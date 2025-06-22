"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendChatNotification = void 0;
const database_1 = require("firebase-functions/v2/database");
const admin = __importStar(require("firebase-admin"));
// Initialiser Firebase Admin
admin.initializeApp();
// Cloud Function qui se déclenche sur nouveau message
exports.sendChatNotification = (0, database_1.onValueCreated)("/messages/{chatId}/{messageId}", async (event) => {
    var _a;
    try {
        const snapshot = event.data;
        const message = snapshot.val();
        const chatId = event.params.chatId;
        console.log(`📨 Nouveau message dans chat ${chatId}:`, message);
        // Récupérer les infos du chat pour trouver le destinataire
        const chatRef = admin.database().ref(`/chats/${chatId}`);
        const chatSnapshot = await chatRef.once("value");
        const chatData = chatSnapshot.val();
        if (!chatData) {
            console.log("❌ Chat non trouvé");
            return;
        }
        // Identifier le destinataire (celui qui n'a pas envoyé le message)
        const participants = chatData.participants || {};
        const senderId = message.senderId;
        const recipientId = Object.keys(participants).find((id) => id !== senderId);
        if (!recipientId) {
            console.log("❌ Destinataire non trouvé");
            return;
        }
        // Récupérer le token FCM du destinataire
        const tokenRef = admin.database().ref(`/fcm_tokens/${recipientId}`);
        const tokenSnapshot = await tokenRef.once("value");
        const tokenData = tokenSnapshot.val();
        if (!tokenData || !tokenData.token) {
            console.log(`❌ Token FCM non trouvé pour ${recipientId}`);
            return;
        }
        // Récupérer le nom de l'expéditeur
        const senderName = ((_a = chatData.participants[senderId]) === null || _a === void 0 ? void 0 : _a.name) || "Quelqu'un";
        // Construire et envoyer la notification
        const payload = {
            notification: {
                title: `💬 ${senderName}`,
                body: message.content || "Nouveau message",
            },
            data: {
                chatId: chatId,
                senderId: senderId,
                type: "chat_message",
            },
            token: tokenData.token,
        };
        const response = await admin.messaging().send(payload);
        console.log("✅ Notification envoyée:", response);
    }
    catch (error) {
        console.error("❌ Erreur envoi notification:", error);
    }
});
// /**
//  * Import function triggers from their respective submodules:
//  *
//  * import {onCall} from "firebase-functions/v2/https";
//  * import {onDocumentWritten} from "firebase-functions/v2/firestore";
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */
//
// import {onRequest} from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";
//
// // Start writing functions
// // https://firebase.google.com/docs/functions/typescript
//
// // export const helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });
//# sourceMappingURL=index.js.map