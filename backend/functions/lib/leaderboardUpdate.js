"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const handler = async (event) => {
    const userId = event.params.uid;
    const after = event.data?.after;
    if (!after?.exists) {
        return; // Document deleted; nothing to do
    }
    const data = after.data();
    if (!data)
        return;
    const participations = data.activeParticipations ?? [];
    for (const p of participations) {
        if (p.eventType !== "tournament")
            continue;
        const tournamentId = p.eventId;
        const score = p.score ?? 0;
        const bestLevelTime = data.bestLevelTime ?? 0;
        // Fetch user profile for nickname denormalization
        const userDoc = await db.collection("users").doc(userId).get();
        const profile = userDoc.data()?.profile ?? {};
        const nickname = profile.displayName ?? "Joueur anonyme";
        const entryRef = db.collection("leaderboards").doc(tournamentId).collection("entries").doc(userId);
        await entryRef.set({
            score,
            bestLevelTime,
            updatedAt: new Date(),
            nickname,
        }, { merge: true });
        console.log(`Leaderboard updated for tournament ${tournamentId}, user ${userId}, score ${score}`);
    }
};
exports.handler = handler;
//# sourceMappingURL=leaderboardUpdate.js.map