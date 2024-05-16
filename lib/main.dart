import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_rtc/main_page.dart';
import 'package:new_rtc/push_message.dart';
import 'firebase_options.dart';

PushReceiver pushReceiver = PushReceiver();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (pushReceiver.flutterLocalNotificationsPlugin == null) {
    await pushReceiver.initLocalPush();
  }

  print('messageData ${message.data}');

  pushReceiver.onBackgroungHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // callKeep.setup(callSetup);
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, name: 'Call');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}
