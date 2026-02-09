# Firestore rules vs 141k denies (analysis)

## What caused the 141k denies

- **Old pattern:** Many read rules used `isBarberOrSuperadmin()` (or similar), which does `get(/databases/.../users/$(request.auth.uid))` on **every** read.
- **Dependency:** That creates a dependency on the **user document**: the read is only allowed after a successful `get(users/uid)`.
- **Login/logout:** During sign-in or sign-out, auth state and the user doc can be inconsistent:
  - New user: `users/{uid}` may not exist yet (created on first write or by a Cloud Function).
  - Transition: Many widgets refetch (brand, locations, barbers, services, availability, rewards, user profile). If every one of those reads required a role check → every one did a `get(users/uid)`. If that get failed or the doc was missing → **PERMISSION_DENIED**.
- **Volume (single user):** Even with one developer using the app, 141k denies in one day means **141k read requests** hit the rules. That can come from:
  - **Streams (snapshots):** Each listener re-evaluates rules when data or auth changes. If you have streams on brands, locations, barbers, services, user doc, appointments, etc., then every auth blip (login, logout, token refresh) or doc update can trigger many re-reads, each evaluated with a `get(users/uid)`.
  - **Rebuilds / refetches:** Hot reload, navigation, or state changes that refetch the same data repeatedly.
  - **Auth churn:** Switching accounts or repeated sign-in/sign-out during testing; each transition can trigger a wave of reads that all depend on the user doc.

So the problem was: **public and own-data reads were gated on a user-document get(), and a single user can still generate a huge number of read evaluations (streams + auth transitions + refetches), each one doing that get() and failing when the doc was missing or inconsistent.**

---

## Do the current rules fix it?

**Yes.** The current rules are designed so that **no high-volume read path depends on `get(users/uid)`.**

### Read paths and `get()` usage

| Collection / path | Who reads | Rule condition | Uses `get()`? |
|-------------------|-----------|-----------------|---------------|
| **brands** | All authenticated | `request.auth != null` | No |
| **locations** | All authenticated | `request.auth != null` | No |
| **barbers** | All authenticated | `request.auth != null` | No |
| **services** | All authenticated | `request.auth != null` | No |
| **availability** | All authenticated | `request.auth != null` | No |
| **rewards** | All authenticated | `request.auth != null` | No |
| **users/{userId}** | Own profile / role | `request.auth.uid == userId` | No |
| **appointments** (own) | Customer | `resource.data.user_id == request.auth.uid` | No (short-circuit) |
| **appointments** (barber list) | Barber | `isBarberOrSuperadmin() && resource.data.barber_id == userBarberId()` | Yes (1 per query, cached) |
| **user_booking_locks/{userId}** | Own lock | `request.auth.uid == userId` | No |
| **reward_redemptions** (own) | Customer | `resource.data.user_id == request.auth.uid` | No |

So:

- **Public data** (brands, locations, barbers, services, availability, rewards): allowed as soon as `request.auth != null`. No user-doc lookup → no dependency storm during login.
- **Own data** (own user doc, own appointments, own lock, own redemptions): allowed by **uid / user_id match only**. No role check, no `get()`.
- **Barber-only reads** (upcoming appointments for barber): use `get(users/uid)` only on that path; Firestore caches that get per request, so it’s one read per query, not per document. This does not affect normal customer flows or public data.

### Short-circuit on appointments

For `appointments` the rule is:

```text
resource.data.user_id == request.auth.uid
|| isSuperadmin()
|| (isBarberOrSuperadmin() && resource.data.barber_id == userBarberId())
```

For **customers** reading their own appointments, the first condition is true, so the rest is not evaluated and **no `get()` runs**. So customer appointment reads do not contribute to the old “every read does a get()” problem.

---

## Conclusion

- **141k denies:** Were caused by reads (especially public and own-data) depending on a successful `get(users/uid)` during login/logout.
- **Current rules:** Remove that dependency for all high-volume reads (public + own user + own appointments + own locks + own redemptions). Only barber/superadmin appointment reads and all **writes** that check role still use `get(users/uid)`.
- **Expected effect:** Public and customer read traffic should no longer hit “waiting for user document” and should stop generating the previous deny spike. So **yes, the current rules are in line with fixing the 141k denies in one dev day**, assuming the main cause was the dependency on user-doc validation for those reads.

### After deploy (single-user / dev)

- Even as the only user, you can generate many read operations (streams, refetches, login/logout). The new rules stop those reads from depending on `get(users/uid)`, so they should no longer deny during auth transitions.
- Watch Firestore “Denied” (and optionally “Reads”) in the Firebase console; you should see a sharp drop in denies and no spike during login/logout.
