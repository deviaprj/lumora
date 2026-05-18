"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
const handler = async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const targetUid = request.data?.uid;
    if (!targetUid || typeof targetUid !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Invalid uid.");
    }
    // Security: users can only delete their own data (GDPR self-service)
    // Admins could be added via custom claims if needed
    if (callerUid !== targetUid) {
        throw new https_1.HttpsError("permission-denied", "You can only delete your own data.");
    }
    const deletedCollections = [];
    let anonymizedLeaderboards = 0;
    try {
        // 1. Delete user profile
        const userRef = db.collection("users").doc(targetUid);
        await userRef.delete();
        deletedCollections.push("users");
        // 2. Delete progress
        const progressRef = db.collection("progress").doc(targetUid);
        await progressRef.delete();
        deletedCollections.push("progress");
        // 3. Delete inventory
        const inventoryRef = db.collection("inventory").doc(targetUid);
        await inventoryRef.delete();
        deletedCollections.push("inventory");
        // 4. Delete events
        const eventsRef = db.collection("events").doc(targetUid);
        await eventsRef.delete();
        deletedCollections.push("events");
        // 5. Delete purchases (audit log retention could be configured separately)
        const purchasesRef = db.collection("purchases").doc(targetUid);
        await purchasesRef.delete();
        deletedCollections.push("purchases");
        // 6. Anonymize leaderboard entries across all tournaments
        const leaderboardsSnap = await db.collection("leaderboards").get();
        for (const tournamentDoc of leaderboardsSnap.docs) {
            const entryRef = tournamentDoc.ref.collection("entries").doc(targetUid);
            const entrySnap = await entryRef.get();
            if (entrySnap.exists) {
                await entryRef.update({
                    nickname: "Joueur supprimé",
                    updatedAt: new Date(),
                });
                anonymizedLeaderboards++;
            }
        }
        // 7. Delete FCM tokens
        await db.collection("fcmTokens").doc(targetUid).delete();
        // 8. Delete notification counters
        await db.collection("notificationCounters").doc(targetUid).delete();
        // 9. Delete Firebase Auth account
        await auth.deleteUser(targetUid);
        console.log(`GDPR deletion completed for ${targetUid}`);
        return { success: true, deletedCollections, anonymizedLeaderboards };
    }
    catch (error) {
        console.error("deleteUserData error:", error);
        throw new https_1.HttpsError("internal", "Deletion failed.");
    }
};
exports.handler = handler;
//# sourceMappingURL=deleteUserData.js.map