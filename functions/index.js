/**
 * Barber App – Marketing Automation Cloud Functions (Firebase v2)
 * Multi-brand: user metrics and reminders are per-brand (users/{uid}/user_brands/{brandId}).
 *
 * - onBookingComplete / onAppointmentCreated: Per-brand stats + enqueue 2h reminder task
 * - dailyReminders: Enqueues batch tasks; dailyReminderBatchTask processes in batches of 500
 * - appointmentReminderTask: Sends single 2h-before reminder (invoked by Cloud Task)
 *
 * Whitelabel: Notification copy uses provider_label and business_label from brands/{brandId}
 * (defaults: "Professional", "Salon"). Set these fields per brand for localised copy.
 *
 * Token cleanup: On FCM invalid/not-registered errors, the token is removed from users/{uid}
 * so we do not keep sending and paying for failed deliveries.
 *
 * Production: Transactional; queue-on-booking (no polling); fan-out for daily reminders.
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const admin = require("firebase-admin");
const { getFunctions } = require("firebase-admin/functions");
const { logger } = require("firebase-functions");
const { formatInTimeZone, fromZonedTime } = require("date-fns-tz");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const REGION = "europe-west1";
const TIMEZONE = "Europe/Zagreb";

const FIRESTORE_BATCH_LIMIT = 500;
const FCM_SEND_EACH_LIMIT = 500;
const DAILY_REMINDER_BATCH_SIZE = 500;
const REMINDER_HOURS_BEFORE_APPOINTMENT = 2;
/** Only send reminder if we're within this window before start (avoids stale task after reschedule). */
const REMINDER_WINDOW_MIN_MINUTES = 90;
const REMINDER_WINDOW_MAX_MINUTES = 150;
const COLLECTION_APPOINTMENTS = "appointments";
const COLLECTION_USERS = "users";
const COLLECTION_USER_BRANDS = "user_brands";
const COLLECTION_BARBERS = "barbers";
const COLLECTION_LOCATIONS = "locations";
const COLLECTION_DAILY_STATS = "daily_stats";
const COLLECTION_MONTHLY_STATS = "monthly_stats";
const COLLECTION_BRANDS = "brands";

/** Default labels when brand has none set (e.g. Professional / Salon for Croatian whitelabel). */
const DEFAULT_PROVIDER_LABEL = "Professional";
const DEFAULT_BUSINESS_LABEL = "Salon";

/** FCM error codes that mean the token is invalid and should be removed from Firestore. */
const FCM_INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
  "invalid-registration-token",
  "registration-token-not-registered",
]);

/**
 * Fetches providerLabel and businessLabel from brands/{brandId}. Used for whitelabel notification copy.
 * @returns {{ providerLabel: string, businessLabel: string }}
 */
async function getBrandTerminology(brandId) {
  if (!brandId) {
    return { providerLabel: DEFAULT_PROVIDER_LABEL, businessLabel: DEFAULT_BUSINESS_LABEL };
  }
  try {
    const brandSnap = await db.collection(COLLECTION_BRANDS).doc(brandId).get();
    const data = brandSnap?.data() ?? {};
    return {
      providerLabel: (data.provider_label && String(data.provider_label).trim()) || DEFAULT_PROVIDER_LABEL,
      businessLabel: (data.business_label && String(data.business_label).trim()) || DEFAULT_BUSINESS_LABEL,
    };
  } catch (err) {
    logger.warn("getBrandTerminology: read failed", { brandId, error: err?.message });
    return { providerLabel: DEFAULT_PROVIDER_LABEL, businessLabel: DEFAULT_BUSINESS_LABEL };
  }
}

/**
 * Removes FCM token from users/{userId} when token is invalid/not-registered to avoid repeated failed sends.
 */
async function removeInvalidFcmToken(userId) {
  if (!userId) return;
  try {
    const userRef = db.collection(COLLECTION_USERS).doc(userId);
    await userRef.update({
      fcm_token: FieldValue.delete(),
      fcmToken: FieldValue.delete(),
    });
    logger.info("removeInvalidFcmToken: cleared token", { userId });
  } catch (err) {
    logger.warn("removeInvalidFcmToken: update failed", { userId, error: err?.message });
  }
}

/**
 * Returns true if the FCM error indicates an invalid/not-registered token that should be removed.
 */
