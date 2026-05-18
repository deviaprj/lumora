"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const handler = async () => {
    const now = firestore_1.Timestamp.now();
    // Load all event definitions
    const defsSnap = await db.collection("eventDefinitions").get();
    if (defsSnap.empty) {
        console.log("No event definitions found.");
        return;
    }
    for (const defDoc of defsSnap.docs) {
        const def = defDoc.data();
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
exports.handler = handler;
//# sourceMappingURL=eventScheduler.js.map