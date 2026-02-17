# Subscription Implementation Guide

This document outlines the architecture and implementation details of the subscription model for the Barber platform. The system uses **Stripe** for payments and **Firebase** (Cloud Functions + Firestore) for subscription management and access control.

## 1. Overview

The goal is to restrict access to the platform for brands that do not have an active subscription or are outside their trial period.

**Key Features:**
*   **Stripe Integration**: Handles secure payments and subscription lifecycle.
*   **Dynamic Free Trial**: Trial duration is configurable via Firestore (`config/subscription`).
*   **Real-time Status**: Subscription status is synced to Firestore via Stripe Webhooks.
*   **App Locking**: The mobile app automatically locks access if the subscription is inactive, with a localized grace period.
*   **Secure**: Subscription data is protected by Firestore Security Rules and can only be modified by the backend.

---

## 2. Architecture

The flow relies on a reactive architecture where the client reacts to state changes in Firestore, which are driven by Stripe webhooks.

1.  **Brand Creation**: A Trigger function (`createStripeCustomer`) creates a Stripe Customer and links it to the `brandId`.
2.  **Checkout**: Client calls `createCheckoutSession` to start a subscription.
3.  **Payment**: User enters details in Stripe Checkout.
4.  **Webhook**: Stripe sends events (`customer.subscription.created`, `invoice.payment_failed`, etc.) to the `handleStripeWebhook` Cloud Function.
5.  **Sync**: The Cloud Function updates the `brands/{brandId}` document in Firestore.
6.  **Client Reacts**: The app listens to the brand document. if `isSubscriptionActive` becomes false, it redirects the user to the `SubscriptionLockedPage`.

---

## 3. Firestore Schema

### Brands Collection (`brands/{brandId}`)

The following read-only fields (from the client's perspective) have been added to the brand document:

| Field | Type | Description |
| :--- | :--- | :--- |
| `subscription_status` | String | Status from Stripe (`active`, `trialing`, `past_due`, `canceled`, `unpaid`, `incomplete`). |
| `subscription_start` | Timestamp | Start date of the current period. |
| `subscription_end` | Timestamp | End date of the current period (access revocation date). |
| `subscription_trial_end` | Timestamp | (Optional) When the free trial ends. |
| `plan_id` | String | The Stripe Price ID for the active plan. |
| `stripe_customer_id` | String | The Stripe Customer ID associated with this brand. |
| `stripe_subscription_id` | String | The active Stripe Subscription ID. |
| `free_trial_days` | Number | The trial duration granted to this brand (snapshot). |

### Configuration (`config/subscription`)

Global configuration for new subscriptions:

| Field | Type | Description |
| :--- | :--- | :--- |
| `default_free_trial_days` | Number | Default number of trial days for new signups. |

---

## 4. Security Rules

To prevent tampering, strict Firestore rules are enforced. The client **cannot** write to subscription-related fields.

**`firestore.rules` snippet:**
```javascript
allow update: if request.auth != null && isSuperadmin() && brandId == barberBrandId()
  && !('subscription_status' in request.resource.data)
  && !('subscription_end' in request.resource.data)
  && !('plan_id' in request.resource.data)
  // ... other protected fields
```
All updates to these fields must come from the Firebase Admin SDK (Cloud Functions).

---

## 5. Backend Logic (Cloud Functions)

Located in `functions/stripe_integration.js`.

### A. `createStripeCustomer` (Trigger)
*   **Trigger**: Firestore `onCreate` for `brands/{brandId}`.
*   **Action**: Creates a Customer in Stripe with metadata `brandId: {brandId}`.
*   **Output**: Updates `brands/{brandId}` with `stripe_customer_id`.

### B. `createCheckoutSession` (Call)
*   **Input**: `brandId`, `priceId` (optional, defaults to env var), `successUrl`, `cancelUrl`.
*   **Action**:
    1.  Reads `config/subscription` to get `default_free_trial_days`.
    2.  Creates a Stripe Checkout Session with `subscription_data.trial_period_days`.
    3.  Enforces `payment_method_collection: 'always'` to ensure card capture upfront.

### C. `handleStripeWebhook` (HTTPS)
*   **Events Handled**:
    *   `customer.subscription.created`
    *   `customer.subscription.updated`
    *   `customer.subscription.deleted`
    *   `invoice.payment_failed`
*   **Action**: Extracts `brandId` from metadata and updates the corresponding Firestore document with the new status and dates.

---

## 6. Frontend Logic (Flutter)

### Data Model (`BrandEntity`)
The `BrandEntity` includes the new fields and a helper getter:

```dart
bool get isSubscriptionActive {
  if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
    return true;
  }
  // Grace period for past_due (3 days)
  if (subscriptionStatus == 'past_due' && subscriptionEnd != null) {
    final gracePeriodEnd = subscriptionEnd!.add(const Duration(days: 3));
    return DateTime.now().isBefore(gracePeriodEnd);
  }
  return false;
}
```

### Routing & Guard (`AppStageNotifier`)
The app state management watches the current brand's subscription status:

1.  **`AppStageNotifier`**: Checks `brand.isSubscriptionActive`.
2.  **`BillingLockedStage`**: Emitted if the check returns `false`.
3.  **`AppRouter`**: Redirects the user to the **`/subscription_locked`** route (`SubscriptionLockedPage`) if they are in the `BillingLockedStage`.

This ensures that no matter where the user is in the app, if the subscription expires (and the grace period passes), they are immediately redirected to the lock screen.

---

## 7. Setup & Deployment

1.  **Environment Variables**:
    Set the following secrets in Firebase Functions:
    ```bash
    firebase functions:secrets:set STRIPE_SECRET_KEY
    firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
    ```

2.  **Deploy Functions**:
    ```bash
    firebase deploy --only functions
    ```

3.  **Deploy Rules**:
    ```bash
    firebase deploy --only firestore:rules
    ```

4.  **Stripe Configuration**:
    *   Create a Product and Price in Stripe dashboard.
    *   Set the Webhook URL to: `https://<region>-<project>.cloudfunctions.net/handleStripeWebhook`
    *   Select events: `customer.subscription.*`, `invoice.*`.
