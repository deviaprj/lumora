import { CallableRequest } from "firebase-functions/v2/https";
export interface ReferralData {
    referralCode: string;
    deviceId: string;
}
export declare const handler: (request: CallableRequest<ReferralData>) => Promise<{
    success: boolean;
    referrerUid: string;
    rewardsGiven: {
        lives: number;
        hints: number;
    };
}>;
//# sourceMappingURL=referralCredit.d.ts.map