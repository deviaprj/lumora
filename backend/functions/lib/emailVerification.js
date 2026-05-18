"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.finalizeSignupHandler = exports.verifyCodeHandler = exports.sendCodeHandler = void 0;
const crypto_1 = require("crypto");
const https_1 = require("https");
const https_2 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
const CODE_TTL_MINUTES = 10;
const TOKEN_TTL_MINUTES = 20;
const MAX_ATTEMPTS = 5;
const EMAIL_VERIFICATION_PEPPER = process.env.EMAIL_VERIFICATION_PEPPER ?? "";
const RESEND_API_KEY = process.env.RESEND_API_KEY ?? "";
const RESEND_FROM_EMAIL = process.env.RESEND_FROM_EMAIL ?? "";
function normalizeEmail(raw) {
    return raw.trim().toLowerCase();
}
function validateEmail(email) {
    const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    if (!isValid) {
        throw new https_2.HttpsError("invalid-argument", "Adresse email invalide.");
    }
}
function emailDocId(email) {
    return (0, crypto_1.createHash)("sha256").update(email).digest("hex");
}
function hashSecret(secret) {
    return (0, crypto_1.createHash)("sha256")
        .update(`${secret}:${EMAIL_VERIFICATION_PEPPER}`)
        .digest("hex");
}
function secureEqualsHash(candidate, expectedHash) {
    const candidateHash = Buffer.from(hashSecret(candidate), "utf8");
    const storedHash = Buffer.from(expectedHash, "utf8");
    if (candidateHash.length !== storedHash.length) {
        return false;
    }
    return (0, crypto_1.timingSafeEqual)(candidateHash, storedHash);
}
function generateCode() {
    return (0, crypto_1.randomInt)(100000, 999999).toString();
}
function generateVerificationToken() {
    return (0, crypto_1.randomBytes)(24).toString("hex");
}
function sendEmailWithResend(email, code) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            from: RESEND_FROM_EMAIL,
            to: [email],
            subject: "Lumora - Code de validation",
            html: `<p>Ton code Lumora est <strong>${code}</strong>.</p><p>Ce code expire dans ${CODE_TTL_MINUTES} minutes.</p>`,
        });
        const req = (0, https_1.request)({
            method: "POST",
            hostname: "api.resend.com",
            path: "/emails",
            headers: {
                Authorization: `Bearer ${RESEND_API_KEY}`,
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(payload),
            },
        }, (res) => {
            const statusCode = res.statusCode ?? 0;
            let body = "";
            res.on("data", (chunk) => {
                body += chunk;
            });
            res.on("end", () => {
                if (statusCode >= 200 && statusCode < 300) {
                    resolve();
                    return;
                }
                reject(new Error(`Resend failed (${statusCode}): ${body}`));
            });
        });
        req.on("error", reject);
        req.write(payload);
        req.end();
    });
}
const sendCodeHandler = async (request) => {
    const email = normalizeEmail(request.data?.email ?? "");
    const intent = request.data?.intent ?? "signup";
    validateEmail(email);
    let emailAlreadyExists = false;
    try {
        await auth.getUserByEmail(email);
        emailAlreadyExists = true;
    }
    catch {
        emailAlreadyExists = false;
    }
    if (intent === "signup" && emailAlreadyExists) {
        return {
            sent: false,
            emailAlreadyExists: true,
            message: "Cet email existe déjà.",
        };
    }
    const code = generateCode();
    const now = firestore_1.Timestamp.now();
    const expiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + CODE_TTL_MINUTES * 60 * 1000);
    const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
    await ref.set({
        email,
        codeHash: hashSecret(code),
        attempts: 0,
        intent,
        createdAt: now,
        expiresAt,
        verifiedAt: null,
        verificationTokenHash: null,
        tokenExpiresAt: null,
        consumedAt: null,
    }, { merge: true });
    if (RESEND_API_KEY.length > 0 && RESEND_FROM_EMAIL.length > 0) {
        await sendEmailWithResend(email, code);
        return {
            sent: true,
            emailAlreadyExists: false,
            message: "Code envoyé.",
        };
    }
    console.log(`DEV email verification code for ${email}: ${code}`);
    return {
        sent: true,
        emailAlreadyExists: false,
        message: "Code généré. Configure RESEND_API_KEY et RESEND_FROM_EMAIL pour un envoi réel.",
    };
};
exports.sendCodeHandler = sendCodeHandler;
const verifyCodeHandler = async (request) => {
    const email = normalizeEmail(request.data?.email ?? "");
    const code = (request.data?.code ?? "").trim();
    validateEmail(email);
    if (!/^\d{6}$/.test(code)) {
        throw new https_2.HttpsError("invalid-argument", "Code invalide.");
    }
    const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
    const snap = await ref.get();
    if (!snap.exists) {
        return { verified: false, message: "Aucun code actif." };
    }
    const data = snap.data();
    const expiresAt = data.expiresAt;
    const attempts = (data.attempts ?? 0);
    if (attempts >= MAX_ATTEMPTS) {
        return { verified: false, message: "Trop de tentatives. Demande un nouveau code." };
    }
    if (expiresAt.toMillis() < Date.now()) {
        return { verified: false, message: "Code expiré." };
    }
    const expectedHash = (data.codeHash ?? "");
    if (!expectedHash || !secureEqualsHash(code, expectedHash)) {
        await ref.update({ attempts: attempts + 1 });
        return { verified: false, message: "Code invalide." };
    }
    const verificationToken = generateVerificationToken();
    const tokenExpiresAt = firestore_1.Timestamp.fromMillis(Date.now() + TOKEN_TTL_MINUTES * 60 * 1000);
    await ref.update({
        verifiedAt: firestore_1.Timestamp.now(),
        verificationTokenHash: hashSecret(verificationToken),
        tokenExpiresAt,
        attempts: attempts + 1,
    });
    return {
        verified: true,
        verificationToken,
        message: "Email vérifié.",
    };
};
exports.verifyCodeHandler = verifyCodeHandler;
const finalizeSignupHandler = async (request) => {
    const email = normalizeEmail(request.data?.email ?? "");
    const password = request.data?.password ?? "";
    const verificationToken = request.data?.verificationToken ?? "";
    validateEmail(email);
    if (password.length < 6) {
        throw new https_2.HttpsError("invalid-argument", "Le mot de passe doit contenir au moins 6 caractères.");
    }
    if (verificationToken.length < 20) {
        throw new https_2.HttpsError("invalid-argument", "Token de validation invalide.");
    }
    const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
    const snap = await ref.get();
    if (!snap.exists) {
        throw new https_2.HttpsError("failed-precondition", "Validation email manquante.");
    }
    const data = snap.data();
    const tokenExpiresAt = data.tokenExpiresAt;
    const consumedAt = data.consumedAt;
    const storedTokenHash = (data.verificationTokenHash ?? "");
    if (consumedAt != null) {
        throw new https_2.HttpsError("already-exists", "Ce code est déjà consommé.");
    }
    if (tokenExpiresAt == null || tokenExpiresAt.toMillis() < Date.now()) {
        throw new https_2.HttpsError("deadline-exceeded", "Token expiré.");
    }
    if (!storedTokenHash || !secureEqualsHash(verificationToken, storedTokenHash)) {
        throw new https_2.HttpsError("permission-denied", "Token invalide.");
    }
    try {
        await auth.getUserByEmail(email);
        throw new https_2.HttpsError("already-exists", "Cet email existe déjà.");
    }
    catch (error) {
        if (error instanceof https_2.HttpsError) {
            throw error;
        }
    }
    const user = await auth.createUser({
        email,
        password,
        emailVerified: true,
    });
    await db.collection("users").doc(user.uid).set({
        email,
        authProvider: "email",
        profile: {
            createdAt: firestore_1.Timestamp.now(),
            lastLoginAt: firestore_1.Timestamp.now(),
        },
    }, { merge: true });
    await ref.update({
        consumedAt: firestore_1.Timestamp.now(),
    });
    const customToken = await auth.createCustomToken(user.uid);
    return {
        success: true,
        uid: user.uid,
        customToken,
    };
};
exports.finalizeSignupHandler = finalizeSignupHandler;
//# sourceMappingURL=emailVerification.js.map