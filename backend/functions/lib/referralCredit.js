"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const REWARD_LIVES = 1;
const REWARD_HINTS = 1;
const handler = async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const { referralCode, deviceId } = request.data;
    if (!referralCode || typeof referralCode !== "string" || referralCode.length < 3) {
        throw new https_1.HttpsError("invalid-argument", "Invalid referral code.");
    }
    if (!deviceId || typeof deviceId !== "string" || deviceId.length < 8) {
        throw new https_1.HttpsError("invalid-argument", "Invalid device ID.");
    }
    const sanitizedCode = referralCode.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 32);
    const sanitizedDeviceId = deviceId.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 128);
    const referralRef = db.collection("referrals").doc(sanitizedCode);
    try {
        const result = await db.runTransaction(async (tx) => {
            const referralDoc = await tx.get(referralRef);
            if (!referralDoc.exists) {
                throw new https_1.HttpsError("not-found", "Referral code not found.");
            }
            const refData = referralDoc.data();
            const referrerUid = refData.referrerUid;
            const maxUses = (refData.maxUses ?? 0);
            const uses = (refData.uses ?? 0);
            const devices = (refData.devices ?? []);
            if (uses >= maxUses) {
                throw new https_1.HttpsError("resource-exhausted", "Referral code max uses reached.");
            }
            // Prevent duplicate device claiming
            if (devices.includes(sanitizedDeviceId)) {
                throw new https_1.HttpsError("already-exists", "This device has already been credited.");
            }
            // Prevent self-referral
            if (referrerUid === uid) {
                throw new https_1.HttpsError("permission-denied", "Self-referral is not allowed.");
            }
            // Credit referrer inventory
            const inventoryRef = db.collection("inventory").doc(referrerUid);
            const invDoc = await tx.get(inventoryRef);
            const invData = invDoc.data() ?? {};
            const currentLives = (invData.lives ?? 0);
            const currentHints = (invData.hintTokens ?? 0);
            tx.update(inventoryRef, {
                lives: currentLives + REWARD_LIVES,
                hintTokens: currentHints + REWARD_HINTS,
                lastReferralCreditAt: new Date(),
            });
            // Update referral tracking
            tx.update(referralRef, {
                uses: uses + 1,
                devices: [...devices, sanitizedDeviceId],
                lastUsedAt: new Date(),
            });
            return { success: true, referrerUid, rewardsGiven: { lives: REWARD_LIVES, hints: REWARD_HINTS } };
        });
        return result;
    }
    catch (error) {
        if (error instanceof https_1.HttpsError)
            throw error;
        console.error("referralCredit error:", error);
        throw new https_1.HttpsError("internal", "Referral credit failed.");
    }
};
exports.handler = handler;
//# sourceMappingURL=referralCredit.js.map