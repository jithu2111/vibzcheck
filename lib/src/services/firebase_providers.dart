// lib/src/services/firebase_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';

/// Provider for the Firebase service singleton
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Example: Provider for current room stream
/// Usage: ref.watch(roomStreamProvider(roomId))
final roomStreamProvider = StreamProvider.family((ref, String roomId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getRoomStream(roomId);
});

/// Example: Provider for queue stream
/// Usage: ref.watch(queueStreamProvider(roomId))
final queueStreamProvider = StreamProvider.family((ref, String roomId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getQueueStream(roomId);
});

/// Example: Provider for chat messages stream
/// Usage: ref.watch(chatStreamProvider(roomId))
final chatStreamProvider = StreamProvider.family((ref, String roomId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getChatStream(roomId);
});

/// Example: Provider for current user stream
/// Usage: ref.watch(userStreamProvider(userId))
final userStreamProvider = StreamProvider.family((ref, String userId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getUserStream(userId);
});

/// Example: Provider for reactions stream
/// Usage: ref.watch(reactionsStreamProvider(roomId))
final reactionsStreamProvider = StreamProvider.family((ref, String roomId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getReactionsStream(roomId);
});