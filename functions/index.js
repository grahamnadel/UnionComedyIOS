const functions = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPush = functions.onRequest(async (req, res) => {
  try {
    const token = req.body.token;
    const title = req.body.title || "Default Title";
    const body = req.body.body || "Default body text";

    const message = {
      token,
      notification: {
        title: title,
        body: body
      },
      data: req.body.data || {}
    };

    const response = await admin.messaging().send(message);
    res.status(200).send({ success: true, id: response });
  } catch (error) {
    console.error("Error sending push:", error);
    res.status(500).send({ success: false, error });
  }
});

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