function isInvalidTokenError(error) {
  const code = String(error?.code ?? error?.message ?? "").trim();
  if (FCM_INVALID_TOKEN_CODES.has(code)) return true;
  const msg = String(error?.message ?? "").toLowerCase();
  return msg.includes("not-registered") || msg.includes("invalid-registration") || msg.includes("invalid registration");
}

/**
 * Helper: Find Brand Owner(s) – Users with role 'superadmin' and matching brand_id.
 * Returns array of { uid, fcmToken, fullName }
 */
async function getBrandOwners(brandId) {
  if (!brandId) return [];
  try {
    const snap = await db.collection(COLLECTION_USERS)
      .where("brand_id", "==", brandId)
      .where("role", "==", "superadmin")
      .get();
    return snap.docs
      .map(d => ({ uid: d.id, data: d.data() }))
      .filter(u => u.data.fcm_token || u.data.fcmToken)
      .map(u => ({
        uid: u.uid,
        fcmToken: u.data.fcm_token || u.data.fcmToken,
        fullName: u.data.full_name || "Owner"
      }));
  } catch (err) {
    logger.warn("getBrandOwners: failed", { brandId, error: err?.message });
    return [];
  }
}

/**
 * Helper: Find Barber User – User with matching barber_id (linked to Barbers collection).
 * Returns { uid, fcmToken, fullName } or null.
 */
async function getBarberUser(barberId) {
  if (!barberId) return null;
  try {
    // Assuming 1:1 mapping standard: User.barber_id points to Barber doc ID.
    const snap = await db.collection(COLLECTION_USERS)
      .where("barber_id", "==", barberId)
      .limit(1)
      .get();
    if (snap.empty) return null;
    const doc = snap.docs[0];
    const data = doc.data();
    const token = data.fcm_token || data.fcmToken;
    if (!token) return null;
    return { uid: doc.id, fcmToken: token, fullName: data.full_name || "Barber" };
  } catch (err) {
    logger.warn("getBarberUser: failed", { barberId, error: err?.message });
    return null;
  }
}

/**
 * Sends a basic notification to a list of recipients.
 * @param {Array<{uid, fcmToken}>} recipients
 * @param {string} title
 * @param {string} body
 * @param {object} dataPayload
 */
async function sendNotifications(recipients, title, body, dataPayload) {
  if (!recipients || recipients.length === 0) return;
  const messaging = admin.messaging();
  const messages = recipients.map(r => ({
    token: r.fcmToken,
    notification: { title, body },
    data: dataPayload,
    android: { priority: "high" },
    apns: { payload: { aps: { "content-available": 1 } } },
  }));

  const results = await messaging.sendEach(messages);
  results.responses.forEach(async (resp, idx) => {
    if (!resp.success && isInvalidTokenError(resp.error)) {
      await removeInvalidFcmToken(recipients[idx].uid);
    }
  });
}

// ---------------------------------------------------------------------------
// Per-brand user metrics: users/{userId}/user_brands/{brandId}
// ---------------------------------------------------------------------------
// last_processed_appointment_id (String) – idempotency guard for completed
// (fcm_token, full_name on parent users/{userId})

/**
 * Schedules a Cloud Task to send the 2h-before appointment reminder.
 * Call when appointment is created or updated with status 'scheduled'.
 */
async function scheduleAppointmentReminderTask(appointmentId, startTime) {
  try {
    const scheduleTime = new Date(startTime.getTime() - REMINDER_HOURS_BEFORE_APPOINTMENT * 60 * 60 * 1000);
    const now = new Date();

    if (scheduleTime <= now) {
      logger.warn("scheduleAppointmentReminderTask: start_time within 2h (or past), skipping", { appointmentId, scheduleTime: scheduleTime.toISOString() });
      return;
    }

    // Use function resource name compatible with firebase-admin
    const queuePath = `locations/${REGION}/functions/appointmentReminderTask`;
    const queue = getFunctions().taskQueue(queuePath);

    try {
      await queue.delete(appointmentId);
    } catch {
      // Ignore if task doesn't exist
    }

    await queue.enqueue(
      { appointmentId },
      {
        scheduleTime,
        dispatchDeadlineSeconds: 60,
        id: appointmentId,
      },
    );
    logger.info("scheduleAppointmentReminderTask: enqueued", { appointmentId, scheduleTime: scheduleTime.toISOString() });
  } catch (err) {
    logger.error("scheduleAppointmentReminderTask: failed", { appointmentId, error: err?.message });
    throw err;
  }
}

