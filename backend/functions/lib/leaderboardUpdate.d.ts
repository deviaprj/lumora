import { FirestoreEvent, Change, DocumentSnapshot } from "firebase-functions/v2/firestore";
export declare const handler: (event: FirestoreEvent<Change<DocumentSnapshot> | undefined, {
    uid: string;
}>) => Promise<void>;
//# sourceMappingURL=leaderboardUpdate.d.ts.map