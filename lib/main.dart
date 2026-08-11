import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'Screens/LoginPage.dart';
import 'Services/notifiService.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Cloud Messaging
  FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  // Ask the user for notification permission
  await messaging.requestPermission();

  // Get the FCM device token
  String? token = await messaging.getToken();

  debugPrint('====================================');
  debugPrint('FCM DEVICE TOKEN:');
  debugPrint(token);
  debugPrint('====================================');

  // Initialize local notifications
  await NotifiService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Elderly Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}