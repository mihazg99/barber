/**
 * Barber App – Marketing Automation Cloud Functions (Firebase v2)
 * - onBookingComplete: Updates user metrics when appointment is completed
 * - dailyReminders: Sends FCM push notifications to users due for a visit
 * - appointmentReminderScanner: Sends 2-hour-before reminders for upcoming appointments
 *
 * Production considerations:
 * - Idempotent: onBookingComplete tracks last_processed_appointment_id to avoid double-counting
 * - No unnecessary reads: uses default average_visit_interval when not set
 * - Chunked: dailyReminders batches FCM (500) and Firestore writes (500)
 * - Timezone: dailyReminders uses Europe/Zagreb for "today"
 */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { formatInTimeZone, fromZonedTime } = require("date-fns-tz");

// Initialize Firebase Admin once (no args = default project)
admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const FIRESTORE_BATCH_LIMIT = 500;
const FCM_SEND_EACH_LIMIT = 500;
const DAILY_REMINDERS_QUERY_LIMIT = 2000;
const APPOINTMENT_REMINDER_QUERY_LIMIT = 500;
const TIMEZONE = "Europe/Zagreb";

// ---------------------------------------------------------------------------
// User document fields (marketing tracking)
// ---------------------------------------------------------------------------
// last_booking_date (Timestamp)
// next_visit_due (Timestamp)
// average_visit_interval (int, default: 30)
// lifetime_value (number, default: 0)
// reminded_this_cycle (boolean, default: false)
// preferred_barber_id (String)
// last_processed_appointment_id (String) – idempotency guard
// fcm_token (String) – used for push notifications

/**
 * Firestore trigger: when an appointment document is updated.
 * - status → 'completed': updates user metrics and aggregates daily_stats / monthly_stats.
 * - status → 'no_show': increments no_shows in daily_stats.
 * Idempotent via last_processed_appointment_id (completed) and no_show_counted (no_show).
 */
exports.onBookingComplete = onDocumentUpdated(
  {
    document: "appointments/{appointmentId}",
    region: "europe-west1",
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

    // --- Handle 'completed' ---
    if (statusAfter === "completed") {
      if (!userId) {
        logger.warn("onBookingComplete: appointment missing user_id", { appointmentId });
        return;
      }

      const userRef = db.collection("users").doc(userId);
      const userSnap = await userRef.get();
      const userData = userSnap?.data() ?? {};

      if (userData.last_processed_appointment_id === appointmentId) {
        logger.info("onBookingComplete: already processed", { appointmentId, userId });
        return;
      }

      const prevLifetime = typeof userData.lifetime_value === "number" ? userData.lifetime_value : 0;
      const isNewCustomer = prevLifetime === 0;

      const avgInterval =
        typeof userData.average_visit_interval === "number"
          ? userData.average_visit_interval
          : 30;

      const now = new Date();
      const nextVisitDue = new Date(now);
      nextVisitDue.setDate(nextVisitDue.getDate() + avgInterval);

      const batch = db.batch();

      batch.set(
        userRef,
        {
          lifetime_value: FieldValue.increment(totalPrice),
          last_booking_date: FieldValue.serverTimestamp(),
          next_visit_due: nextVisitDue,
          reminded_this_cycle: false,
          preferred_barber_id: barberId ?? "",
          last_processed_appointment_id: appointmentId,
        },
        { merge: true },
      );

      if (locationId) {
        const locationRef = db.collection("locations").doc(locationId);
        const dailyRef = locationRef.collection("daily_stats").doc(dateKey);
        const monthlyRef = locationRef.collection("monthly_stats").doc(monthKey);

        const dailyUpdate = {
          total_revenue: FieldValue.increment(totalPrice),
          appointments_count: FieldValue.increment(1),
          ...(isNewCustomer ? { new_customers: FieldValue.increment(1) } : {}),
        };
        for (const sid of serviceIds) {
          dailyUpdate[`service_breakdown.${sid}`] = FieldValue.increment(1);
        }
        batch.set(dailyRef, dailyUpdate, { merge: true });

        const monthlyUpdate = {
          total_revenue: FieldValue.increment(totalPrice),
          ...(barberId ? { [`barber_appointments.${barberId}`]: FieldValue.increment(1) } : {}),
        };
        batch.set(monthlyRef, monthlyUpdate, { merge: true });
      }

      await batch.commit();
      logger.info("onBookingComplete: updated user and stats", {
        userId,
        appointmentId,
        locationId,
        totalPrice,
        isNewCustomer,
      });
      return;
    }

    // --- Handle 'no_show' ---
    if (statusAfter === "no_show") {
      if (after?.no_show_counted === true) {
        logger.info("onBookingComplete: no_show already counted", { appointmentId });
        return;
      }

      if (!locationId) {
        logger.warn("onBookingComplete: no_show missing location_id", { appointmentId });
        return;
      }

      const locationRef = db.collection("locations").doc(locationId);
      const dailyRef = locationRef.collection("daily_stats").doc(dateKey);
      const appointmentRef = db.collection("appointments").doc(appointmentId);

      const batch = db.batch();
      batch.set(
        dailyRef,
        { no_shows: FieldValue.increment(1) },
        { merge: true },
      );
      batch.update(appointmentRef, { no_show_counted: true });

      await batch.commit();
      logger.info("onBookingComplete: recorded no_show", { appointmentId, locationId });
    }
  },
);

