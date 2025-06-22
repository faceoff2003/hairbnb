import {onValueCreated} from "firebase-functions/v2/database";
import * as admin from "firebase-admin";

// Initialiser Firebase Admin
admin.initializeApp();

// Cloud Function qui se déclenche sur nouveau message
export const sendChatNotification = onValueCreated(
  "/messages/{chatId}/{messageId}",
  async (event) => {
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
      const recipientId = Object.keys(participants).find(
        (id) => id !== senderId,
      );

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
      const senderName = chatData.participants[senderId]?.name || "Quelqu'un";

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
    } catch (error) {
      console.error("❌ Erreur envoi notification:", error);
    }
  },
);


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
