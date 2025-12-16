const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ======================================================
// 1) HTTP FUNCTION: Send a manual push notification
// ======================================================

exports.sendPush = functions.https.onRequest(async (req, res) => {
  try {
    const { token, title, body, data } = req.body;

    if (!token) {
      return res.status(400).send({ error: "Missing FCM token" });
    }

    const message = {
      token,
      notification: {
        title: title || "Notification",
        body: body || "You have a message."
      },
      data: data || {}
    };

    const response = await admin.messaging().send(message);
    return res.status(200).send({ success: true, id: response });

  } catch (error) {
    console.error("sendPush error:", error);
    return res.status(500).send({ error: error.message });
  }
});
