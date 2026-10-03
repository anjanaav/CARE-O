import { NotificationQueueDoc } from "./types";

export interface MessageContent {
  title: string;
  body: string;
}

/**
 * Builds the human-readable notification for a queue entry. `type` is
 * whatever the client wrote (currently only "missed_medication"); anything
 * unrecognized still gets a safe, generic message instead of crashing the
 * function, so a future client-side type doesn't silently fail delivery
 * until this file is updated.
 */
export function buildMessage(
  seniorName: string,
  doc: NotificationQueueDoc
): MessageContent {
  switch (doc.type) {
    case "missed_medication": {
      const med = doc.medicationName ?? "a medication";
      const time = doc.reminderTime
        ? doc.reminderTime.toDate().toLocaleTimeString([], {
            hour: "numeric",
            minute: "2-digit",
          })
        : "the scheduled time";
      return {
        title: `Missed medication: ${seniorName}`,
        body: `${seniorName} has not confirmed taking ${med}, scheduled for ${time}. You're receiving this because you're listed as a Care Circle contact for missed-medication alerts.`,
      };
    }
    default: {
      return {
        title: `Careo alert for ${seniorName}`,
        body: `${seniorName}'s Careo app has an update for you. Open the app for details.`,
      };
    }
  }
}
