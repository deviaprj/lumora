import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

interface ReferralData {
  referralCode: string;
  deviceId: string;
}

const REWARD_LIVES = 1;
const REWARD_HINTS = 1;

export const handler = async (
  request: CallableRequest<ReferralData>
): Promise<{ success: boolean; referrerUid: string; rewardsGiven: { lives: number; hints: number } }> => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { referralCode, deviceId } = request.data;
  if (!referralCode || typeof referralCode !== "string" || referralCode.length < 3) {
    throw new HttpsError("invalid-argument", "Invalid referral code.");
  }
  if (!deviceId || typeof deviceId !== "string" || deviceId.length < 8) {
    throw new HttpsError("invalid-argument", "Invalid device ID.");
  }

  const sanitizedCode = referralCode.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 32);
  const sanitizedDeviceId = deviceId.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 128);

  const referralRef = db.collection("referrals").doc(sanitizedCode);

  try {
    const result = await db.runTransaction(async (tx) => {
      const referralDoc = await tx.get(referralRef);
      if (!referralDoc.exists) {
        throw new HttpsError("not-found", "Referral code not found.");
      }

      const refData = referralDoc.data()!;
      const referrerUid = refData.referrerUid as string;
      const maxUses = (refData.maxUses ?? 0) as number;
      const uses = (refData.uses ?? 0) as number;
      const devices = (refData.devices ?? []) as string[];

      if (uses >= maxUses) {
        throw new HttpsError("resource-exhausted", "Referral code max uses reached.");
      }

      // Prevent duplicate device claiming
      if (devices.includes(sanitizedDeviceId)) {
        throw new HttpsError("already-exists", "This device has already been credited.");
      }

      // Prevent self-referral
      if (referrerUid === uid) {
        throw new HttpsError("permission-denied", "Self-referral is not allowed.");
      }

      // Credit referrer inventory
      const inventoryRef = db.collection("inventory").doc(referrerUid);
      const invDoc = await tx.get(inventoryRef);
      const invData = invDoc.data() ?? {};
      const currentLives = (invData.lives ?? 0) as number;
      const currentHints = (invData.hintTokens ?? 0) as number;

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
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("referralCredit error:", error);
    throw new HttpsError("internal", "Referral credit failed.");
  }
};
