import { CallableRequest } from "firebase-functions/v2/https";
export interface MergeData {
    anonymousUid: string;
    authenticatedUid: string;
}
export declare const handler: (request: CallableRequest<MergeData>) => Promise<{
    success: boolean;
    mergedFields: string[];
}>;
//# sourceMappingURL=mergeAnonymousData.d.ts.map