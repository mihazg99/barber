const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const Stripe = require("stripe");

const db = admin.firestore();
const COLLECTION_BRANDS = "brands";
const COLLECTION_CONFIG = "config";

/**
 * Creates a Stripe customer when a new brand is created.
 */
exports.createStripeCustomer = onDocumentCreated(
    {
        document: `${COLLECTION_BRANDS}/{brandId}`,
        region: "europe-west1",
        secrets: ["STRIPE_SECRET_KEY"],
    },
    async (event) => {
        const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
        const brandId = event.params.brandId;
        const brandData = event.data.data();

        if (!brandData) return;

        try {
            const customer = await stripe.customers.create({
                email: brandData.contact_email,
                name: brandData.name,
                metadata: {
                    brandId: brandId,
                },
            });

            await event.data.ref.update({
                stripe_customer_id: customer.id,
            });

            logger.info("Created Stripe customer for brand", { brandId, customerId: customer.id });
        } catch (error) {
            logger.error("Failed to create Stripe customer", { brandId, error: error.message });
        }
    }
);

/**
 * Creates a Stripe Checkout Session for subscription.
 * Uses 'setup' mode if just collecting card, or 'subscription' mode.
 * 
 * If free_trial_days > 0, we use subscription mode with trial_period_days.
 * We force 'payment_method_collection': 'always' to ensure card is captured upfront.
 */
exports.createCheckoutSession = onCall(
    {
        region: "europe-west1",
        secrets: ["STRIPE_SECRET_KEY"],
    },
    async (request) => {
        const { brandId, planId, successUrl, cancelUrl } = request.data;

        // 1. Validate User Permissions (Must be owner/admin of brand)
        // For simplicity here assume caller is authorized or check context.auth
        // In production: verify request.auth.uid is owner of brandId or superadmin.

        if (!brandId || !planId) {
            throw new HttpsError('invalid-argument', 'Missing brandId or planId');
        }

        const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

        try {
            const brandDoc = await db.collection(COLLECTION_BRANDS).doc(brandId).get();
            if (!brandDoc.exists) {
                throw new HttpsError('not-found', 'Brand not found');
            }
            const brandData = brandDoc.data();
            let customerId = brandData.stripe_customer_id;

            // Create customer if missing
            if (!customerId) {
                const customer = await stripe.customers.create({
                    email: brandData.contact_email,
                    name: brandData.name,
                    metadata: { brandId: brandId },
                });
                customerId = customer.id;
                await brandDoc.ref.update({ stripe_customer_id: customerId });
            }

            // Determine Trial Days
            // Priority: Brand specific > Global Config > 0
            let trialDays = brandData.free_trial_days;
            if (trialDays === undefined || trialDays === null) {
                const configDoc = await db.collection(COLLECTION_CONFIG).doc('subscription').get();
                trialDays = configDoc.exists ? configDoc.data().default_free_trial_days : 0;
            }

            // Ensure trialDays is a number
            trialDays = Number(trialDays) || 0;

            // Simplify: If user already had a subscription, maybe deny trial?
            // For now, we trust the logic: if config says trial, we give trial.

            const sessionParams = {
                customer: customerId,
                mode: 'subscription',
                payment_method_collection: 'always', // Force card upfront
                line_items: [{ price: planId, quantity: 1 }],
                success_url: successUrl,
                cancel_url: cancelUrl,
                subscription_data: {
                    trial_period_days: trialDays > 0 ? trialDays : undefined,
                    metadata: { brandId: brandId }
                },
                metadata: { brandId: brandId },
            };

            const session = await stripe.checkout.sessions.create(sessionParams);
            return { url: session.url };

        } catch (error) {
            logger.error("createCheckoutSession failed", { error: error.message });
            throw new HttpsError('internal', error.message);
        }
    }
);

/**
 * Handles Stripe Webhooks to sync subscription status to Firestore.
 */
exports.handleStripeWebhook = onRequest(
    {
        region: "europe-west1",
        secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"],
    },
    async (req, res) => {
        const sig = req.headers['stripe-signature'];
        const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
        const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
        let event;

        try {
            event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
        } catch (err) {
            logger.error(`Webhook signature verification failed.`, err.message);
            res.status(400).send(`Webhook Error: ${err.message}`);
            return;
        }

        try {
            switch (event.type) {
                case 'checkout.session.completed': {
                    const session = event.data.object;
                    const brandId = session.metadata?.brandId;
                    if (brandId && session.subscription) {
                        // We trust customer.subscription.created/updated to handle the main sync, 
                        // but we can set a flag here if needed. 
                        // For now, allow subscription events to drive the state.
                        logger.info("Checkout session completed", { brandId, subscriptionId: session.subscription });
                    }
                    break;
                }

                case 'customer.subscription.created':
                case 'customer.subscription.updated': {
                    const subscription = event.data.object;
                    const brandId = subscription.metadata?.brandId;

                    if (!brandId) {
                        logger.warn("Subscription event missing brandId metadata", { id: subscription.id });
                        break;
                    }

                    const status = subscription.status; // active, trialing, past_due, canceled, unpaid
                    const currentPeriodEnd = new Date(subscription.current_period_end * 1000);
                    const trialEnd = subscription.trial_end ? new Date(subscription.trial_end * 1000) : null;

                    const updateData = {
                        stripe_subscription_id: subscription.id,
                        subscription_status: status,
                        subscription_end: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
                        plan_id: subscription.items.data[0]?.price?.id,
                    };

                    if (trialEnd) {
                        updateData.subscription_trial_end = admin.firestore.Timestamp.fromDate(trialEnd);
                    }

                    // Map Stripe status to our internal simplified status if needed, 
                    // but 'active', 'trialing', 'past_due', 'canceled' map 1:1 nicely.

                    await db.collection(COLLECTION_BRANDS).doc(brandId).update(updateData);
                    logger.info("Updated subscription status", { brandId, status });
                    break;
                }

                case 'customer.subscription.deleted': {
                    const subscription = event.data.object;
                    const brandId = subscription.metadata?.brandId;
                    if (brandId) {
                        await db.collection(COLLECTION_BRANDS).doc(brandId).update({
                            subscription_status: 'canceled',
                        });
                        logger.info("Subscription canceled", { brandId });
                    }
                    break;
                }

                case 'invoice.payment_failed': {
                    const invoice = event.data.object;
                    const subscriptionId = invoice.subscription;
                    // We rely on subscription.updated (which usually triggers with status='past_due')
                    // but logging here is useful.
                    logger.warn("Invoice payment failed", { subscriptionId });
                    break;
                }
            }
        } catch (error) {
            logger.error("Error processing webhook", error);
            res.status(500).send("Internal Server Error");
            return;
        }

        res.json({ received: true });
    }
);
