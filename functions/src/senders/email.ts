import sgMail from "@sendgrid/mail";
import { defineSecret } from "firebase-functions/params";
import { GuardianDoc, PermanentDeliveryError } from "../types";
import { MessageContent } from "../message";

// Set these once via:
//   firebase functions:secrets:set SENDGRID_API_KEY
//   firebase functions:secrets:set SENDGRID_FROM_EMAIL
// SENDGRID_FROM_EMAIL must be an address you've verified in SendGrid
// (Single Sender Verification or a verified domain) — sends will fail
// otherwise. Get an API key at https://app.sendgrid.com/settings/api_keys.
export const sendgridApiKey = defineSecret("SENDGRID_API_KEY");
export const sendgridFromEmail = defineSecret("SENDGRID_FROM_EMAIL");

let configured = false;
function ensureConfigured() {
  if (configured) return;
  const key = sendgridApiKey.value();
  if (!key) {
    throw new Error(
      "SENDGRID_API_KEY secret is not set — email delivery is not configured yet."
    );
  }
  sgMail.setApiKey(key);
  configured = true;
}

/**
 * Sends an email via SendGrid if the guardian has an email on file.
 * Returns false (not an error) when there's simply no email to send to,
 * so the caller can fall through to SMS.
 */
export async function sendEmail(
  guardian: GuardianDoc,
  content: MessageContent
): Promise<boolean> {
  if (!guardian.email) return false;

  ensureConfigured();
  const from = sendgridFromEmail.value();
  if (!from) {
    throw new Error("SENDGRID_FROM_EMAIL secret is not set.");
  }

  try {
    await sgMail.send({
      to: guardian.email,
      from,
      subject: content.title,
      text: content.body,
    });
    return true;
  } catch (err: any) {
    const status = err?.code ?? err?.response?.statusCode;
    // 4xx from SendGrid (bad/blocked address, etc.) won't fix itself on
    // retry; 5xx or network errors might.
    if (typeof status === "number" && status >= 400 && status < 500) {
      throw new PermanentDeliveryError(
        `SendGrid rejected the address (HTTP ${status})`
      );
    }
    throw err;
  }
}