/**
 * Firestore trigger: appointment created. If status is 'scheduled', enqueue 2h-before reminder task.
 */
exports.onAppointmentCreated = onDocumentCreated(
  {
    document: `${COLLECTION_APPOINTMENTS}/{appointmentId}`,
    region: REGION,
  },
  async (event) => {
    const appointmentId = event.params.appointmentId;
    logger.info("onAppointmentCreated: triggered", { appointmentId });
    try {
      const snap = event.data;
      if (!snap || !snap.exists) {
        // Warning if triggered but doc gone (e.g. immediate delete)
        return;
      }
      const data = snap.data();
      const status = data?.status ?? "";
      const startTimeVal = data?.start_time;
      const startTime = startTimeVal?.toDate?.();

      if (status !== "scheduled") {
        return;
      }

      if (!startTime) {
        logger.warn("onAppointmentCreated: missing start_time or invalid format", { appointmentId });
        return;
      }

      // 1. Notify Owner (Always)
      // 2. Notify Barber (If start_time < 48 hours from now)

      const brandId = data.brand_id;
      const barberId = data.barber_id;
      const serviceNames = data.service_name || "New Booking";
      const customerName = data.customer_name || "Client"; // Appointment usually has client_name snapshot

      const now = new Date();
      const hoursUntilStart = (startTime.getTime() - now.getTime()) / (1000 * 60 * 60);
      const isUrgent = hoursUntilStart < 48;

      const [owners, barberUser] = await Promise.all([
        getBrandOwners(brandId),
        getBarberUser(barberId)
      ]);

      const timeStr = formatInTimeZone(startTime, TIMEZONE, "HH:mm dd.MM.");
      const notifTitle = "Nova rezervacija! 📅";
      const notifBody = `${customerName} - ${serviceNames} u ${timeStr}`;

      // Payload for navigation (open booking details)
      const dataPayload = {
        type: "new_booking",
        appointment_id: appointmentId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      };

      // Send to Owners
      if (owners.length > 0) {
        await sendNotifications(owners, notifTitle, notifBody, dataPayload);
        logger.info("onAppointmentCreated: notified owners", { count: owners.length });
      }

      // Send to Barber if urgent
      if (barberUser && isUrgent) {
        await sendNotifications([barberUser], notifTitle, notifBody, dataPayload);
        logger.info("onAppointmentCreated: notified barber", { uid: barberUser.uid });
      }

      await scheduleAppointmentReminderTask(appointmentId, startTime);
    } catch (err) {
      logger.error("onAppointmentCreated: failed", { appointmentId, error: err?.message });
      throw err;
    }
  },
);

/**
 * Firestore trigger: appointment updated.
 * - status → 'scheduled': enqueue 2h-before reminder task (e.g. rescheduled).
 * - status → 'completed': transactional update of user_brands + daily/monthly_stats; idempotent.
 * - status → 'no_show': increment no_shows; idempotent via no_show_counted.
 */
