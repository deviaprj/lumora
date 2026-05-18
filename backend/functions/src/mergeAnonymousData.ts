import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

export interface MergeData {
  anonymousUid: string;
  authenticatedUid: string;
}

export const handler = async (
  request: CallableRequest<MergeData>
): Promise<{ success: boolean; mergedFields: string[] }> => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { anonymousUid, authenticatedUid } = request.data;
  if (!anonymousUid || !authenticatedUid || anonymousUid === authenticatedUid) {
    throw new HttpsError("invalid-argument", "Invalid UIDs.");
  }

  // Security: caller must be the authenticated account being merged into
  if (callerUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "You can only merge into your own account.");
  }

  const mergedFields: string[] = [];

  try {
    await db.runTransaction(async (tx) => {
      // 1. Progress merge
      const anonProgressRef = db.collection("progress").doc(anonymousUid);
      const authProgressRef = db.collection("progress").doc(authenticatedUid);
      const [anonProgressSnap, authProgressSnap] = await Promise.all([
        tx.get(anonProgressRef),
        tx.get(authProgressRef),
      ]);

      const anonProgress = anonProgressSnap.data() ?? {};
      const authProgress = authProgressSnap.data() ?? {};

      // Max level
      const anonLevel = (anonProgress.currentLevel ?? 0) as number;
      const authLevel = (authProgress.currentLevel ?? 0) as number;
      const mergedLevel = Math.max(anonLevel, authLevel);

      // Max stars per level
      const anonStars = (anonProgress.starsByLevel ?? {}) as Record<string, number>;
      const authStars = (authProgress.starsByLevel ?? {}) as Record<string, number>;
      const mergedStars: Record<string, number> = { ...authStars };
      for (const [lvl, starCount] of Object.entries(anonStars)) {
        mergedStars[lvl] = Math.max(mergedStars[lvl] ?? 0, starCount);
      }

      // Max world
      const anonWorld = (anonProgress.currentWorld ?? 1) as number;
      const authWorld = (authProgress.currentWorld ?? 1) as number;
      const mergedWorld = Math.max(anonWorld, authWorld);

      // Unlocked levels union
      const anonUnlocked = new Set((anonProgress.unlockedLevels ?? []) as number[]);
      const authUnlocked = new Set((authProgress.unlockedLevels ?? []) as number[]);
      const mergedUnlocked = Array.from(new Set([...anonUnlocked, ...authUnlocked])).sort((a, b) => a - b);

      const totalStars = Object.values(mergedStars).reduce((sum, s) => sum + (s ?? 0), 0);

      tx.set(
        authProgressRef,
        {
          currentLevel: mergedLevel,
          currentWorld: mergedWorld,
          starsByLevel: mergedStars,
          unlockedLevels: mergedUnlocked,
          totalStars,
          lastSyncAt: new Date(),
          mergedFrom: anonymousUid,
        },
        { merge: true }
      );
      mergedFields.push("progress");

      // 2. Inventory merge (sum consumables, union themes/cosmetics)
      const anonInventoryRef = db.collection("inventory").doc(anonymousUid);
      const authInventoryRef = db.collection("inventory").doc(authenticatedUid);
      const [anonInvSnap, authInvSnap] = await Promise.all([
        tx.get(anonInventoryRef),
        tx.get(authInventoryRef),
      ]);

      const anonInv = anonInvSnap.data() ?? {};
      const authInv = authInvSnap.data() ?? {};

      const mergedLives = Math.min(
        5,
        ((authInv.lives ?? 0) as number) + ((anonInv.lives ?? 0) as number)
      );
      const mergedHints = Math.min(
        3,
        ((authInv.hintTokens ?? 0) as number) + ((anonInv.hintTokens ?? 0) as number)
      );

      const anonThemes = new Set((anonInv.unlockedThemes ?? []) as string[]);
      const authThemes = new Set((authInv.unlockedThemes ?? []) as string[]);
      const mergedThemes = Array.from(new Set([...anonThemes, ...authThemes]));

      const anonConsumables = (anonInv.consumables ?? {}) as Record<string, number>;
      const authConsumables = (authInv.consumables ?? {}) as Record<string, number>;
      const mergedConsumables: Record<string, number> = { ...authConsumables };
      for (const [key, val] of Object.entries(anonConsumables)) {
        mergedConsumables[key] = (mergedConsumables[key] ?? 0) + (val ?? 0);
      }

      const anonCosmetics = new Set((anonInv.cosmetics ?? []) as string[]);
      const authCosmetics = new Set((authInv.cosmetics ?? []) as string[]);
      const mergedCosmetics = Array.from(new Set([...anonCosmetics, ...authCosmetics]));

      // Preserve active season pass if any
      const mergedSeasonPass = authInv.activeSeasonPass ?? anonInv.activeSeasonPass ?? null;

      tx.set(
        authInventoryRef,
        {
          lives: mergedLives,
          hintTokens: mergedHints,
          unlockedThemes: mergedThemes,
          consumables: mergedConsumables,
          cosmetics: mergedCosmetics,
          activeSeasonPass: mergedSeasonPass,
          mergedFrom: anonymousUid,
        },
        { merge: true }
      );
      mergedFields.push("inventory");

      // 3. Events merge (union activeParticipations)
      const anonEventsRef = db.collection("events").doc(anonymousUid);
      const authEventsRef = db.collection("events").doc(authenticatedUid);
      const [anonEventsSnap, authEventsSnap] = await Promise.all([
        tx.get(anonEventsRef),
        tx.get(authEventsRef),
      ]);

      const anonEvents = anonEventsSnap.data() ?? {};
      const authEvents = authEventsSnap.data() ?? {};

      const anonParticipations: Array<Record<string, unknown>> = anonEvents.activeParticipations ?? [];
      const authParticipations: Array<Record<string, unknown>> = authEvents.activeParticipations ?? [];
      const mergedParticipationsMap = new Map<string, Record<string, unknown>>();

      for (const p of authParticipations) {
        const eid = (p.eventId ?? "") as string;
        if (eid) mergedParticipationsMap.set(eid, p);
      }
      for (const p of anonParticipations) {
        const eid = (p.eventId ?? "") as string;
        if (!eid) continue;
        const existing = mergedParticipationsMap.get(eid);
        if (existing) {
          // Max score wins
          const existingScore = (existing.score ?? 0) as number;
          const pScore = (p.score ?? 0) as number;
          mergedParticipationsMap.set(eid, {
            ...p,
            score: Math.max(existingScore, pScore),
            completedLevels: Math.max(
              (existing.completedLevels ?? 0) as number,
              (p.completedLevels ?? 0) as number
            ),
            rewardsClaimed: Array.from(
              new Set([
                ...((existing.rewardsClaimed ?? []) as string[]),
                ...((p.rewardsClaimed ?? []) as string[]),
              ])
            ),
          });
        } else {
          mergedParticipationsMap.set(eid, p);
        }
      }

      tx.set(
        authEventsRef,
        {
          activeParticipations: Array.from(mergedParticipationsMap.values()),
          mergedFrom: anonymousUid,
        },
        { merge: true }
      );
      mergedFields.push("events");

      // 4. Update users/{authenticatedUid} anonymousLinkedTo and mark old anonymous data
      const authUserRef = db.collection("users").doc(authenticatedUid);
      tx.update(authUserRef, {
        anonymousLinkedTo: FieldValue.arrayUnion(anonymousUid),
        lastMergeAt: new Date(),
      });

      // Optional: mark old anonymous docs as merged (soft-delete flag)
      tx.update(anonProgressRef, { mergedInto: authenticatedUid });
      tx.update(anonInventoryRef, { mergedInto: authenticatedUid });
      tx.update(anonEventsRef, { mergedInto: authenticatedUid });
    });

    return { success: true, mergedFields };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("mergeAnonymousData error:", error);
    throw new HttpsError("internal", "Merge failed.");
  }
};
