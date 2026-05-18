"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.finalizeEmailSignup = exports.verifyEmailVerificationCode = exports.sendEmailVerificationCode = exports.deleteUserData = exports.scheduleNotifications = exports.mergeAnonymousData = exports.referralCredit = exports.purchaseValidation = exports.leaderboardUpdate = exports.eventScheduler = exports.dailyRewardReset = exports.checkQuota = exports.messaging = exports.auth = exports.db = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const messaging_1 = require("firebase-admin/messaging");
const v2_1 = require("firebase-functions/v2");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_2 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const checkQuotaModule = __importStar(require("./checkQuota"));
const dailyRewardResetModule = __importStar(require("./dailyRewardReset"));
const eventSchedulerModule = __importStar(require("./eventScheduler"));
const leaderboardUpdateModule = __importStar(require("./leaderboardUpdate"));
const purchaseValidationModule = __importStar(require("./purchaseValidation"));
const referralCreditModule = __importStar(require("./referralCredit"));
const mergeAnonymousDataModule = __importStar(require("./mergeAnonymousData"));
const scheduleNotificationsModule = __importStar(require("./scheduleNotifications"));
const deleteUserDataModule = __importStar(require("./deleteUserData"));
const emailVerificationModule = __importStar(require("./emailVerification"));
// Initialize Firebase Admin SDK once
const app = (0, app_1.initializeApp)();
exports.db = (0, firestore_1.getFirestore)(app);
exports.auth = (0, auth_1.getAuth)(app);
exports.messaging = (0, messaging_1.getMessaging)(app);
// Global options for all v2 functions
(0, v2_1.setGlobalOptions)({
    region: "europe-west1",
    memory: "256MiB",
    timeoutSeconds: 60,
});
// 1. checkQuota — HTTPS callable (anti-cheat quota check)
exports.checkQuota = (0, https_1.onCall)({
    memory: "256MiB",
    timeoutSeconds: 10,
}, checkQuotaModule.handler);
// 2. dailyRewardReset — Scheduled at 00:00 UTC
exports.dailyRewardReset = (0, scheduler_1.onSchedule)({
    schedule: "0 0 * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 300,
}, dailyRewardResetModule.handler);
// 3. eventScheduler — Scheduled (every 15 minutes to cover daily/weekend/seasonal/tournament/happy_hour)
exports.eventScheduler = (0, scheduler_1.onSchedule)({
    schedule: "*/15 * * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 120,
}, eventSchedulerModule.handler);
// 4. leaderboardUpdate — Firestore trigger on events/{uid} writes
exports.leaderboardUpdate = (0, firestore_2.onDocumentWritten)({
    document: "events/{uid}",
    memory: "1GiB",
    timeoutSeconds: 120,
}, leaderboardUpdateModule.handler);
// 5. purchaseValidation — HTTPS function (RevenueCat webhook)
exports.purchaseValidation = (0, https_1.onRequest)({
    memory: "512MiB",
    timeoutSeconds: 60,
}, purchaseValidationModule.handler);
// 6. referralCredit — HTTPS callable
exports.referralCredit = (0, https_1.onCall)({
    memory: "256MiB",
    timeoutSeconds: 30,
}, referralCreditModule.handler);
// 7. mergeAnonymousData — HTTPS callable
exports.mergeAnonymousData = (0, https_1.onCall)({
    memory: "512MiB",
    timeoutSeconds: 60,
}, mergeAnonymousDataModule.handler);
// 8. scheduleNotifications — Scheduled every hour
exports.scheduleNotifications = (0, scheduler_1.onSchedule)({
    schedule: "0 * * * *",
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 300,
}, scheduleNotificationsModule.handler);
// 9. deleteUserData — HTTPS callable (GDPR)
exports.deleteUserData = (0, https_1.onCall)({
    memory: "512MiB",
    timeoutSeconds: 120,
}, deleteUserDataModule.handler);
// 10. sendEmailVerificationCode — HTTPS callable
exports.sendEmailVerificationCode = (0, https_1.onCall)({
    memory: "256MiB",
    timeoutSeconds: 30,
}, emailVerificationModule.sendCodeHandler);
// 11. verifyEmailVerificationCode — HTTPS callable
exports.verifyEmailVerificationCode = (0, https_1.onCall)({
    memory: "256MiB",
    timeoutSeconds: 30,
}, emailVerificationModule.verifyCodeHandler);
// 12. finalizeEmailSignup — HTTPS callable
exports.finalizeEmailSignup = (0, https_1.onCall)({
    memory: "512MiB",
    timeoutSeconds: 60,
}, emailVerificationModule.finalizeSignupHandler);
//# sourceMappingURL=index.js.map