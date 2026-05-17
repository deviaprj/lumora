import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getMessaging } from "firebase-admin/messaging";
import { setGlobalOptions } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";

import * as checkQuotaModule from "./checkQuota";
import * as dailyRewardResetModule from "./dailyRewardReset";
import * as eventSchedulerModule from "./eventScheduler";
import * as leaderboardUpdateModule from "./leaderboardUpdate";
import * as purchaseValidationModule from "./purchaseValidation";
import * as referralCreditModule from "./referralCredit";
import * as mergeAnonymousDataModule from "./mergeAnonymousData";
import * as scheduleNotificationsModule from "./scheduleNotifications";
import * as deleteUserDataModule from "./deleteUserData";

// Initialize Firebase Admin SDK once
const app = initializeApp();
export const db = getFirestore(app);
export const auth = getAuth(app);
export const messaging = getMessaging(app);

// Global options for all v2 functions
setGlobalOptions({
  region: "europe-west1",
  memory: "256MiB",
  timeoutSeconds: 60,
});

// 1. checkQuota — HTTPS callable (anti-cheat quota check)
export const checkQuota = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 10,
  },
  checkQuotaModule.handler
);

// 2. dailyRewardReset — Scheduled at 00:00 UTC
export const dailyRewardReset = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  dailyRewardResetModule.handler
);

// 3. eventScheduler — Scheduled (every 15 minutes to cover daily/weekend/seasonal/tournament/happy_hour)
export const eventScheduler = onSchedule(
  {
    schedule: "*/15 * * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  eventSchedulerModule.handler
);

// 4. leaderboardUpdate — Firestore trigger on events/{uid} writes
export const leaderboardUpdate = onDocumentWritten(
  {
    document: "events/{uid}",
    memory: "1GiB",
    timeoutSeconds: 120,
  },
  leaderboardUpdateModule.handler
);

// 5. purchaseValidation — HTTPS function (RevenueCat webhook)
export const purchaseValidation = onRequest(
  {
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  purchaseValidationModule.handler
);

// 6. referralCredit — HTTPS callable
export const referralCredit = onCall(
  {
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  referralCreditModule.handler
);

// 7. mergeAnonymousData — HTTPS callable
export const mergeAnonymousData = onCall(
  {
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  mergeAnonymousDataModule.handler
);

// 8. scheduleNotifications — Scheduled every hour
export const scheduleNotifications = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  scheduleNotificationsModule.handler
);

// 9. deleteUserData — HTTPS callable (GDPR)
export const deleteUserData = onCall(
  {
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  deleteUserDataModule.handler
);
