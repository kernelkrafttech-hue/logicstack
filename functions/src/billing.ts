/**
 * Stripe-backed billing for MaintenanceOS.
 *
 * Three callables + one webhook + one Firestore trigger:
 *
 *   createStripeCheckoutSession     → returns hosted Checkout URL
 *   createStripeCustomerPortalSession → returns hosted Customer Portal URL
 *   stripeWebhook                  → /POST endpoint Stripe hits with events
 *   seedFreeTrialOnUserCreated     → seeds users/{uid}/subscription/current
 *
 * Secrets pulled from Firebase Functions secrets:
 *   STRIPE_SECRET_KEY
 *   STRIPE_WEBHOOK_SECRET
 *   STRIPE_PRICE_STARTER, STRIPE_PRICE_GROWTH, STRIPE_PRICE_PRO
 *   STRIPE_PORTAL_RETURN_URL  (e.g. https://your-app/return)
 *
 * Set with:
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   ...
 */

import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions/v2";
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import Stripe from "stripe";

if (getApps().length === 0) {
  initializeApp();
}
const db = getFirestore();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const stripePriceStarter = defineSecret("STRIPE_PRICE_STARTER");
const stripePriceGrowth = defineSecret("STRIPE_PRICE_GROWTH");
const stripePricePro = defineSecret("STRIPE_PRICE_PRO");
const stripeReturnUrl = defineSecret("STRIPE_PORTAL_RETURN_URL");

const TRIAL_DAYS = 14;

type PlanId = "starter" | "growth" | "pro";

function priceForPlan(planId: PlanId): string {
  switch (planId) {
    case "starter":
      return stripePriceStarter.value();
    case "growth":
      return stripePriceGrowth.value();
    case "pro":
      return stripePricePro.value();
  }
}

function planForPriceId(priceId: string | null | undefined): PlanId | null {
  if (!priceId) return null;
  if (priceId === stripePriceStarter.value()) return "starter";
  if (priceId === stripePriceGrowth.value()) return "growth";
  if (priceId === stripePricePro.value()) return "pro";
  return null;
}

function newStripeClient(): Stripe {
  return new Stripe(stripeSecretKey.value(), {
    apiVersion: "2024-10-28.acacia",
  });
}

function subscriptionDoc(uid: string) {
  return db
    .collection("users")
    .doc(uid)
    .collection("subscription")
    .doc("current");
}

/* ---------------------------------------------------------------------- */
/*  Trial seed                                                            */
/* ---------------------------------------------------------------------- */

/**
 * When a new `users/{uid}` doc lands (i.e. a tenant/landlord/contractor
 * just signed up), seed a 14-day trial. No Stripe customer yet — that's
 * created on the first checkout attempt.
 */
export const seedFreeTrialOnUserCreated = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const ref = subscriptionDoc(uid);
    const existing = await ref.get();
    if (existing.exists) return;

    const now = new Date();
    const trialEnd = new Date(now.getTime() + TRIAL_DAYS * 86400 * 1000);
    await ref.set({
      userId: uid,
      planId: "free_trial",
      status: "trialing",
      trialEnd: Timestamp.fromDate(trialEnd),
      currentPeriodEnd: Timestamp.fromDate(trialEnd),
      cancelAtPeriodEnd: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

/* ---------------------------------------------------------------------- */
/*  Checkout session                                                       */
/* ---------------------------------------------------------------------- */

interface CheckoutInput {
  planId?: unknown;
}

export const createStripeCheckoutSession = onCall<CheckoutInput>(
  {
    secrets: [
      stripeSecretKey,
      stripePriceStarter,
      stripePriceGrowth,
      stripePricePro,
      stripeReturnUrl,
    ],
    region: "us-central1",
    timeoutSeconds: 30,
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in to subscribe.");
    }
    const planId = request.data?.planId;
    if (planId !== "starter" && planId !== "growth" && planId !== "pro") {
      throw new HttpsError("invalid-argument", "Unknown plan.");
    }

    const stripe = newStripeClient();

    // Resolve / create the Stripe customer for this user.
    const subRef = subscriptionDoc(auth.uid);
    const subSnap = await subRef.get();
    let customerId = subSnap.get("stripeCustomerId") as string | undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: auth.token.email ?? undefined,
        metadata: {firebaseUid: auth.uid},
      });
      customerId = customer.id;
      await subRef.set(
        {stripeCustomerId: customerId, updatedAt: FieldValue.serverTimestamp()},
        {merge: true},
      );
    }

    const returnUrl = stripeReturnUrl.value();
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{price: priceForPlan(planId), quantity: 1}],
      allow_promotion_codes: true,
      subscription_data: {
        metadata: {firebaseUid: auth.uid, planId},
      },
      success_url: `${returnUrl}?status=success`,
      cancel_url: `${returnUrl}?status=cancelled`,
    });

    if (!session.url) {
      throw new HttpsError("internal", "Stripe did not return a URL.");
    }
    return {url: session.url};
  },
);

