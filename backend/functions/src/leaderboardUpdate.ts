import { FirestoreEvent, Change, DocumentSnapshot } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

interface Participation {
  eventId: string;
  eventType: string;
  score: number;
  completedLevels: number;
  rewardsClaimed: string[];
  startedAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
}

export const handler = async (
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined, { uid: string }>
): Promise<void> => {
  const userId = event.params.uid;
  const after = event.data?.after;

  if (!after?.exists) {
    return; // Document deleted; nothing to do
  }

  const data = after.data();
  if (!data) return;

  const participations: Participation[] = data.activeParticipations ?? [];

  for (const p of participations) {
    if (p.eventType !== "tournament") continue;

    const tournamentId = p.eventId;
    const score = p.score ?? 0;
    const bestLevelTime = data.bestLevelTime ?? 0;

    // Fetch user profile for nickname denormalization
    const userDoc = await db.collection("users").doc(userId).get();
    const profile = userDoc.data()?.profile ?? {};
    const nickname = profile.displayName ?? "Joueur anonyme";

    const entryRef = db.collection("leaderboards").doc(tournamentId).collection("entries").doc(userId);

    await entryRef.set(
      {
        score,
        bestLevelTime,
        updatedAt: new Date(),
        nickname,
      },
      { merge: true }
    );

    console.log(`Leaderboard updated for tournament ${tournamentId}, user ${userId}, score ${score}`);
  }
};
