import 'package:flutter/material.dart';

import 'Screens/LoginPage.dart';
import 'Services/notifiService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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