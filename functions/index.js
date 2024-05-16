const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

const messaging = admin.messaging();

exports.notifySubscribers = functions.https.onCall(async (data, _) => {

    try {
        if(data.messageText != null) {
            message = {
                data: {
                    title: data.messageTitle,
                    body: data.messageText
                  },
                android: {
                    priority: "high"
                },
                token: data.targetDevice
            }
        } else {
            message = {
                data: {
                    roomId: data.roomId,
                    callStatus: data.callStatus,
                    caller: data.caller,
                    video: data.video
                },
                android: {
                    priority: "high"
                },
                token: data.targetDevice
            }
        }

        await messaging.send(message);

        return true;

    } catch (ex) {
        return ex;
    }
});

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