/* ---------------------------------------------------------------------- */
/*  Customer portal session                                                */
/* ---------------------------------------------------------------------- */

export const createStripeCustomerPortalSession = onCall(
  {
    secrets: [stripeSecretKey, stripeReturnUrl],
    region: "us-central1",
    timeoutSeconds: 30,
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const subSnap = await subscriptionDoc(auth.uid).get();
    const customerId = subSnap.get("stripeCustomerId") as string | undefined;
    if (!customerId) {
      throw new HttpsError(
        "failed-precondition",
        "No Stripe customer yet. Pick a plan first.",
      );
    }

    const stripe = newStripeClient();
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: stripeReturnUrl.value(),
    });
    return {url: session.url};
  },
);

/* ---------------------------------------------------------------------- */
/*  Webhook                                                                */
/* ---------------------------------------------------------------------- */

/**
 * Stripe webhook. Subscribe in the Stripe dashboard to:
 *   - customer.subscription.created
 *   - customer.subscription.updated
 *   - customer.subscription.deleted
 *
 * Everything we need to mirror the canonical state lives on the
 * subscription event itself; the function maps that onto
 * users/{uid}/subscription/current.
 */
export const stripeWebhook = onRequest(
  {
    secrets: [stripeSecretKey, stripeWebhookSecret],
    region: "us-central1",
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }
    const stripe = newStripeClient();
    const signature = req.headers["stripe-signature"];
    if (typeof signature !== "string") {
      res.status(400).send("Missing signature");
      return;
    }

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value(),
      );
    } catch (err) {
      logger.error("Webhook signature verification failed", err);
      res.status(400).send("Invalid signature");
      return;
    }

    try {
      switch (event.type) {
        case "customer.subscription.created":
        case "customer.subscription.updated":
          await applySubscription(event.data.object as Stripe.Subscription);
          break;
        case "customer.subscription.deleted":
          await markSubscriptionCanceled(
            event.data.object as Stripe.Subscription,
          );
          break;
        default:
          // Ignore other event types for now.
          break;
      }
      res.status(200).send("ok");
    } catch (err) {
      logger.error("Webhook handler failed", err);
      res.status(500).send("internal");
    }
  },
);

async function resolveUid(
  subscription: Stripe.Subscription,
): Promise<string | null> {
  const meta = subscription.metadata?.firebaseUid;
  if (typeof meta === "string" && meta.length > 0) return meta;

  const stripe = newStripeClient();
  const customer = await stripe.customers.retrieve(
    subscription.customer as string,
  );
  if (customer.deleted) return null;
  const uid = customer.metadata?.firebaseUid;
  return typeof uid === "string" && uid.length > 0 ? uid : null;
}

async function applySubscription(sub: Stripe.Subscription): Promise<void> {
  const uid = await resolveUid(sub);
  if (!uid) {
    logger.warn(`No firebaseUid for Stripe subscription ${sub.id}`);
    return;
  }
  const priceId = sub.items.data[0]?.price?.id;
  const planId = planForPriceId(priceId) ?? "starter";

  await subscriptionDoc(uid).set(
    {
      userId: uid,
      planId,
      status: sub.status,
      stripeCustomerId: sub.customer as string,
      stripeSubscriptionId: sub.id,
      currentPeriodEnd: Timestamp.fromMillis(sub.current_period_end * 1000),
      trialEnd:
        sub.trial_end != null
          ? Timestamp.fromMillis(sub.trial_end * 1000)
          : null,
      cancelAtPeriodEnd: sub.cancel_at_period_end,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function markSubscriptionCanceled(
  sub: Stripe.Subscription,
): Promise<void> {
  const uid = await resolveUid(sub);
  if (!uid) return;
  await subscriptionDoc(uid).set(
    {
      status: "canceled",
      cancelAtPeriodEnd: false,
      stripeSubscriptionId: sub.id,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}
