# Delivering queued guardian notifications

## Status: backend built, needs your provider credentials to go live

The Cloud Function that delivers these has been built — see
`/functions` at the repo root, and `/functions/README.md` for exactly
what you need to set up (a Firebase Blaze plan, a SendGrid account, and
optionally a Twilio account) before it actually sends anything. Nothing
sends until you provide those credentials; the function fails loudly
and marks entries `failed: true` rather than pretending to deliver.

## What exists today (client-side, in this repo)

`NotificationOutboxRepository` writes documents to
`/users/{uid}/notification_queue/{id}` whenever the app detects something
a guardian has consented to hear about — currently just missed medication.
Each document looks like:

```json
{
  "type": "missed_medication",
  "medicationName": "Metformin",
  "reminderTime": <Firestore Timestamp>,
  "guardianIds": ["abc123", "def456"],
  "createdAt": <server Timestamp>,
  "delivered": false
}
```

`guardianIds` only ever contains guardians whose Firestore document has
`notifyMissedMedication: true` — consent is already enforced before the
entry is written, not left for the backend to check.

**The Flutter app itself never sends a push notification, SMS, or email
directly** — it only ever writes to this queue. Actual delivery is the
Cloud Function in `/functions`, which holds the provider credentials the
app bundle must never contain.

## What was built to deliver these

The Cloud Function living in `/functions` does exactly this:

1. Triggers on document creation in any `users/{uid}/notification_queue/{id}`
   path (`onDocumentCreated`, Cloud Functions v2).
2. Reads the `guardianIds` off the new document, then reads each
   `users/{uid}/guardians/{guardianId}` document to get that guardian's
   phone number / email — the function runs with the Admin SDK, so it can
   read across users, which the app itself is never allowed to do (see
   `firestore.rules`).
3. Sends the actual notification, trying **push (FCM) → email (SendGrid)
   → SMS (Twilio)** and stopping at the first channel that succeeds. Push
   will rarely fire today since no guardian-facing app registers an
   `fcmToken` yet — see `functions/README.md`.
4. Updates the queue document: `{ "delivered": true, "deliveredAt": ... }`
   on success, or `{ "failed": true, "lastError": ... }` once it's retried
   past the cap.
5. Is idempotent and caps retries at 5 attempts rather than retrying a
   permanently-bad contact forever.

Standing it up still required choosing and provisioning a paid SMS/push
provider, storing credentials in a secrets manager the app never sees,
and deploying server code — see `functions/README.md` for exactly what
you need to provide (a Firebase Blaze plan, SendGrid, optionally Twilio)
before it sends anything live. Until those credentials are set, the
function fails loudly and marks entries `failed: true` rather than
pretending to deliver — faking delivery client-side would give the
senior user's family a false sense that they'd be notified.
