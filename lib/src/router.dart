// lib/src/router.dart
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/room_screen.dart';
import 'screens/join_room_screen.dart';

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
    GoRoute(
      path: '/join-room',
      builder: (context, state) {
        final guestName = state.extra as String;
        return JoinRoomScreen(guestName: guestName);
      },
    ),
    GoRoute(
      path: '/room/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return RoomScreen(roomId: roomId);
      },
    ),
  ],
);