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


// ======================================================
// 2) SCHEDULED FUNCTION: Run once per week
//    Sends push notifications for any events occurring
//    in the next 96 hours (4 days)
// ======================================================

exports.weeklyEventCheck = functions.pubsub
  .schedule("every sunday 00:00")   // runs once per week
  .timeZone("America/New_York")     // change if needed
  .onRun(async () => {

    const now = Date.now();
    const ninetySixHoursFromNow = now + (96 * 60 * 60 * 1000);

    console.log("Weekly check running at:", new Date(now).toString());
    console.log("Checking events between now and:", new Date(ninetySixHoursFromNow).toString());

    // Get events that haven't been notified yet
    const eventsSnap = await admin.firestore()
      .collection("events")
      .where("notify96Sent", "==", false)
      .get();

    if (eventsSnap.empty) {
      console.log("No events needing notification.");
      return null;
    }

    for (const doc of eventsSnap.docs) {
      const data = doc.data();

      if (!data.eventTime || !data.token) {
        console.log(`Event ${doc.id} is missing eventTime or token`);
        continue;
      }

      const eventTime = data.eventTime.toMillis();

      // Check if the event is within the next 96 hours
      const isUpcoming =
        eventTime >= now &&
        eventTime <= ninetySixHoursFromNow;

      if (isUpcoming) {
        console.log(`Sending notification for event ${doc.id}`);

        await admin.messaging().send({
          token: data.token,
          notification: {
            title: data.title || "Upcoming Event!",
            body: data.body || "Something is happening soon!"
          }
        });

        // Mark so it doesn't send again next week
        await doc.ref.update({ notify96Sent: true });
      }
    }

    return null;
  });

