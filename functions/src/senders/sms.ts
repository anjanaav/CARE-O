import twilio from "twilio";
import { defineSecret } from "firebase-functions/params";
import { GuardianDoc, PermanentDeliveryError } from "../types";
import { MessageContent } from "../message";

// Set these once via:
//   firebase functions:secrets:set TWILIO_ACCOUNT_SID
//   firebase functions:secrets:set TWILIO_AUTH_TOKEN
//   firebase functions:secrets:set TWILIO_FROM_NUMBER
// Get these from https://console.twilio.com — TWILIO_FROM_NUMBER must be
// a phone number you've purchased/verified on that account, in E.164
// format (e.g. +15551234567). Twilio is paid; a trial account can only
// send to numbers you've manually verified in the console.
export const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
export const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
export const twilioFromNumber = defineSecret("TWILIO_FROM_NUMBER");

let client: ReturnType<typeof twilio> | null = null;
function getClient() {
  if (client) return client;
  const sid = twilioAccountSid.value();
  const token = twilioAuthToken.value();
  if (!sid || !token) {
    throw new Error(
      "TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN secrets are not set — SMS delivery is not configured yet."
    );
  }
  client = twilio(sid, token);
  return client;
}

/**
 * Sends an SMS via Twilio if the guardian has a phone number on file.
 * `phone` is a required field on every Guardian, so in practice this is
 * the fallback that (almost) always has something to try if push and
 * email were unavailable or failed.
 */
export async function sendSms(
  guardian: GuardianDoc,
  content: MessageContent
): Promise<boolean> {
  if (!guardian.phone) return false;

  const from = twilioFromNumber.value();
  if (!from) throw new Error("TWILIO_FROM_NUMBER secret is not set.");

  try {
    await getClient().messages.create({
      to: guardian.phone,
      from,
      body: `${content.title}\n${content.body}`,
    });
    return true;
  } catch (err: any) {
    // Twilio error codes in the 21xxx range are almost all "this number
    // is invalid / unreachable / unsubscribed" — permanent, not transient.
    const code = err?.code;
    if (typeof code === "number" && code >= 21000 && code < 22000) {
      throw new PermanentDeliveryError(`Twilio rejected the number (${code})`);
    }
    throw err;
  }
}