/**
 * Scheduled function: runs daily at 10:00 AM Europe/Zagreb.
 * Queries users where next_visit_due <= today (Zagreb) AND reminded_this_cycle == false,
 * sends FCM push notifications (chunked 500), then sets reminded_this_cycle = true (chunked 500).
 */
exports.dailyReminders = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: TIMEZONE,
    region: "europe-west1",
  },
  async () => {
    const nowUtc = new Date();
    const todayStr = formatInTimeZone(nowUtc, TIMEZONE, "yyyy-MM-dd");
    const endOfTodayZagreb = fromZonedTime(`${todayStr}T23:59:59.999`, TIMEZONE);

    const usersSnap = await db
      .collection("users")
      .where("next_visit_due", "<=", endOfTodayZagreb)
      .where("reminded_this_cycle", "==", false)
      .limit(DAILY_REMINDERS_QUERY_LIMIT)
      .get();

    const preferredStaffIds = [...new Set(
      usersSnap.docs
        .map((d) => d.data().preferred_barber_id)
        .filter((id) => id && typeof id === "string")
    )];

    const staffSnaps = preferredStaffIds.length > 0
      ? await Promise.all(preferredStaffIds.map((id) => db.collection("barbers").doc(id).get()))
      : [];
    const staffNames = Object.fromEntries(
      preferredStaffIds.map((id, i) => [id, staffSnaps[i]?.data()?.name || id])
    );

    const messages = [];
    const userIdsToUpdate = [];

    for (const doc of usersSnap.docs) {
      const data = doc.data();
      const fcmToken = data.fcm_token || data.fcmToken;
      const fullName = data.full_name || "";
      const preferredStaffId = data.preferred_barber_id || "";

      if (!fcmToken || typeof fcmToken !== "string") {
        logger.warn("dailyReminders: user has no fcm_token", { userId: doc.id });
        continue;
      }

      const staffName = preferredStaffId ? (staffNames[preferredStaffId] || preferredStaffId) : "";
      const title = fullName
        ? `${fullName}, nedostaješ nam!`
        : "Nedostaješ nam!";
      const body = staffName
        ? `${staffName} te čeka i veseli se tvom povratku. Rezerviraj termin – brzo i jednostavno!`
        : "Čekamo te i veselimo se tvom povratku. Rezerviraj termin – brzo i jednostavno!";

      messages.push({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          type: "visit_reminder",
          user_id: doc.id,
          preferred_barber_id: String(preferredStaffId),
        },
      });
      userIdsToUpdate.push(doc.id);
    }

    if (messages.length === 0) {
      logger.info("dailyReminders: no users to notify");
      return;
    }

    if (usersSnap.docs.length >= DAILY_REMINDERS_QUERY_LIMIT) {
      logger.warn("dailyReminders: hit query limit, consider pagination for larger scale", {
        limit: DAILY_REMINDERS_QUERY_LIMIT,
      });
    }

    // Send FCM in chunks of 500
    const messaging = admin.messaging();
    let totalSuccess = 0;
    let totalFailure = 0;

    for (let i = 0; i < messages.length; i += FCM_SEND_EACH_LIMIT) {
      const chunk = messages.slice(i, i + FCM_SEND_EACH_LIMIT);
      const results = await messaging.sendEach(chunk);
      totalSuccess += results.successCount;
      totalFailure += results.failureCount;

      if (results.failureCount > 0) {
        const failedTokens = [];
        results.responses.forEach((resp, j) => {
          if (!resp.success) {
            const idx = i + j;
            failedTokens.push({
              userId: userIdsToUpdate[idx],
              error: resp.error?.message,
            });
          }
        });
        logger.warn("dailyReminders: some sends failed", { failedTokens });
      }
    }

    logger.info("dailyReminders: sent notifications", {
      total: messages.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
    });

    // Update reminded_this_cycle in Firestore batches of 500
    for (let i = 0; i < userIdsToUpdate.length; i += FIRESTORE_BATCH_LIMIT) {
      const chunk = userIdsToUpdate.slice(i, i + FIRESTORE_BATCH_LIMIT);
      const batch = db.batch();
      for (const userId of chunk) {
        batch.update(db.collection("users").doc(userId), {
          reminded_this_cycle: true,
        });
      }
      await batch.commit();
    }

    logger.info("dailyReminders: updated reminded_this_cycle for", userIdsToUpdate.length, "users");
  }
);

