import { CallableRequest } from "firebase-functions/v2/https";
export interface SendCodeData {
    email: string;
    intent?: "signup" | "signin";
}
export interface VerifyCodeData {
    email: string;
    code: string;
}
export interface FinalizeSignupData {
    email: string;
    password: string;
    verificationToken: string;
}
export declare const sendCodeHandler: (request: CallableRequest<SendCodeData>) => Promise<{
    sent: boolean;
    emailAlreadyExists: boolean;
    message: string;
}>;
export declare const verifyCodeHandler: (request: CallableRequest<VerifyCodeData>) => Promise<{
    verified: boolean;
    verificationToken?: string;
    message: string;
}>;
export declare const finalizeSignupHandler: (request: CallableRequest<FinalizeSignupData>) => Promise<{
    success: boolean;
    uid: string;
    customToken: string;
}>;
//# sourceMappingURL=emailVerification.d.ts.map