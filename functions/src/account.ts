/**
 * Account-management Cloud Functions.
 *
 * `deleteAccount` is intentionally narrow:
 *   - Wipes the user's profile doc, FCM tokens, and current subscription
 *     entry from Firestore.
 *   - Cancels any active Stripe subscription so we don't keep billing
 *     after the user is gone.
 *   - Deletes the Firebase Auth user.
 *
 * Maintenance requests authored by the user are intentionally retained
 * (other parties may still need them) — see the privacy policy for the
 * retention rationale.
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions/v2";
import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import Stripe from "stripe";

if (getApps().length === 0) {
  initializeApp();
}
const db = getFirestore();
const auth = getAuth();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

async function deleteSubcollection(uid: string, name: string): Promise<void> {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection(name)
    .get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

export const deleteAccount = onCall(
  {
    secrets: [stripeSecretKey],
    region: "us-central1",
    timeoutSeconds: 30,
  },
  async (request) => {
    const callerAuth = request.auth;
    if (!callerAuth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const uid = callerAuth.uid;

    // Cancel Stripe subscription if there is one.
    const subSnap = await db
      .collection("users")
      .doc(uid)
      .collection("subscription")
      .doc("current")
      .get();
    const stripeSubscriptionId =
      subSnap.get("stripeSubscriptionId") as string | undefined;
    if (stripeSubscriptionId) {
      try {
        const stripe = new Stripe(stripeSecretKey.value(), {
          apiVersion: "2024-10-28.acacia",
        });
        await stripe.subscriptions.cancel(stripeSubscriptionId);
      } catch (err) {
        logger.warn("Stripe cancel during deleteAccount failed", err);
      }
    }

    // Wipe per-user subcollections.
    await Promise.all([
      deleteSubcollection(uid, "fcmTokens"),
      deleteSubcollection(uid, "subscription"),
    ]);

    // Profile doc.
    await db.collection("users").doc(uid).delete();

    // Firebase Auth user — last so we still have the uid for the work above.
    await auth.deleteUser(uid);

    return {ok: true};
  },
);
