// lib/src/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

// Placeholder home screen for now
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Home / Lobby",
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 16),
              Text("Coming soon!"),
            ],
          ),
        ),
      );
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);