exports.onBookingComplete = onDocumentUpdated(
  {
    document: `${COLLECTION_APPOINTMENTS}/{appointmentId}`,
    region: REGION,
  },
  async (event) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    const statusBefore = before?.status ?? "";
    const statusAfter = after?.status ?? "";
    if (statusBefore === statusAfter) return;

    const appointmentId = event.params.appointmentId;
    const brandId = after?.brand_id ?? "";
    const locationId = after?.location_id;
    const userId = after?.user_id;
    const barberId = after?.barber_id;
    const totalPrice = typeof after?.total_price === "number" ? after.total_price : 0;
    const serviceIds = Array.isArray(after?.service_ids)
      ? after.service_ids.filter((id) => id && typeof id === "string")
      : [];
    const startTs = after?.start_time?.toDate?.() ?? new Date();
    const dateKey = formatInTimeZone(startTs, TIMEZONE, "yyyy-MM-dd");
    const monthKey = formatInTimeZone(startTs, TIMEZONE, "yyyy-MM");

    // --- status → 'scheduled': enqueue reminder task (e.g. reschedule) ---
    if (statusAfter === "scheduled") {
      try {
        await scheduleAppointmentReminderTask(appointmentId, startTs);
      } catch (err) {
        logger.error("onBookingComplete: schedule reminder failed", { appointmentId, error: err?.message });
      }
      return;
    }

    // --- status → 'cancelled': notify Barber ---
    // Note: status might be 'cancelled_by_client' or just 'cancelled'. Checking inclusion.
    if (statusAfter.includes("cancelled")) {
      const barberUser = await getBarberUser(barberId);
      if (barberUser) {
        const timeStr = formatInTimeZone(startTs, TIMEZONE, "HH:mm dd.MM.");
        const notifTitle = "Otkazana rezervacija ❌";
        const notifBody = `Termin u ${timeStr} je otkazan.`;
        const dataPayload = {
          type: "sub_cancelled", // using generic 'cancelled' type or reuse existing
          appointment_id: appointmentId,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        };
        await sendNotifications([barberUser], notifTitle, notifBody, dataPayload);
        logger.info("onBookingComplete: notified barber of cancellation", { uid: barberUser.uid });
      }
      return;
    }

    // --- status → 'completed': transactional update; idempotent via last_processed_appointment_id ---
    if (statusAfter === "completed") {
      if (!userId || !brandId) {
        logger.warn("onBookingComplete: missing user_id or brand_id", { appointmentId });
        return;
      }
      try {
        const userBrandRef = db.collection(COLLECTION_USERS).doc(userId).collection(COLLECTION_USER_BRANDS).doc(brandId);
        const locationRef = locationId ? db.collection(COLLECTION_LOCATIONS).doc(locationId) : null;
        const dailyRef = locationRef?.collection(COLLECTION_DAILY_STATS).doc(dateKey) ?? null;
        const monthlyRef = locationRef?.collection(COLLECTION_MONTHLY_STATS).doc(monthKey) ?? null;

        const result = await db.runTransaction(async (tx) => {
          const userBrandSnap = await tx.get(userBrandRef);
          const userBrandData = userBrandSnap?.data() ?? {};
          if (userBrandData.last_processed_appointment_id === appointmentId) {
            logger.info("onBookingComplete: already processed (idempotent)", { appointmentId, userId, brandId });
            return { isAlreadyProcessed: true };
          }
          const prevLifetime = typeof userBrandData.lifetime_value === "number" ? userBrandData.lifetime_value : 0;
          const isNewCustomer = prevLifetime === 0;
          const avgInterval =
            typeof userBrandData.average_visit_interval === "number" ? userBrandData.average_visit_interval : 21;
          const now = new Date();
          const nextVisitDue = new Date(now);
          nextVisitDue.setDate(nextVisitDue.getDate() + avgInterval);

          const userBrandUpdate = {
            brand_id: brandId,
            average_visit_interval: avgInterval,
            lifetime_value: FieldValue.increment(totalPrice),
            last_booking_date: FieldValue.serverTimestamp(),
            next_visit_due: nextVisitDue,
            reminded_this_cycle: false,
            preferred_barber_id: barberId ?? "",
            last_processed_appointment_id: appointmentId,
            last_active: FieldValue.serverTimestamp(),
          };
          if (!userBrandSnap?.exists) {
            userBrandUpdate.loyalty_points = 0;
            userBrandUpdate.joined_at = FieldValue.serverTimestamp();
          }
          tx.set(userBrandRef, userBrandUpdate, { merge: true });

          if (dailyRef) {
            const dailyUpdate = {
              total_revenue: FieldValue.increment(totalPrice),
              appointments_count: FieldValue.increment(1),
              ...(isNewCustomer ? { new_customers: FieldValue.increment(1) } : {}),
            };
            for (const sid of serviceIds) {
              dailyUpdate[`service_breakdown.${sid}`] = FieldValue.increment(1);
            }
            tx.set(dailyRef, dailyUpdate, { merge: true });
          }
          if (monthlyRef) {
            const monthlyUpdate = {
              total_revenue: FieldValue.increment(totalPrice),
              ...(barberId ? { [`barber_appointments.${barberId}`]: FieldValue.increment(1) } : {}),
            };
            tx.set(monthlyRef, monthlyUpdate, { merge: true });
          }
          return { isNewCustomer };
        });

        if (result?.isAlreadyProcessed) return;

        const { isNewCustomer } = result;

        logger.info("onBookingComplete: updated user_brands and stats", {
          userId,
          brandId,
          appointmentId,
          locationId,
          totalPrice,
          isNewCustomer,
        });
      } catch (err) {
        logger.error("onBookingComplete: transaction failed", { appointmentId, error: err?.message });
        throw err;
      }
      return;
    }

    // --- status → 'no_show' ---
    if (statusAfter === "no_show") {
      if (after?.no_show_counted === true) {
        logger.info("onBookingComplete: no_show already counted", { appointmentId });
        return;
      }
      if (!locationId) {
        logger.warn("onBookingComplete: no_show missing location_id", { appointmentId });
        return;
      }
      try {
        const locationRef = db.collection(COLLECTION_LOCATIONS).doc(locationId);
        const dailyRef = locationRef.collection(COLLECTION_DAILY_STATS).doc(dateKey);
        const appointmentRef = db.collection(COLLECTION_APPOINTMENTS).doc(appointmentId);
        const batch = db.batch();
        batch.set(dailyRef, { no_shows: FieldValue.increment(1) }, { merge: true });
        batch.update(appointmentRef, { no_show_counted: true });
        await batch.commit();
        logger.info("onBookingComplete: recorded no_show", { appointmentId, locationId });
      } catch (err) {
        logger.error("onBookingComplete: no_show failed", { appointmentId, error: err?.message });
        throw err;
      }
    }
  },
);

