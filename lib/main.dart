import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movies_app/services/media_provider.dart';
import 'package:movies_app/screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:movies_app/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if we are on the same network as the server
  await AppConfig.checkConnection();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MediaProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movies App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
