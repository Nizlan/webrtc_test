import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:new_rtc/signaling.dart';

class Messaging {
  static String? token;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  void setUp(Signaling signaling, RTCVideoRenderer localRenderer,
      RTCVideoRenderer remoteRenderer, BuildContext context) async {
    await getPermissions();
    FirebaseMessaging.onMessage.listen((remoteMessage) async {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('success')));
      String? roomId = remoteMessage.data['roomId'];
      if (roomId != null) {
        bool video = remoteMessage.data['video'] == "true";
        await signaling.answer(roomId, localRenderer, remoteRenderer, video);
      }
    });
  }

  Future<void> getPermissions() async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  static Future<String?> getToken() async {
    token = await messaging.getToken();
    return token;
  }

  Future<void> sendStartCall(
      String deviceToken, String roomId, String caller, bool video) async {
    var func = FirebaseFunctions.instance.httpsCallable("notifySubscribers");
    await func.call(<String, dynamic>{
      "targetDevice": deviceToken,
      "roomId": roomId,
      "caller": caller,
      "video": '$video',
      "callStatus": '',
    });
  }

  Future<void> sendMessage(String deviceToken, String messageText) async {
    var func = FirebaseFunctions.instance.httpsCallable("notifySubscribers");
    await func.call(<String, dynamic>{
      "targetDevice": deviceToken,
      "messageText": messageText,
      "messageTitle": "test title"
    });
  }

  Future<void> sendEndedCall() async {
    if (token == null) {
      return;
    }
    var func = FirebaseFunctions.instance.httpsCallable("notifySubscribers");
    await func.call(<String, dynamic>{
      "targetDevice": token,
      "callStatus": 'ended',
    });
  }
}
