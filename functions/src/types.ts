import { Timestamp } from "firebase-admin/firestore";

/** Mirrors the shape written by NotificationOutboxRepository (Flutter). */
export interface NotificationQueueDoc {
  type: "missed_medication" | string;
  medicationName?: string;
  reminderTime?: Timestamp;
  guardianIds: string[];
  createdAt?: Timestamp;
  delivered: boolean;
  // Fields this backend adds/owns — not written by the client:
  attempts?: number;
  deliveredAt?: Timestamp;
  failed?: boolean;
  lastError?: string;
  results?: GuardianDeliveryResult[];
}

/** Mirrors the shape written by GuardianRepository (Flutter). */
export interface GuardianDoc {
  name: string;
  phone: string;
  email?: string | null;
  relationship: string;
  role: string;
  notifyMedicationReminders: boolean;
  notifyMissedMedication: boolean;
  notifyEmergencyAlerts: boolean;
  shareWellnessSummary: boolean;
  // Not written by the app today. If a guardian ever installs a
  // companion app and registers for push, it would store its token
  // here — the push sender checks for this opportunistically.
  fcmToken?: string;
}

export type DeliveryChannel = "push" | "email" | "sms";

export interface GuardianDeliveryResult {
  guardianId: string;
  channel: DeliveryChannel | "none";
  status: "sent" | "failed" | "skipped_no_contact_info";
  error?: string;
}

/** A channel attempt failed in a way that will never succeed on retry
 * (bad phone number, unregistered push token, etc). Distinguishing this
 * from a transient error (network blip, provider 500) is what lets the
 * function stop retrying instead of hammering a permanently-bad contact. */
export class PermanentDeliveryError extends Error {}
