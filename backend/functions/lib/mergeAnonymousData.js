"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const handler = async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const { anonymousUid, authenticatedUid } = request.data;
    if (!anonymousUid || !authenticatedUid || anonymousUid === authenticatedUid) {
        throw new https_1.HttpsError("invalid-argument", "Invalid UIDs.");
    }
    // Security: caller must be the authenticated account being merged into
    if (callerUid !== authenticatedUid) {
        throw new https_1.HttpsError("permission-denied", "You can only merge into your own account.");
    }
    const mergedFields = [];
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
            const anonLevel = (anonProgress.currentLevel ?? 0);
            const authLevel = (authProgress.currentLevel ?? 0);
            const mergedLevel = Math.max(anonLevel, authLevel);
            // Max stars per level
            const anonStars = (anonProgress.starsByLevel ?? {});
            const authStars = (authProgress.starsByLevel ?? {});
            const mergedStars = { ...authStars };
            for (const [lvl, starCount] of Object.entries(anonStars)) {
                mergedStars[lvl] = Math.max(mergedStars[lvl] ?? 0, starCount);
            }
            // Max world
            const anonWorld = (anonProgress.currentWorld ?? 1);
            const authWorld = (authProgress.currentWorld ?? 1);
            const mergedWorld = Math.max(anonWorld, authWorld);
            // Unlocked levels union
            const anonUnlocked = new Set((anonProgress.unlockedLevels ?? []));
            const authUnlocked = new Set((authProgress.unlockedLevels ?? []));
            const mergedUnlocked = Array.from(new Set([...anonUnlocked, ...authUnlocked])).sort((a, b) => a - b);
            const totalStars = Object.values(mergedStars).reduce((sum, s) => sum + (s ?? 0), 0);
            tx.set(authProgressRef, {
                currentLevel: mergedLevel,
                currentWorld: mergedWorld,
                starsByLevel: mergedStars,
                unlockedLevels: mergedUnlocked,
                totalStars,
                lastSyncAt: new Date(),
                mergedFrom: anonymousUid,
            }, { merge: true });
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
            const mergedLives = Math.min(5, (authInv.lives ?? 0) + (anonInv.lives ?? 0));
            const mergedHints = Math.min(3, (authInv.hintTokens ?? 0) + (anonInv.hintTokens ?? 0));
            const anonThemes = new Set((anonInv.unlockedThemes ?? []));
            const authThemes = new Set((authInv.unlockedThemes ?? []));
            const mergedThemes = Array.from(new Set([...anonThemes, ...authThemes]));
            const anonConsumables = (anonInv.consumables ?? {});
            const authConsumables = (authInv.consumables ?? {});
            const mergedConsumables = { ...authConsumables };
            for (const [key, val] of Object.entries(anonConsumables)) {
                mergedConsumables[key] = (mergedConsumables[key] ?? 0) + (val ?? 0);
            }
            const anonCosmetics = new Set((anonInv.cosmetics ?? []));
            const authCosmetics = new Set((authInv.cosmetics ?? []));
            const mergedCosmetics = Array.from(new Set([...anonCosmetics, ...authCosmetics]));
            // Preserve active season pass if any
            const mergedSeasonPass = authInv.activeSeasonPass ?? anonInv.activeSeasonPass ?? null;
            tx.set(authInventoryRef, {
                lives: mergedLives,
                hintTokens: mergedHints,
                unlockedThemes: mergedThemes,
                consumables: mergedConsumables,
                cosmetics: mergedCosmetics,
                activeSeasonPass: mergedSeasonPass,
                mergedFrom: anonymousUid,
            }, { merge: true });
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
            const anonParticipations = anonEvents.activeParticipations ?? [];
            const authParticipations = authEvents.activeParticipations ?? [];
            const mergedParticipationsMap = new Map();
            for (const p of authParticipations) {
                const eid = (p.eventId ?? "");
                if (eid)
                    mergedParticipationsMap.set(eid, p);
            }
            for (const p of anonParticipations) {
                const eid = (p.eventId ?? "");
                if (!eid)
                    continue;
                const existing = mergedParticipationsMap.get(eid);
                if (existing) {
                    // Max score wins
                    const existingScore = (existing.score ?? 0);
                    const pScore = (p.score ?? 0);
                    mergedParticipationsMap.set(eid, {
                        ...p,
                        score: Math.max(existingScore, pScore),
                        completedLevels: Math.max((existing.completedLevels ?? 0), (p.completedLevels ?? 0)),
                        rewardsClaimed: Array.from(new Set([
                            ...(existing.rewardsClaimed ?? []),
                            ...(p.rewardsClaimed ?? []),
                        ])),
                    });
                }
                else {
                    mergedParticipationsMap.set(eid, p);
                }
            }
            tx.set(authEventsRef, {
                activeParticipations: Array.from(mergedParticipationsMap.values()),
                mergedFrom: anonymousUid,
            }, { merge: true });
            mergedFields.push("events");
            // 4. Update users/{authenticatedUid} anonymousLinkedTo and mark old anonymous data
            const authUserRef = db.collection("users").doc(authenticatedUid);
            tx.update(authUserRef, {
                anonymousLinkedTo: firestore_1.FieldValue.arrayUnion(anonymousUid),
                lastMergeAt: new Date(),
            });
            // Optional: mark old anonymous docs as merged (soft-delete flag)
            tx.update(anonProgressRef, { mergedInto: authenticatedUid });
            tx.update(anonInventoryRef, { mergedInto: authenticatedUid });
            tx.update(anonEventsRef, { mergedInto: authenticatedUid });
        });
        return { success: true, mergedFields };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError)
            throw error;
        console.error("mergeAnonymousData error:", error);
        throw new https_1.HttpsError("internal", "Merge failed.");
    }
};
exports.handler = handler;
//# sourceMappingURL=mergeAnonymousData.js.map