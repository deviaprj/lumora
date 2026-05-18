import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export interface CheckQuotaData {
  levelId: number;
  sessionId: string;
}

export interface CheckQuotaResponse {
  allowed: boolean;
  remaining: number;
  quotaKey: string;
}

const MAX_ATTEMPTS_PER_LEVEL_SESSION = 20;
const db = getFirestore();

export const handler = async (
  request: CallableRequest<CheckQuotaData>
): Promise<CheckQuotaResponse> => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { levelId, sessionId } = request.data;
  if (
    typeof levelId !== "number" ||
    typeof sessionId !== "string" ||
    sessionId.length < 8
  ) {
    throw new HttpsError("invalid-argument", "Invalid levelId or sessionId.");
  }

  // Sanitize sessionId to prevent path traversal
  const sanitizedSessionId = sessionId.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 64);
  const quotaKey = `level_${levelId}_session_${sanitizedSessionId}`;
  const quotaRef = db.collection("quotas").doc(uid).collection("levelSessions").doc(quotaKey);

  try {
    const result = await db.runTransaction(async (tx) => {
      const doc = await tx.get(quotaRef);
      const now = new Date();

      if (!doc.exists) {
        tx.set(quotaRef, {
          attempts: 1,
          createdAt: now,
          updatedAt: now,
          levelId,
          sessionId: sanitizedSessionId,
        });
        return { allowed: true, remaining: MAX_ATTEMPTS_PER_LEVEL_SESSION - 1, quotaKey };
      }

      const data = doc.data();
      const attempts = (data?.attempts ?? 0) as number;

      if (attempts >= MAX_ATTEMPTS_PER_LEVEL_SESSION) {
        return { allowed: false, remaining: 0, quotaKey };
      }

      tx.update(quotaRef, {
        attempts: attempts + 1,
        updatedAt: now,
      });

      return { allowed: true, remaining: MAX_ATTEMPTS_PER_LEVEL_SESSION - attempts - 1, quotaKey };
    });

    return result;
  } catch (error) {
    console.error("checkQuota transaction failed:", error);
    throw new HttpsError("internal", "Quota check failed.");
  }
};