/**
 * Scheduled function: runs every 30 minutes.
 * Finds appointments starting in 2–2.5 hours, sends FCM reminders, sets reminder_sent.
 */
exports.appointmentReminderScanner = onSchedule(
  {
    schedule: "*/30 * * * *",
    region: "europe-west1",
  },
  async () => {
    const now = new Date();
    const windowStart = new Date(now.getTime() + 120 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + 150 * 60 * 1000);

    const appointmentsSnap = await db
      .collection("appointments")
      .where("status", "==", "scheduled")
      .where("start_time", ">=", windowStart)
      .where("start_time", "<", windowEnd)
      .limit(APPOINTMENT_REMINDER_QUERY_LIMIT)
      .get();

    const toRemind = [];
    for (const doc of appointmentsSnap.docs) {
      const data = doc.data();
      if (data.reminder_sent === true) continue;
      toRemind.push({ id: doc.id, data });
    }

    if (toRemind.length === 0) {
      logger.info("appointmentReminderScanner: no appointments to remind");
      return;
    }

    const userIds = [...new Set(toRemind.map((a) => a.data.user_id))];
    const locationIds = [...new Set(toRemind.map((a) => a.data.location_id))];
    const barberIds = [...new Set(toRemind.map((a) => a.data.barber_id))];

    const [userSnaps, locationSnaps, barberSnaps] = await Promise.all([
      Promise.all(userIds.map((id) => db.collection("users").doc(id).get())),
      Promise.all(locationIds.map((id) => db.collection("locations").doc(id).get())),
      Promise.all(barberIds.map((id) => db.collection("barbers").doc(id).get())),
    ]);

    const users = Object.fromEntries(userIds.map((id, i) => [id, userSnaps[i].data()]));
    const locations = Object.fromEntries(
      locationIds.map((id, i) => [id, locationSnaps[i].data()?.name ?? "lokacija"])
    );
    const barbers = Object.fromEntries(
      barberIds.map((id, i) => [id, barberSnaps[i].data()?.name ?? ""])
    );

    const messages = [];
    const appointmentIdsToUpdate = [];

    for (const { id, data } of toRemind) {
      const userData = users[data.user_id] ?? {};
      const fcmToken = userData.fcm_token || userData.fcmToken;

      if (!fcmToken || typeof fcmToken !== "string") {
        logger.warn("appointmentReminderScanner: user has no fcm_token", {
          appointmentId: id,
          userId: data.user_id,
        });
        continue;
      }

      const venueName = locations[data.location_id] ?? "lokacija";
      const staffName = barbers[data.barber_id] ?? "";
      const startTs = data.start_time?.toDate?.() ?? new Date();
      const timeStr = formatInTimeZone(startTs, TIMEZONE, "HH:mm");

      const title = "Vidimo se za 2 sata!";
      const staffPart = staffName ? ` s ${staffName}` : "";
      const body = `Tvoj termin u ${venueName}${staffPart} kreće u ${timeStr}.`;

      messages.push({
        token: fcmToken,
        notification: { title, body },
        data: {
          type: "appointment_reminder",
          appointment_id: id,
          user_id: data.user_id,
        },
      });
      appointmentIdsToUpdate.push(id);
    }

    if (messages.length === 0) {
      logger.info("appointmentReminderScanner: no valid fcm tokens");
      return;
    }

    const messaging = admin.messaging();
    let totalSuccess = 0;
    let totalFailure = 0;

    for (let i = 0; i < messages.length; i += FCM_SEND_EACH_LIMIT) {
      const chunk = messages.slice(i, i + FCM_SEND_EACH_LIMIT);
      const results = await messaging.sendEach(chunk);
      totalSuccess += results.successCount;
      totalFailure += results.failureCount;

      if (results.failureCount > 0) {
        const failed = results.responses
          .map((r, j) => (r.success ? null : { appointmentId: appointmentIdsToUpdate[i + j], error: r.error?.message }))
          .filter(Boolean);
        logger.warn("appointmentReminderScanner: some sends failed", { failed });
      }
    }

    logger.info("appointmentReminderScanner: sent reminders", {
      total: messages.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
    });

    await Promise.all(
      appointmentIdsToUpdate.map((aptId) =>
        db.collection("appointments").doc(aptId).update({ reminder_sent: true })
      )
    );

    logger.info("appointmentReminderScanner: updated reminder_sent for", appointmentIdsToUpdate.length, "appointments");
  }
);
