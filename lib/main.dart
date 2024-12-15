import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/home/home.dart';
import 'package:smarthome/login/login.dart';
import 'package:smarthome/signin/final.dart';
import 'package:smarthome/welcome/spalsh.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Firebase web initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDQl-zOIFLisl8K4LRZH12Pw4aRtnztCXQ",
          authDomain: "smart-c2aaf.firebaseapp.com",
          projectId: "smart-c2aaf",
          storageBucket: "smart-c2aaf.firebasestorage.app",
          messagingSenderId: "63612868248",
          appId: "1:63612868248:web:dcfc0ef20c7f7fec0ea2ed"),
    );
  } else {
    // Firebase initialization for other platforms
    await Firebase.initializeApp();
  }
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Notification channel for alerts',
        defaultColor: Colors.red,
        ledColor: Colors.white,
      )
    ],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
