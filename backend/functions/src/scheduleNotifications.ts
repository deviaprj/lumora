import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const db = getFirestore();
const messaging = getMessaging();

const MAX_PUSHES_PER_DAY = 3;

interface NotificationPayload {
  title: string;
  body: string;
  imageUrl?: string;
}

interface SegmentConfig {
  name: string;
  minDays: number;
  maxDays: number;
  timeHourLocal: number; // target local hour
  payload: NotificationPayload;
  topic?: string;
  filterPayers?: boolean;
}

const SEGMENTS: SegmentConfig[] = [
  {
    name: "churn_24h",
    minDays: 1,
    maxDays: 2,
    timeHourLocal: 20,
    payload: {
      title: "Ta récompense quotidienne t'attend !",
      body: "Reviens récupérer ta vie bonus et maintenir ta streak. ✨",
    },
    topic: "churn_24h",
  },
  {
    name: "churn_7d",
    minDays: 7,
    maxDays: 13,
    timeHourLocal: 10,
    payload: {
      title: "Ta flamme s'éteint… 🔥",
      body: "Ta streak va disparaître ! Reviens maintenant pour la préserver.",
    },
    topic: "churn_7d",
  },
  {
    name: "churn_30d",
    minDays: 30,
    maxDays: 60,
    timeHourLocal: 10,
    payload: {
      title: "Lumora a changé ! 🌟",
      body: "De nouveaux niveaux et événements t'attendent. Découvre-les !",
    },
    topic: "churn_30d",
  },
  {
    name: "near_perfect",
    minDays: 0,
    maxDays: 1,
    timeHourLocal: 18,
    payload: {
      title: "Il ne te manque qu'une étincelle ! ✨",
      body: "Tu as failli obtenir 3 étoiles. Rejoue pour le perfect !",
    },
  },
  {
    name: "active_payers",
    minDays: 0,
    maxDays: 1,
    timeHourLocal: 19,
    payload: {
      title: "Offre exclusive pour toi 💎",
      body: "Ton pack préféré est en promo Happy Hour. Ne manque pas ça !",
    },
    topic: "active_payers",
    filterPayers: true,
  },
];

function getUserLocalHour(timestamp: Timestamp, timezone: string): number {
  // Parse the Firestore timestamp into a Date, then shift to the user's timezone string
  const date = timestamp.toDate();
  try {
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone || "UTC",
      hour: "numeric",
      hour12: false,
    });
    const parts = formatter.formatToParts(date);
    const hourPart = parts.find((p) => p.type === "hour");
    return hourPart ? parseInt(hourPart.value, 10) : date.getUTCHours();
  } catch {
    return date.getUTCHours();
  }
}

export const handler = async (): Promise<void> => {
  const now = Timestamp.now();
  const nowDate = now.toDate();

  for (const segment of SEGMENTS) {
    // Only run segment if current UTC hour is close to the target local hour window
    // We run every hour, so we check if the segment should be processed now
    // Better: query users whose local hour matches target

    let query = db
      .collection("users")
      .where("profile.lastLoginAt", "<", Timestamp.fromMillis(nowDate.getTime() - segment.minDays * 86400000))
      .where("profile.lastLoginAt", ">", Timestamp.fromMillis(nowDate.getTime() - segment.maxDays * 86400000))
      .limit(500);

    // If segment requires payers, we need a subquery or post-filter (simplified here)
    const snap = await query.get();
    if (snap.empty) continue;

    const tokens: string[] = [];
    const pushCounters: Record<string, number> = {};

    for (const userDoc of snap.docs) {
      const uid = userDoc.id;
      const settings = userDoc.data()?.settings ?? {};

      if (settings.notifications === false) continue;

      const timezone = settings.timezone || "UTC";
      const userLocalHour = getUserLocalHour(now, timezone);

      // Timezone-aware: only send if within +/- 1h of target local hour
      const hourDiff = Math.abs(userLocalHour - segment.timeHourLocal);
      if (hourDiff > 1 && hourDiff < 23) continue; // skip if not in window

      // Rate limit: max 3 pushes/day
      const todayStr = nowDate.toISOString().slice(0, 10);
      const counterRef = db.collection("notificationCounters").doc(uid);
      const counterSnap = await counterRef.get();
      const counterData = counterSnap.data() ?? {};
      const sentToday = (counterData[todayStr] ?? 0) as number;
      if (sentToday >= MAX_PUSHES_PER_DAY) continue;

      // Fetch FCM token
      const tokenDoc = await db.collection("fcmTokens").doc(uid).get();
      const tokenData = tokenDoc.data();
      const token = tokenData?.token as string | undefined;
      if (!token) continue;

      tokens.push(token);
      pushCounters[uid] = sentToday + 1;
    }

    if (tokens.length === 0) continue;

    // Send via FCM multicast
    const payload = segment.payload;
    const message = {
      notification: {
        title: payload.title,
        body: payload.body,
        imageUrl: payload.imageUrl,
      },
      data: { segment: segment.name },
      android: { priority: "high" as const, notification: { channelId: "lumora_retention" } },
      apns: {
        payload: { aps: { badge: 1, sound: "default" } },
        headers: { "apns-priority": "10" },
      },
    };

    try {
      const response = await messaging.sendEachForMulticast({ tokens, ...message });
      console.log(
        `Segment ${segment.name}: sent ${response.successCount}/${tokens.length}`
      );

      // Update counters
      const batch = db.batch();
      const todayStr = nowDate.toISOString().slice(0, 10);
      for (const uid of Object.keys(pushCounters)) {
        const ref = db.collection("notificationCounters").doc(uid);
        batch.set(ref, { [todayStr]: pushCounters[uid] }, { merge: true });
      }
      await batch.commit();
    } catch (error) {
      console.error(`FCM send failed for segment ${segment.name}:`, error);
    }
  }
};
