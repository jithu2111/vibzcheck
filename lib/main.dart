// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/router.dart';

Future<void> main() async {
  // Ensure widgets are ready before loading env/firebase
  WidgetsFlutterBinding.ensureInitialized();

  // We will load .env here in the next step
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'Vibzcheck',
      theme: ThemeData.dark(), // Dark mode fits music apps best
    );
  }
}