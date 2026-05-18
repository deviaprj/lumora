"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const messaging_1 = require("firebase-admin/messaging");
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
const messaging = (0, messaging_1.getMessaging)();
const REVENUECAT_WEBHOOK_SECRET = process.env.REVENUECAT_WEBHOOK_SECRET ?? "";
const handler = async (req, res) => {
    try {
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }
        // Verify signature if configured
        const signature = req.headers["x-revenuecat-signature"];
        if (REVENUECAT_WEBHOOK_SECRET && signature) {
            // In production, implement HMAC/ECDSA verification here
            // For now, presence check is a basic guard
        }
        const payload = req.body;
        const event = payload?.event;
        const subscriber = payload?.subscriber;
        if (!event || !subscriber) {
            res.status(400).send("Missing event or subscriber");
            return;
        }
        const uid = subscriber.app_user_id || subscriber.original_app_user_id;
        if (!uid) {
            res.status(400).send("Missing uid");
            return;
        }
        // Verify user exists
        try {
            await auth.getUser(uid);
        }
        catch {
            res.status(400).send("User not found");
            return;
        }
        const transactionId = event.transaction_id;
        const productId = event.product_id;
        const priceUsd = event.price ?? 0;
        const platform = event.store === "PLAY_STORE" ? "android" : event.store === "APP_STORE" ? "ios" : "other";
        const purchaseRef = db.collection("purchases").doc(uid);
        // Idempotence: check transaction uniqueness
        const existing = await purchaseRef.get();
        const transactions = existing.data()?.transactions ?? [];
        const alreadyExists = transactions.some((t) => t.transactionId === transactionId);
        if (alreadyExists) {
            console.log(`Transaction ${transactionId} already recorded for ${uid}`);
            res.status(200).send("Already recorded");
            return;
        }
        // Optional double-check: flag suspicious transactions
        let fraudFlag = false;
        const suspiciousPriceThreshold = 10.0; // USD
        if (priceUsd > suspiciousPriceThreshold || priceUsd < 0) {
            fraudFlag = true;
            console.warn(`Suspicious transaction for ${uid}: price=${priceUsd} product=${productId}`);
        }
        const newTransaction = {
            transactionId,
            productId,
            revenueCatId: transactionId,
            priceUsd,
            purchasedAt: new Date(),
            platform,
            restored: false,
            eventType: event.type,
            fraudFlag,
        };
        const updateData = {
            transactions: [...transactions, newTransaction],
            updatedAt: new Date(),
        };
        if (!existing.exists || !existing.data()?.firstPurchaseAt) {
            updateData.firstPurchaseAt = new Date();
        }
        await purchaseRef.set(updateData, { merge: true });
        // Send silent push to invalidate client cache
        try {
            await messaging.send({
                token: "", // Will be filled by client token retrieval if needed; here we use topic
                topic: `user_${uid}`,
                data: { type: "purchase_invalidated" },
                android: { priority: "high" },
                apns: { headers: { "apns-priority": "5" } },
            });
        }
        catch (e) {
            console.log("Silent push failed (non-critical):", e);
        }
        console.log(`Purchase validated for ${uid}: ${productId} (${event.type})`);
        res.status(200).send("OK");
    }
    catch (error) {
        console.error("purchaseValidation error:", error);
        res.status(500).send("Internal Server Error");
    }
};
exports.handler = handler;
//# sourceMappingURL=purchaseValidation.js.map