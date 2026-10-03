# Careo notification delivery backend

Implements the Cloud Function described in
`lib/features/notifications/README.md`: it watches
`users/{uid}/notification_queue/{queueId}` and actually delivers each
entry to the consented guardians, instead of leaving the queue unread.

## What this does and doesn't do

- Triggers on **creation** of a queue document (Firestore `onDocumentCreated`).
- Looks up each `guardianIds` entry under the same user, and tries **push
  (FCM) → email (SendGrid) → SMS (Twilio)**, in that order, stopping at
  the first channel that succeeds for that guardian.
- Marks the queue document `delivered: true` once at least one guardian
  received something, or `failed: true` if every attempt was a dead end
  (no usable contact info, or repeated transient failures past the retry
  cap). It never retries forever or fails silently.
- Does **not** invent delivery it can't actually perform. If you deploy
  this without setting up SendGrid or Twilio, email/SMS sends will throw
  a clear "secret not set" error and the entry will be marked failed
  rather than pretending to have sent something.

Push (FCM) will currently almost never fire, because nothing in the
Flutter app registers an `fcmToken` on a guardian document — guardians
are entries in the senior's address book, not necessarily people who
have Careo installed. It's wired up and ready for the day a guardian
companion app registers a token; until then, email/SMS are the real
delivery paths.

## What you need to decide and provide (I can't do this part for you)

This requires **your** accounts and **your** budget — a backend
processing health-related alerts needs real provider credentials, and
those should never be hardcoded or committed to the repo:

1. **A Firebase Blaze (pay-as-you-go) plan.** Cloud Functions with
   outbound network calls (to SendGrid/Twilio) require it — the free
   Spark plan won't deploy this.
2. **A SendGrid account** (or swap in another provider) for email —
   free tier covers low volume: https://sendgrid.com
   - Verify a sender address (Single Sender Verification, or a domain).
3. **A Twilio account** for SMS — this one is paid per message, no free
   tier for production sending: https://www.twilio.com
   - Buy/verify a phone number to send from.
4. Decide whether SMS cost is even acceptable for your expected message
   volume, or whether you'd rather ship push+email only for now and add
   Twilio later. Both senders degrade gracefully if unconfigured — a
   missing Twilio secret just means SMS is skipped as failed, everything
   else still works.

## One-time setup

```bash
cd functions
npm install

# Log in and select your Firebase project (already set in ../.firebaserc)
firebase login
firebase use careonew-ebd63

# Upgrade to Blaze if you haven't:
# https://console.firebase.google.com/project/careonew-ebd63/usage/details

# Store your provider credentials as Cloud Functions secrets (never in code):
firebase functions:secrets:set SENDGRID_API_KEY
firebase functions:secrets:set SENDGRID_FROM_EMAIL
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_FROM_NUMBER
```

Each `secrets:set` command prompts you to paste the value — it's stored
in Secret Manager, not in your source tree.

## Deploy

```bash
npm run deploy
# equivalent to: firebase deploy --only functions
```

## Local testing without spending money

```bash
firebase emulators:start --only functions,firestore
```

Point your Flutter app's Firebase config at the emulator, add a
guardian with `notifyMissedMedication: true`, trigger a missed-medication
queue write, and watch the emulator logs. Without secrets configured
locally, email/SMS sends will fail fast with a clear "not configured"
error — that's expected, not a bug.

## Monitoring

```bash
npm run logs
# or: firebase functions:log
```

Failed queue entries are left in Firestore with `failed: true` and a
`lastError` string — worth a periodic manual check (or a future
scheduled function that alerts *you* when entries pile up failed).
