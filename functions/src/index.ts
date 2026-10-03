import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import {
  GuardianDeliveryResult,
  GuardianDoc,
  NotificationQueueDoc,
  PermanentDeliveryError,
} from "./types";
import { buildMessage } from "./message";
import { sendPush } from "./senders/push";
import { sendEmail, sendgridApiKey, sendgridFromEmail } from "./senders/email";
import {
  sendSms,
  twilioAccountSid,
  twilioAuthToken,
  twilioFromNumber,
} from "./senders/sms";

initializeApp();
const db = getFirestore();

/** Automatic-retry ceiling. Firestore triggers can be retried by throwing,
 * but we cap it ourselves too so a permanently-misconfigured secret (say,
 * SendGrid never set up) doesn't retry forever — after this many attempts
 * the entry is marked failed and left for manual/human follow-up instead
 * of silently vanishing or looping. */
const MAX_ATTEMPTS = 5;

/**
 * Delivers one Care Circle member's notification, trying push -> email ->
 * SMS in that order and stopping at the first channel that succeeds.
 * Guardians aren't required to have any particular contact method beyond
 * `phone`, so this is intentionally tolerant of missing channels.
 */
async function deliverToGuardian(
  guardianId: string,
  guardian: GuardianDoc,
  content: { title: string; body: string }
): Promise<GuardianDeliveryResult> {
  const attempts: Array<[GuardianDeliveryResult["channel"], () => Promise<boolean>]> = [
    ["push", () => sendPush(guardian, content)],
    ["email", () => sendEmail(guardian, content)],
    ["sms", () => sendSms(guardian, content)],
  ];

  let lastError: string | undefined;
  for (const [channel, attempt] of attempts) {
    try {
      const sent = await attempt();
      if (sent) return { guardianId, channel, status: "sent" };
    } catch (err) {
      lastError = err instanceof Error ? err.message : String(err);
      logger.warn(
        `Delivery to guardian ${guardianId} via ${channel} failed`,
        { error: lastError, permanent: err instanceof PermanentDeliveryError }
      );
      // Permanent errors on one channel just mean "try the next channel";
      // they don't need to bubble up and abort the whole guardian.
    }
  }

  return {
    guardianId,
    channel: "none",
    status: lastError ? "failed" : "skipped_no_contact_info",
    error: lastError,
  };
}

export const deliverGuardianNotification = onDocumentCreated(
  {
    document: "users/{uid}/notification_queue/{queueId}",
    secrets: [
      sendgridApiKey,
      sendgridFromEmail,
      twilioAccountSid,
      twilioAuthToken,
      twilioFromNumber,
    ],
    retry: true,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, queueId } = event.params as { uid: string; queueId: string };
    const docRef = snap.ref;
    const data = snap.data() as NotificationQueueDoc;

    // Idempotency guard: with `retry: true`, Cloud Functions may redeliver
    // the same create event. If a previous run already finished this
    // entry, there's nothing left to do.
    if (data.delivered || data.failed) return;

    const attemptNumber = (data.attempts ?? 0) + 1;
    if (attemptNumber > MAX_ATTEMPTS) {
      await docRef.update({
        failed: true,
        lastError: "Exceeded maximum delivery attempts",
      });
      logger.error(`Queue item ${queueId} for user ${uid} exceeded retry limit`);
      return;
    }

    try {
      const [userSnap, guardianSnaps] = await Promise.all([
        db.collection("users").doc(uid).get(),
        Promise.all(
          data.guardianIds.map((gid) =>
            db.collection("users").doc(uid).collection("guardians").doc(gid).get()
          )
        ),
      ]);

      const seniorName = (userSnap.data()?.fullName as string | undefined) ?? "Your family member";
      const content = buildMessage(seniorName, data);

      const results: GuardianDeliveryResult[] = [];
      for (const guardianSnap of guardianSnaps) {
        if (!guardianSnap.exists) {
          results.push({
            guardianId: guardianSnap.id,
            channel: "none",
            status: "skipped_no_contact_info",
            error: "Guardian document no longer exists",
          });
          continue;
        }
        const guardian = guardianSnap.data() as GuardianDoc;
        results.push(await deliverToGuardian(guardianSnap.id, guardian, content));
      }

      const anySent = results.some((r) => r.status === "sent");
      const anyRetryable = results.some((r) => r.status === "failed");

      if (anySent || !anyRetryable) {
        // Either we got at least one message out, or every remaining
        // failure is a dead end (no contact info) — nothing left to
        // usefully retry.
        await docRef.update({
          delivered: anySent,
          failed: !anySent,
          deliveredAt: anySent ? FieldValue.serverTimestamp() : null,
          attempts: attemptNumber,
          results,
        });
      } else {
        // Every guardian hit a transient failure and none succeeded —
        // worth another attempt. Record progress, then throw so
        // `retry: true` schedules a redelivery of this event.
        await docRef.update({ attempts: attemptNumber, results });
        throw new Error(
          `All ${results.length} guardian(s) failed transiently on attempt ${attemptNumber}`
        );
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error(`Queue item ${queueId} for user ${uid} failed`, { error: message });
      // Re-throw only if we haven't already written a terminal state above
      // and haven't hit the attempt ceiling — lets `retry: true` work.
      if (attemptNumber < MAX_ATTEMPTS) {
        await docRef.update({ attempts: attemptNumber, lastError: message });
        throw err;
      }
      await docRef.update({ failed: true, attempts: attemptNumber, lastError: message });
    }
  }
);
