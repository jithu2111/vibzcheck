// lib/src/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user documents in Firestore
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String userId,
    required String displayName,
    String? email,
    String? spotifyId,
    bool isGuest = false,
    bool isSpotifyPremium = false,
  }) async {
    try {
      // ignore: avoid_print
      print('💾 [USER_SERVICE] Creating/updating user document for $userId');

      final userRef = _firestore.collection('users').doc(userId);

      // Check if user already exists
      final userDoc = await userRef.get();
      final now = FieldValue.serverTimestamp();

      if (userDoc.exists) {
        // Update existing user
        // ignore: avoid_print
        print('🔄 [USER_SERVICE] User exists, updating document');

        await userRef.update({
          'displayName': displayName,
          'email': email,
          'spotifyId': spotifyId,
          'isGuest': isGuest,
          'isSpotifyPremium': isSpotifyPremium,
          'lastLoginAt': now,
          'updatedAt': now,
        });

        // ignore: avoid_print
        print('✅ [USER_SERVICE] User document updated');
      } else {
        // Create new user
        // ignore: avoid_print
        print('📝 [USER_SERVICE] Creating new user document');

        await userRef.set({
          'userId': userId,
          'displayName': displayName,
          'email': email,
          'spotifyId': spotifyId,
          'isGuest': isGuest,
          'isSpotifyPremium': isSpotifyPremium,
          'createdAt': now,
          'lastLoginAt': now,
          'updatedAt': now,
          // Additional user metadata
          'hostedRooms': 0,
          'joinedRooms': 0,
          'totalVotes': 0,
        });

        // ignore: avoid_print
        print('✅ [USER_SERVICE] New user document created');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ [USER_SERVICE] Failed to create/update user: $e');
      throw Exception('Failed to create/update user document: $e');
    }
  }

  /// Get user document from Firestore
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [USER_SERVICE] Failed to get user: $e');
      return null;
    }
  }

  /// Update user stats (rooms hosted, joined, votes)
  Future<void> updateUserStats({
    required String userId,
    int? hostedRooms,
    int? joinedRooms,
    int? totalVotes,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (hostedRooms != null) {
        updates['hostedRooms'] = FieldValue.increment(hostedRooms);
      }
      if (joinedRooms != null) {
        updates['joinedRooms'] = FieldValue.increment(joinedRooms);
      }
      if (totalVotes != null) {
        updates['totalVotes'] = FieldValue.increment(totalVotes);
      }

      await userRef.update(updates);
    } catch (e) {
      // ignore: avoid_print
      print('❌ [USER_SERVICE] Failed to update user stats: $e');
    }
  }

  /// Delete user document (for logout/account deletion)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      // ignore: avoid_print
      print('🗑️ [USER_SERVICE] User document deleted: $userId');
    } catch (e) {
      // ignore: avoid_print
      print('❌ [USER_SERVICE] Failed to delete user: $e');
    }
  }
}