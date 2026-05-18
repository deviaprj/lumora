import * as checkQuotaModule from "./checkQuota";
import * as referralCreditModule from "./referralCredit";
import * as mergeAnonymousDataModule from "./mergeAnonymousData";
import * as deleteUserDataModule from "./deleteUserData";
import * as emailVerificationModule from "./emailVerification";
export declare const db: FirebaseFirestore.Firestore;
export declare const auth: import("firebase-admin/auth").Auth;
export declare const messaging: import("firebase-admin/messaging").Messaging;
export declare const checkQuota: import("firebase-functions/v2/https").CallableFunction<checkQuotaModule.CheckQuotaData, Promise<checkQuotaModule.CheckQuotaResponse>>;
export declare const dailyRewardReset: import("firebase-functions/v2/scheduler").ScheduleFunction;
export declare const eventScheduler: import("firebase-functions/v2/scheduler").ScheduleFunction;
export declare const leaderboardUpdate: import("firebase-functions/v2").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    uid: string;
}>>;
export declare const purchaseValidation: import("firebase-functions/v2/https").HttpsFunction;
export declare const referralCredit: import("firebase-functions/v2/https").CallableFunction<referralCreditModule.ReferralData, Promise<{
    success: boolean;
    referrerUid: string;
    rewardsGiven: {
        lives: number;
        hints: number;
    };
}>>;
export declare const mergeAnonymousData: import("firebase-functions/v2/https").CallableFunction<mergeAnonymousDataModule.MergeData, Promise<{
    success: boolean;
    mergedFields: string[];
}>>;
export declare const scheduleNotifications: import("firebase-functions/v2/scheduler").ScheduleFunction;
export declare const deleteUserData: import("firebase-functions/v2/https").CallableFunction<deleteUserDataModule.DeleteData, Promise<{
    success: boolean;
    deletedCollections: string[];
    anonymizedLeaderboards: number;
}>>;
export declare const sendEmailVerificationCode: import("firebase-functions/v2/https").CallableFunction<emailVerificationModule.SendCodeData, Promise<{
    sent: boolean;
    emailAlreadyExists: boolean;
    message: string;
}>>;
export declare const verifyEmailVerificationCode: import("firebase-functions/v2/https").CallableFunction<emailVerificationModule.VerifyCodeData, Promise<{
    verified: boolean;
    verificationToken?: string;
    message: string;
}>>;
export declare const finalizeEmailSignup: import("firebase-functions/v2/https").CallableFunction<emailVerificationModule.FinalizeSignupData, Promise<{
    success: boolean;
    uid: string;
    customToken: string;
}>>;
//# sourceMappingURL=index.d.ts.map