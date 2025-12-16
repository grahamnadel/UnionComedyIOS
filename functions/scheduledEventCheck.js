const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ======================================================
// 2) SCHEDULED FUNCTION: Run once per week
//    Sends push notifications for any events occurring
//    in the next 96 hours (4 days)
// ======================================================

exports.weeklyEventCheck = functions.pubsub
  .schedule("every 1 minutes") // once per week
  .timeZone("America/New_York")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const ninetySixHoursFromNow = new Date(now.getTime() + 96 * 60 * 60 * 1000);

    console.log(`Weekly check running: ${now}`);
    console.log(`Looking for performances between ${now} and ${ninetySixHoursFromNow}`);

    // 1️⃣ Get performances within the next 96 hours
    const showsSnap = await db.collection("performances")
      .where("showTime", ">=", now)
      .where("showTime", "<=", ninetySixHoursFromNow)
      .get();

    if (showsSnap.empty) {
      console.log("No upcoming shows within 96 hours.");
      return null;
    }

    const shows = showsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // 2️⃣ Get all users with FCM tokens and favoriteTeams
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      if (!userData.fcmToken || !Array.isArray(userData.favoriteTeams)) continue;

      // 3️⃣ Find any shows matching user's favorite teams
      const userShows = shows.filter(show =>
        userData.favoriteTeams.includes(show.teamName)
      );

      for (const show of userShows) {
        const message = {
          token: userData.fcmToken,
          notification: {
            title: `Upcoming Show: ${show.teamName}`,
            body: `Happening on ${new Date(show.showTime._seconds * 1000).toLocaleString()}`
          }
        };

        try {
          await admin.messaging().send(message);
          console.log(`Sent notification to ${userDoc.id} for show ${show.teamName}`);
        } catch (error) {
          console.error(`Error sending to ${userDoc.id}:`, error);
        }
      }
    }

    console.log("Weekly notification check complete.");
    return null;
  });