/**
 * Cloud Task: send one appointment reminder. Checks status before sending (handles stale/cancelled).
 */
exports.appointmentReminderTask = onTaskDispatched(
  {
    region: REGION,
    retryConfig: { maxAttempts: 3, minBackoffSeconds: 60 },
  },
  async (req) => {
    const { appointmentId } = req.data ?? {};
    if (!appointmentId || typeof appointmentId !== "string") {
      logger.warn("appointmentReminderTask: missing appointmentId");
      return;
    }
    try {
      const aptRef = db.collection(COLLECTION_APPOINTMENTS).doc(appointmentId);
      const aptSnap = await aptRef.get();
      const data = aptSnap?.data();
      if (!data) {
        logger.warn("appointmentReminderTask: appointment not found", { appointmentId });
        return;
      }
      if ((data.status ?? "") !== "scheduled") {
        logger.info("appointmentReminderTask: skipped (stale/cancelled)", { appointmentId, status: data.status });
        return;
      }
      if (data.reminder_sent === true) {
        logger.info("appointmentReminderTask: already sent", { appointmentId });
        return;
      }
      const startTs = data.start_time?.toDate?.() ?? new Date();
      const now = new Date();
      const minutesUntilStart = (startTs.getTime() - now.getTime()) / (60 * 1000);
      if (minutesUntilStart < REMINDER_WINDOW_MIN_MINUTES || minutesUntilStart > REMINDER_WINDOW_MAX_MINUTES) {
        logger.info("appointmentReminderTask: skipped (not in 2h window, likely rescheduled)", {
          appointmentId,
          minutesUntilStart: Math.round(minutesUntilStart),
        });
        return;
      }
      const userId = data.user_id;
      const locationId = data.location_id;
      const barberId = data.barber_id;
      const brandId = data.brand_id ?? "";
      const [userSnap, locationSnap, barberSnap, terminology] = await Promise.all([
        db.collection(COLLECTION_USERS).doc(userId).get(),
        locationId ? db.collection(COLLECTION_LOCATIONS).doc(locationId).get() : Promise.resolve(null),
        barberId ? db.collection(COLLECTION_BARBERS).doc(barberId).get() : Promise.resolve(null),
        getBrandTerminology(brandId),
      ]);
      const userData = userSnap?.data() ?? {};
      const fcmToken = userData.fcm_token || userData.fcmToken;
      if (!fcmToken || typeof fcmToken !== "string") {
        logger.warn("appointmentReminderTask: no fcm_token", { appointmentId, userId });
        return;
      }
      const { businessLabel } = terminology;
      const venueName = locationSnap?.data()?.name ?? businessLabel;
      const staffName = barberSnap?.data()?.name ?? "";
      const timeStr = formatInTimeZone(startTs, TIMEZONE, "HH:mm");
      const title = "Vidimo se za 2 sata!";
      const staffPart = staffName ? ` s ${staffName}` : "";
      const body = `Tvoj termin u ${venueName}${staffPart} kreće u ${timeStr}.`;

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          android: {
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                "content-available": 1,
              },
            },
          },
          data: {
            type: "appointment_reminder",
            appointment_id: appointmentId,
            user_id: String(userId),
            brand_id: String(brandId),
          },
        });
      } catch (sendErr) {
        if (isInvalidTokenError(sendErr)) {
          await removeInvalidFcmToken(userId);
        }
        throw sendErr;
      }
      await aptRef.update({ reminder_sent: true });
      logger.info("appointmentReminderTask: sent", { appointmentId });
    } catch (err) {
      logger.error("appointmentReminderTask: failed", { appointmentId, error: err?.message });
      throw err;
    }
  },
);

