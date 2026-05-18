import { randomBytes, randomInt, createHash, timingSafeEqual } from "crypto";
import { request as httpsRequest } from "https";
import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

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

const db = getFirestore();
const auth = getAuth();

const CODE_TTL_MINUTES = 10;
const TOKEN_TTL_MINUTES = 20;
const MAX_ATTEMPTS = 5;
const EMAIL_VERIFICATION_PEPPER = process.env.EMAIL_VERIFICATION_PEPPER ?? "";

const RESEND_API_KEY = process.env.RESEND_API_KEY ?? "";
const RESEND_FROM_EMAIL = process.env.RESEND_FROM_EMAIL ?? "";

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

function validateEmail(email: string): void {
  const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  if (!isValid) {
    throw new HttpsError("invalid-argument", "Adresse email invalide.");
  }
}

function emailDocId(email: string): string {
  return createHash("sha256").update(email).digest("hex");
}

function hashSecret(secret: string): string {
  return createHash("sha256")
    .update(`${secret}:${EMAIL_VERIFICATION_PEPPER}`)
    .digest("hex");
}

function secureEqualsHash(candidate: string, expectedHash: string): boolean {
  const candidateHash = Buffer.from(hashSecret(candidate), "utf8");
  const storedHash = Buffer.from(expectedHash, "utf8");
  if (candidateHash.length !== storedHash.length) {
    return false;
  }
  return timingSafeEqual(candidateHash, storedHash);
}

function generateCode(): string {
  return randomInt(100000, 999999).toString();
}

function generateVerificationToken(): string {
  return randomBytes(24).toString("hex");
}

function sendEmailWithResend(email: string, code: string): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    const payload = JSON.stringify({
      from: RESEND_FROM_EMAIL,
      to: [email],
      subject: "Lumora - Code de validation",
      html: `<p>Ton code Lumora est <strong>${code}</strong>.</p><p>Ce code expire dans ${CODE_TTL_MINUTES} minutes.</p>`,
    });

    const req = httpsRequest(
      {
        method: "POST",
        hostname: "api.resend.com",
        path: "/emails",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(payload),
        },
      },
      (res) => {
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
      }
    );

    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

export const sendCodeHandler = async (
  request: CallableRequest<SendCodeData>
): Promise<{ sent: boolean; emailAlreadyExists: boolean; message: string }> => {
  const email = normalizeEmail(request.data?.email ?? "");
  const intent = request.data?.intent ?? "signup";
  validateEmail(email);

  let emailAlreadyExists = false;
  try {
    await auth.getUserByEmail(email);
    emailAlreadyExists = true;
  } catch {
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
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(
    now.toMillis() + CODE_TTL_MINUTES * 60 * 1000
  );

  const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
  await ref.set(
    {
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
    },
    { merge: true }
  );

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
    message:
      "Code généré. Configure RESEND_API_KEY et RESEND_FROM_EMAIL pour un envoi réel.",
  };
};

export const verifyCodeHandler = async (
  request: CallableRequest<VerifyCodeData>
): Promise<{ verified: boolean; verificationToken?: string; message: string }> => {
  const email = normalizeEmail(request.data?.email ?? "");
  const code = (request.data?.code ?? "").trim();

  validateEmail(email);
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Code invalide.");
  }

  const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
  const snap = await ref.get();
  if (!snap.exists) {
    return { verified: false, message: "Aucun code actif." };
  }

  const data = snap.data()!;
  const expiresAt = data.expiresAt as Timestamp;
  const attempts = (data.attempts ?? 0) as number;

  if (attempts >= MAX_ATTEMPTS) {
    return { verified: false, message: "Trop de tentatives. Demande un nouveau code." };
  }

  if (expiresAt.toMillis() < Date.now()) {
    return { verified: false, message: "Code expiré." };
  }

  const expectedHash = (data.codeHash ?? "") as string;
  if (!expectedHash || !secureEqualsHash(code, expectedHash)) {
    await ref.update({ attempts: attempts + 1 });
    return { verified: false, message: "Code invalide." };
  }

  const verificationToken = generateVerificationToken();
  const tokenExpiresAt = Timestamp.fromMillis(
    Date.now() + TOKEN_TTL_MINUTES * 60 * 1000
  );

  await ref.update({
    verifiedAt: Timestamp.now(),
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

export const finalizeSignupHandler = async (
  request: CallableRequest<FinalizeSignupData>
): Promise<{ success: boolean; uid: string; customToken: string }> => {
  const email = normalizeEmail(request.data?.email ?? "");
  const password = request.data?.password ?? "";
  const verificationToken = request.data?.verificationToken ?? "";

  validateEmail(email);
  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Le mot de passe doit contenir au moins 6 caractères."
    );
  }
  if (verificationToken.length < 20) {
    throw new HttpsError("invalid-argument", "Token de validation invalide.");
  }

  const ref = db.collection("emailVerificationCodes").doc(emailDocId(email));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("failed-precondition", "Validation email manquante.");
  }

  const data = snap.data()!;
  const tokenExpiresAt = data.tokenExpiresAt as Timestamp | null;
  const consumedAt = data.consumedAt as Timestamp | null;
  const storedTokenHash = (data.verificationTokenHash ?? "") as string;

  if (consumedAt != null) {
    throw new HttpsError("already-exists", "Ce code est déjà consommé.");
  }
  if (tokenExpiresAt == null || tokenExpiresAt.toMillis() < Date.now()) {
    throw new HttpsError("deadline-exceeded", "Token expiré.");
  }
  if (!storedTokenHash || !secureEqualsHash(verificationToken, storedTokenHash)) {
    throw new HttpsError("permission-denied", "Token invalide.");
  }

  try {
    await auth.getUserByEmail(email);
    throw new HttpsError("already-exists", "Cet email existe déjà.");
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
  }

  const user = await auth.createUser({
    email,
    password,
    emailVerified: true,
  });

  await db.collection("users").doc(user.uid).set(
    {
      email,
      authProvider: "email",
      profile: {
        createdAt: Timestamp.now(),
        lastLoginAt: Timestamp.now(),
      },
    },
    { merge: true }
  );

  await ref.update({
    consumedAt: Timestamp.now(),
  });

  const customToken = await auth.createCustomToken(user.uid);
  return {
    success: true,
    uid: user.uid,
    customToken,
  };
};
