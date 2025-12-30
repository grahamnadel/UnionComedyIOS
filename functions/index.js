const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
admin.initializeApp();

exports.weeklyEventCheck = onSchedule("0 19 * * 4", async (event) => {
    const db = admin.firestore();
    const now = new Date();
    const ninetySixHoursFromNow = new Date(now.getTime() + 96 * 60 * 60 * 1000);


    logger.info(`Weekly check running: ${now}`, { structuredData: true });
    logger.info(`Looking for performances between ${now} and ${ninetySixHoursFromNow}`, { structuredData: true });

    // Get performances within the next 96 hours
    const showsSnap = await db.collection("festivalTeams")
        //.where("showTimes", ">=", now)
        //.where("showTimes", "<=", ninetySixHoursFromNow)
        .get();

    if (showsSnap.empty) {
        logger.info("No upcoming shows within 96 hours.");
        return;
    }

    const shows = showsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Get all users with FCM tokens and favoriteTeams
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
        const userData = userDoc.data();
        if (!userData.fcmToken || !Array.isArray(userData.favoriteTeams)) continue;        

	// Find any shows matching user's favorite teams
        const userShows = shows.filter(show =>
            userData.favoriteTeams.includes(show.name)
        );

        for (const show of userShows) {	
		const secondsValue = show.showTimes[0]._seconds
		const milliseconds = secondsValue * 1000;
		const showDate = new Date(milliseconds);
		const dayOfWeek = showDate.toLocaleDateString('en-US', { weekday: 'long' });
		const timeString = showDate.toLocaleTimeString('en-US', {
			hour: 'numeric',
			minute: '2-digit',
			hour12: true
		});

		const dateString = `${dayOfWeek} at ${timeString}`;
		
		console.log(`dateString: ${JSON.stringify(dateString, null, 2)}`);
	            
		const message = {
                	token: userData.fcmToken,
                	notification: {
                    	title: `${show.name}`,
                    	body: `${dateString}`
                	}
            	};
// DEBUG
	console.log(`Debug: token: ${userData.fcmToken}\n userShows: ${userShows}`);		


            try {
                await admin.messaging().send(message);
		logger.info(`Sent notification to ${userDoc.id} for show ${show.name}`);
            } catch (error) {
                logger.error(`Error sending to ${userDoc.id}:`, error);
            }
        }
    }

    logger.info("Weekly notification check complete.");
});


//exports.sendPush = functions.onRequest(async (req, res) => {
//  try {
//    const token = req.body.token;
//    const title = req.body.title || "Default Title";
//    const body = req.body.body || "Default body text";

//    const message = {
//      token,
//      notification: {
//        title: title,
//        body: body
//      },
//      data: req.body.data || {}
//    };

//    const response = await admin.messaging().send(message);
//    res.status(200).send({ success: true, id: response });
//  } catch (error) {
//    console.error("Error sending push:", error);
//    res.status(500).send({ success: false, error });
//  }
//});

