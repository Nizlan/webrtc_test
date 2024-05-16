import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushReceiver {
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  Future<void> initLocalPush() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin!.initialize(initSettings);
  }

  void onBackgroungHandler(RemoteMessage message) {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_ID', 'channel_name', channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      vibrationPattern: Int64List.fromList(
          [0, 1000, 500, 2000]), //pattern for vibration you can set yours
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin?.show(
      0,
      message.data['title'],
      message.data['body'],
      platformChannelSpecifics,
    );
  }
}
