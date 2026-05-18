import { CallableRequest } from "firebase-functions/v2/https";
export interface DeleteData {
    uid: string;
}
export declare const handler: (request: CallableRequest<DeleteData>) => Promise<{
    success: boolean;
    deletedCollections: string[];
    anonymizedLeaderboards: number;
}>;
//# sourceMappingURL=deleteUserData.d.ts.map