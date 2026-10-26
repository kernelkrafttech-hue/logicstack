/**
 * Notification triggers for MaintenanceOS.
 *
 * Each trigger:
 *   1. Resolves the recipient set (uids) from the event data.
 *   2. Writes an `notifications/{id}` doc per recipient.
 *   3. Sends an FCM push to every token under
 *      `users/{uid}/fcmTokens/*` for that recipient.
 *
 * The admin SDK bypasses Firestore rules, so the client-facing rule that
 * forbids notification creates stays in effect.
 */

import {onDocumentCreated, onDocumentUpdated} from
  "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {initializeApp, getApps} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {getAuth} from "firebase-admin/auth";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();
const messaging = getMessaging();
const auth = getAuth();

const STATUS_DISPLAY: Record<string, string> = {
  submitted: "Submitted",
  reviewed: "Reviewed",
  sent_to_contractor: "Sent to contractor",
  accepted: "Accepted",
  scheduled: "Scheduled",
  in_progress: "In progress",
  completed: "Completed",
  closed: "Closed",
  cancelled: "Cancelled",
};

const ROLE_DISPLAY: Record<string, string> = {
  landlord: "Landlord",
  tenant: "Tenant",
  contractor: "Contractor",
};

interface RequestData {
  tenantId?: string;
  landlordId?: string;
  contractorId?: string;
  contractorName?: string;
  contractorEmail?: string;
  status?: string;
  title?: string;
}

/** Fan out a single notification to one or more uids. */
async function dispatch(
  recipients: ReadonlyArray<string>,
  payload: {
    title: string;
    body: string;
    requestId: string;
  },
): Promise<void> {
  const unique = Array.from(new Set(recipients.filter((u) => !!u)));
  if (unique.length === 0) return;

  await Promise.all(
    unique.map(async (uid) => {
      try {
        await Promise.all([
          writeNotificationDoc(uid, payload),
          sendPush(uid, payload),
        ]);
      } catch (err) {
        logger.error(
          `Failed to deliver notification to ${uid}`,
          err,
        );
      }
    }),
  );
}

async function writeNotificationDoc(
  uid: string,
  payload: {title: string; body: string; requestId: string},
): Promise<void> {
  await db.collection("notifications").add({
    userId: uid,
    title: payload.title,
    body: payload.body,
    requestId: payload.requestId,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function sendPush(
  uid: string,
  payload: {title: string; body: string; requestId: string},
): Promise<void> {
  const tokensSnap = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();
  const tokens = tokensSnap.docs.map((d) => d.id).filter((t) => t.length > 0);
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      requestId: payload.requestId,
    },
  });

  // Clean up tokens the FCM service rejects as no-longer-registered.
  const stale: string[] = [];
  response.responses.forEach((resp, i) => {
    if (resp.success) return;
    const code = resp.error?.code ?? "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      stale.push(tokens[i]);
    }
  });
  if (stale.length === 0) return;
  await Promise.all(
    stale.map((t) =>
      db.collection("users").doc(uid).collection("fcmTokens").doc(t).delete(),
    ),
  );
}

/** Best-effort uid lookup for a contractor's email. */
async function uidForEmail(email: string | undefined): Promise<string | null> {
  if (!email) return null;
  try {
    const u = await auth.getUserByEmail(email);
    return u.uid;
  } catch (_) {
    return null;
  }
}

/* ---------------------------------------------------------------------- */
/*  Triggers                                                              */
/* ---------------------------------------------------------------------- */

/** Tenant submitted a new request → notify the landlord. */
export const notifyOnRequestCreated = onDocumentCreated(
  "maintenanceRequests/{requestId}",
  async (event) => {
    const data = event.data?.data() as RequestData | undefined;
    if (!data) return;
    const requestId = event.params.requestId;
    const landlordId = data.landlordId;
    if (!landlordId) return;

    await dispatch([landlordId], {
      title: "New maintenance request",
      body: data.title ?? "A tenant has submitted a new request.",
      requestId,
    });
  },
);

/**
 * Status change or contractor assignment.
 *
 * If the assignment fields just landed, we treat it as an assignment event
 * and notify the new contractor + tenant. Otherwise, when status changed,
 * we notify the tenant + assigned contractor.
 */
export const notifyOnRequestUpdated = onDocumentUpdated(
  "maintenanceRequests/{requestId}",
  async (event) => {
    const before = event.data?.before.data() as RequestData | undefined;
    const after = event.data?.after.data() as RequestData | undefined;
    if (!before || !after) return;
    const requestId = event.params.requestId;

    const justAssigned =
      (after.contractorId ?? "") !== (before.contractorId ?? "") &&
      (after.contractorId ?? "") !== "";

    if (justAssigned) {
      const contractorUid = await uidForEmail(after.contractorEmail);
      const recipients: string[] = [];
      if (after.tenantId) recipients.push(after.tenantId);
      if (contractorUid) recipients.push(contractorUid);

      await dispatch(recipients, {
        title: "Contractor assigned",
        body: `${after.contractorName ?? "A contractor"} was assigned to "${
          after.title ?? "your request"
        }".`,
        requestId,
      });
      return;
    }

    const statusChanged = (after.status ?? "") !== (before.status ?? "");
    if (statusChanged) {
      const display =
        STATUS_DISPLAY[after.status ?? ""] ?? after.status ?? "updated";
      const recipients: string[] = [];
      if (after.tenantId) recipients.push(after.tenantId);
      const contractorUid = await uidForEmail(after.contractorEmail);
      if (contractorUid) recipients.push(contractorUid);
      // Don't drop the landlord if the contractor is the one moving the
      // job through their lifecycle.
      if (after.landlordId) recipients.push(after.landlordId);

      await dispatch(recipients, {
        title: `Status: ${display}`,
        body: `"${after.title ?? "Maintenance request"}" is now ${display.toLowerCase()}.`,
        requestId,
      });
    }
  },
);

interface CommentData {
  senderId?: string;
  senderName?: string;
  senderRole?: string;
  text?: string;
}

/** New comment → notify every other party on the parent request. */
export const notifyOnCommentCreated = onDocumentCreated(
  "maintenanceRequests/{requestId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data() as CommentData | undefined;
    if (!comment) return;
    const requestId = event.params.requestId;

    const parentSnap = await db
      .collection("maintenanceRequests")
      .doc(requestId)
      .get();
    const parent = parentSnap.data() as RequestData | undefined;
    if (!parent) return;

    const recipients: string[] = [];
    if (parent.tenantId && parent.tenantId !== comment.senderId) {
      recipients.push(parent.tenantId);
    }
    if (parent.landlordId && parent.landlordId !== comment.senderId) {
      recipients.push(parent.landlordId);
    }
    const contractorUid = await uidForEmail(parent.contractorEmail);
    if (contractorUid && contractorUid !== comment.senderId) {
      recipients.push(contractorUid);
    }

    const senderRoleLabel =
      ROLE_DISPLAY[comment.senderRole ?? ""] ?? "Someone";
    const senderName = comment.senderName ?? senderRoleLabel;

    await dispatch(recipients, {
      title: `New comment from ${senderName}`,
      body: comment.text ?? "",
      requestId,
    });
  },
);
