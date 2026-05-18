"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const BATCH_SIZE = 500;
const handler = async () => {
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const todayStr = today.toISOString().slice(0, 10);
    const metaRef = db.collection("system").doc("dailyRewardReset");
    const metaSnap = await metaRef.get();
    // Idempotence: skip if already reset today
    if (metaSnap.exists && metaSnap.data()?.lastResetDate === todayStr) {
        console.log(`dailyRewardReset already executed for ${todayStr}`);
        return;
    }
    let lastDoc = null;
    let processed = 0;
    for (;;) {
        let query = db
            .collection("users")
            .orderBy("__name__")
            .limit(BATCH_SIZE);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snap = await query.get();
        if (snap.empty)
            break;
        const batch = db.batch();
        for (const userDoc of snap.docs) {
            const uid = userDoc.id;
            const inventoryRef = db.collection("inventory").doc(uid);
            batch.update(inventoryRef, {
                dailyRewardClaimed: false,
                dailyRewardDay: 0, // Will be computed client-side or kept as-is; reset streak if needed
                dailyRewardLastReset: today,
            });
        }
        await batch.commit();
        processed += snap.docs.length;
        lastDoc = snap.docs[snap.docs.length - 1];
        if (snap.docs.length < BATCH_SIZE)
            break;
    }
    // Mark as done
    await metaRef.set({ lastResetDate: todayStr, processedAt: new Date() }, { merge: true });
    console.log(`dailyRewardReset completed for ${todayStr}: ${processed} users`);
};
exports.handler = handler;
//# sourceMappingURL=dailyRewardReset.js.map