/**
 * Scheduled: daily at 10:00 Europe/Zagreb. Enqueues one batch task; fan-out is inside dailyReminderBatchTask.
 */
exports.dailyReminders = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: TIMEZONE,
    region: REGION,
  },
  async () => {
    try {
      const nowUtc = new Date();
      const todayStr = formatInTimeZone(nowUtc, TIMEZONE, "yyyy-MM-dd");
      const endOfTodayZagreb = fromZonedTime(`${todayStr}T23:59:59.999`, TIMEZONE);
      const queue = getFunctions().taskQueue(`locations/${REGION}/functions/dailyReminderBatchTask`);
      await queue.enqueue(
        { dueCutoff: endOfTodayZagreb.toISOString() },
        { dispatchDeadlineSeconds: 540 },
      );
      logger.info("dailyReminders: enqueued batch task", { dueCutoff: endOfTodayZagreb.toISOString() });
    } catch (err) {
      logger.error("dailyReminders: enqueue failed", { error: err?.message });
      throw err;
    }
  },
);

/**
 * Cloud Task: process one batch of daily (visit) reminders. Cursor-based pagination; enqueues next batch if needed.
 * Payload: { dueCutoff: ISO string, lastDocPath?: string }
 */
exports.dailyReminderBatchTask = onTaskDispatched(
  {
    region: REGION,
    retryConfig: { maxAttempts: 3, minBackoffSeconds: 120 },
    rateLimits: { maxConcurrentDispatches: 10 },
  },
  async (req) => {
    const { dueCutoff: dueCutoffIso, lastDocPath } = req.data ?? {};
    if (!dueCutoffIso) {
      logger.warn("dailyReminderBatchTask: missing dueCutoff");
      return;
    }
    const dueCutoff = new Date(dueCutoffIso);
    try {
      let query = db
        .collectionGroup(COLLECTION_USER_BRANDS)
        .where("next_visit_due", "<=", dueCutoff)
        .where("reminded_this_cycle", "==", false)
        .orderBy("next_visit_due")
        .limit(DAILY_REMINDER_BATCH_SIZE);
      if (lastDocPath) {
        const lastSnap = await db.doc(lastDocPath).get();
        if (lastSnap.exists) query = query.startAfter(lastSnap);
      }
      const userBrandsSnap = await query.get();
      const docs = userBrandsSnap.docs;
      if (docs.length === 0) {
        logger.info("dailyReminderBatchTask: no docs in batch");
        return;
      }
      const preferredStaffIds = [...new Set(
        docs.map((d) => d.data().preferred_barber_id).filter((id) => id && typeof id === "string"),
      )];
      const staffSnaps =
        preferredStaffIds.length > 0
          ? await Promise.all(preferredStaffIds.map((id) => db.collection(COLLECTION_BARBERS).doc(id).get()))
          : [];
      const staffNames = Object.fromEntries(
        preferredStaffIds.map((id, i) => [id, staffSnaps[i]?.data()?.name ?? id]),
      );
      const userIds = [...new Set(docs.map((d) => d.reference.parent.parent.id))];
      const brandIds = [...new Set(docs.map((d) => d.id))];
      const [userSnaps, terminologyMap] = await Promise.all([
        Promise.all(userIds.map((id) => db.collection(COLLECTION_USERS).doc(id).get())),
        Promise.all(brandIds.map((id) => getBrandTerminology(id))).then((arr) =>
          Object.fromEntries(brandIds.map((id, idx) => [id, arr[idx]])),
        ),
      ]);
      const users = Object.fromEntries(userIds.map((id, i) => [id, userSnaps[i]?.data() ?? {}]));

      const messages = [];
      const refsToUpdate = [];
      const userIdsForMessages = [];
      for (const doc of docs) {
        const data = doc.data();
        const userId = doc.reference.parent.parent.id;
        const brandId = doc.id;
        const userData = users[userId] ?? {};
        const fcmToken = userData.fcm_token || userData.fcmToken;
        const fullName = userData.full_name || "";
        const preferredStaffId = data.preferred_barber_id || "";
        if (!fcmToken || typeof fcmToken !== "string") {
          logger.warn("dailyReminderBatchTask: no fcm_token", { userId, brandId });
          continue;
        }
        const { providerLabel, businessLabel } = terminologyMap[brandId] ?? { providerLabel: DEFAULT_PROVIDER_LABEL, businessLabel: DEFAULT_BUSINESS_LABEL };
        const staffName = preferredStaffId ? (staffNames[preferredStaffId] ?? preferredStaffId) : "";
        const title = fullName ? `${fullName}, nedostaješ nam!` : "Nedostaješ nam!";
        const body = staffName
          ? `${staffName} te čeka i veseli se tvom povratku. Rezerviraj termin – brzo i jednostavno!`
          : `Tvoj ${businessLabel} te čeka i veseli se tvom povratku. Rezerviraj termin – brzo i jednostavno!`;
        messages.push({
          token: fcmToken,
          notification: { title, body },
          data: {
            type: "visit_reminder",
            user_id: userId,
            brand_id: String(brandId),
            preferred_barber_id: String(preferredStaffId),
          },
        });
        refsToUpdate.push(doc.reference);
        userIdsForMessages.push(userId);
      }
      if (messages.length === 0) {
        logger.info("dailyReminderBatchTask: no valid tokens in batch");
        return;
      }
      const messaging = admin.messaging();
      for (let i = 0; i < messages.length; i += FCM_SEND_EACH_LIMIT) {
        const chunk = messages.slice(i, i + FCM_SEND_EACH_LIMIT);
        const results = await messaging.sendEach(chunk);
        if (results.failureCount > 0) {
          for (let j = 0; j < results.responses.length; j++) {
            const resp = results.responses[j];
            if (!resp.success && resp.error) {
              const msgIdx = i + j;
              logger.warn("dailyReminderBatchTask: send failed", { msgIdx, userId: userIdsForMessages[msgIdx], error: resp.error?.message });
              if (isInvalidTokenError(resp.error)) {
                await removeInvalidFcmToken(userIdsForMessages[msgIdx]);
              }
            }
          }
        }
      }
      for (let i = 0; i < refsToUpdate.length; i += FIRESTORE_BATCH_LIMIT) {
        const batch = db.batch();
        for (let j = i; j < Math.min(i + FIRESTORE_BATCH_LIMIT, refsToUpdate.length); j++) {
          batch.update(refsToUpdate[j], { reminded_this_cycle: true });
        }
        await batch.commit();
      }
      logger.info("dailyReminderBatchTask: processed batch", { count: refsToUpdate.length });
      if (docs.length >= DAILY_REMINDER_BATCH_SIZE) {
        const lastDoc = docs[docs.length - 1];
        const queue = getFunctions().taskQueue(`locations/${REGION}/functions/dailyReminderBatchTask`);
        await queue.enqueue(
          { dueCutoff: dueCutoffIso, lastDocPath: lastDoc.ref.path },
          { dispatchDeadlineSeconds: 540 },
        );
        logger.info("dailyReminderBatchTask: enqueued next batch", { lastDocPath: lastDoc.ref.path });
      }
    } catch (err) {
      logger.error("dailyReminderBatchTask: failed", { dueCutoff: dueCutoffIso, error: err?.message });
      throw err;
    }
  },
);

// ---------------------------------------------------------------------------
// Stripe Integration
// ---------------------------------------------------------------------------
const { createStripeCustomer, createCheckoutSession, handleStripeWebhook } = require("./stripe_integration");
exports.createStripeCustomer = createStripeCustomer;
exports.createCheckoutSession = createCheckoutSession;
exports.handleStripeWebhook = handleStripeWebhook;
