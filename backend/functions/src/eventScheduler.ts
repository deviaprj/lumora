import { CloudEvent } from "firebase-functions/v2/core";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const db = getFirestore();

interface EventDefinition {
  type: "daily" | "weekend" | "seasonal" | "tournament" | "happy_hour";
  startAt: Timestamp;
  endAt: Timestamp;
  rules?: Record<string, unknown>;
  rewards?: Array<Record<string, unknown>>;
  requiresSeasonPass?: boolean;
  frequency?: string;
}

export const handler = async (_event: CloudEvent<unknown>): Promise<void> => {
  const now = Timestamp.now();

  // Load all event definitions
  const defsSnap = await db.collection("eventDefinitions").get();
  if (defsSnap.empty) {
    console.log("No event definitions found.");
    return;
  }

  for (const defDoc of defsSnap.docs) {
    const def = defDoc.data() as EventDefinition;
    const defId = defDoc.id;

    if (!def.startAt || !def.endAt) {
      console.warn(`Skipping event definition ${defId}: missing startAt/endAt`);
      continue;
    }

    // Check if startAt is in the future (not yet time)
    if (def.startAt.toMillis() > now.toMillis()) {
      continue;
    }

    // Check if endAt is in the past (already finished)
    if (def.endAt.toMillis() < now.toMillis()) {
      continue;
    }

    // Idempotence: check if this event instance already exists
    const eventRef = db.collection("events").doc(defId);
    const existing = await eventRef.get();

    if (existing.exists) {
      // Already created: optionally update status if needed
      const data = existing.data();
      if (data?.status === "scheduled") {
        await eventRef.update({ status: "open", openedAt: now });
        console.log(`Event ${defId} opened.`);
      }
      continue;
    }

    // Create the event instance
    await eventRef.set({
      definitionId: defId,
      type: def.type,
      startAt: def.startAt,
      endAt: def.endAt,
      rules: def.rules ?? {},
      rewards: def.rewards ?? [],
      requiresSeasonPass: def.requiresSeasonPass ?? false,
      status: "open",
      createdAt: now,
      openedAt: now,
    });

    console.log(`Event ${defId} (${def.type}) created and opened.`);
  }
};
