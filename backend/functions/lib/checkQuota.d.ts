import { CallableRequest } from "firebase-functions/v2/https";
export interface CheckQuotaData {
    levelId: number;
    sessionId: string;
}
export interface CheckQuotaResponse {
    allowed: boolean;
    remaining: number;
    quotaKey: string;
}
export declare const handler: (request: CallableRequest<CheckQuotaData>) => Promise<CheckQuotaResponse>;
//# sourceMappingURL=checkQuota.d.ts.map