import { getMessaging } from "firebase-admin/messaging";
import { GuardianDoc, PermanentDeliveryError } from "../types";
import { MessageContent } from "../message";

/**
 * Sends a push notification via FCM if the guardian has a stored token.
 * Guardians are entries in the *senior's* address book, not necessarily
 * Careo users themselves — most won't have an fcmToken today, since
 * nothing in the app currently registers one for them. This sender is a
 * no-op (returns false) in that case so the caller falls through to
 * email/SMS, rather than treating "no token" as an error.
 */
export async function sendPush(
  guardian: GuardianDoc,
  content: MessageContent
): Promise<boolean> {
  if (!guardian.fcmToken) return false;

  try {
    await getMessaging().send({
      token: guardian.fcmToken,
      notification: {
        title: content.title,
        body: content.body,
      },
    });
    return true;
  } catch (err: any) {
    // Unregistered/invalid tokens will never succeed again — treat as
    // permanent so the caller doesn't keep retrying just this channel.
    const code = err?.errorInfo?.code ?? err?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      throw new PermanentDeliveryError(`FCM token invalid: ${code}`);
    }
    throw err;
  }
}
