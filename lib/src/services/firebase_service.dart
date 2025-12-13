// lib/src/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase service wrapper for managing all Firebase interactions
/// This centralizes Firestore, Realtime Database, and Auth operations
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters for Firebase instances
  FirebaseFirestore get firestore => _firestore;
  FirebaseDatabase get database => _database;
  FirebaseAuth get auth => _auth;

  // Collection references for Firestore
  CollectionReference get roomsCollection => _firestore.collection('rooms');
  CollectionReference get usersCollection => _firestore.collection('users');

  /// Initialize Firebase service and set up listeners
  Future<void> initialize() async {
    // Enable Firestore network on startup
    await _firestore.enableNetwork();

    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - can be logged for debugging
        // ignore: avoid_print
        // print('User signed in: ${user.uid}');
      } else {
        // User signed out - can be logged for debugging
        // ignore: avoid_print
        // print('User signed out');
      }
    });
  }

  /// Clean up resources when app is closed
  Future<void> dispose() async {
    await _firestore.disableNetwork();
  }

  // ----- ROOM OPERATIONS -----

  /// Generate a unique 4-digit room code
  Future<String> _generateUniqueRoomCode() async {
    const maxAttempts = 10;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate random 4-digit code
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      final code = random.toString().padLeft(4, '0');

      // Check if code already exists
      final existingRooms = await roomsCollection
          .where('roomCode', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingRooms.docs.isEmpty) {
        return code;
      }
    }

    // Fallback: use timestamp-based code
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 10000).toString().padLeft(4, '0');
  }

  /// Create a new room in Firestore with a unique 4-digit code
  Future<Map<String, String>> createRoom({
    required String roomName,
    required String hostId,
    required String vibe,
  }) async {
    try {
      // Generate unique room code
      final roomCode = await _generateUniqueRoomCode();

      final roomRef = await roomsCollection.add({
        'name': roomName,
        'hostId': hostId,
        'vibe': vibe,
        'roomCode': roomCode,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'currentTrack': null,
        'members': [hostId],
      });

      return {
        'roomId': roomRef.id,
        'roomCode': roomCode,
      };
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  /// Find room by code
  Future<String?> findRoomByCode(String code) async {
    try {
      final querySnapshot = await roomsCollection
          .where('roomCode', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.id;
    } catch (e) {
      throw Exception('Failed to find room: $e');
    }
  }

  /// Get room by ID
  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return roomsCollection.doc(roomId).snapshots();
  }

  /// Join a room
  Future<void> joinRoom(String roomId, String userId) async {
    try {
      await roomsCollection.doc(roomId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to join room: $e');
    }
  }

  /// Leave a room
  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await roomsCollection.doc(roomId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to leave room: $e');
    }
  }

  // ----- QUEUE OPERATIONS (Realtime Database) -----

  /// Get reference to room's queue in Realtime Database
  DatabaseReference getQueueRef(String roomId) {
    return _database.ref('queues/$roomId');
  }

  /// Add song to queue
  Future<void> addSongToQueue({
    required String roomId,
    required String songId,
    required String title,
    required String artist,
    required String albumArt,
    required String addedBy,
  }) async {
    try {
      final queueRef = getQueueRef(roomId);
      await queueRef.push().set({
        'songId': songId,
        'title': title,
        'artist': artist,
        'albumArt': albumArt,
        'addedBy': addedBy,
        'votes': 0,
        'addedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to add song to queue: $e');
    }
  }

  /// Vote on a song in the queue
  Future<void> voteOnSong({
    required String roomId,
    required String songKey,
    required int voteChange, // +1 for upvote, -1 for downvote
  }) async {
    try {
      final songRef = getQueueRef(roomId).child(songKey);
      await songRef.update({
        'votes': ServerValue.increment(voteChange),
      });
    } catch (e) {
      throw Exception('Failed to vote on song: $e');
    }
  }

  /// Remove song from queue
  Future<void> removeSongFromQueue(String roomId, String songKey) async {
    try {
      await getQueueRef(roomId).child(songKey).remove();
    } catch (e) {
      throw Exception('Failed to remove song from queue: $e');
    }
  }

  /// Listen to queue changes
  Stream<DatabaseEvent> getQueueStream(String roomId) {
    return getQueueRef(roomId).onValue;
  }

  // ----- USER OPERATIONS -----

  /// Create or update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String displayName,
    String? spotifyId,
    String? photoUrl,
  }) async {
    try {
      await usersCollection.doc(userId).set({
        'displayName': displayName,
        'spotifyId': spotifyId,
        'photoUrl': photoUrl,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get user profile
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return usersCollection.doc(userId).snapshots();
  }

  // ----- CHAT OPERATIONS -----

  /// Send a chat message to a room
  Future<void> sendChatMessage({
    required String roomId,
    required String userId,
    required String message,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add({
        'userId': userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get chat messages stream
  Stream<QuerySnapshot> getChatStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots();
  }

  // ----- REACTION OPERATIONS -----

  /// Send a reaction (e.g., fire emoji)
  Future<void> sendReaction({
    required String roomId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      // Store reaction in Realtime Database for ephemeral data
      await _database.ref('reactions/$roomId').push().set({
        'userId': userId,
        'type': reactionType,
        'timestamp': ServerValue.timestamp,
      });

      // Remove reaction after 5 seconds
      // This will be handled client-side with a timer
    } catch (e) {
      throw Exception('Failed to send reaction: $e');
    }
  }

  /// Listen to reactions
  Stream<DatabaseEvent> getReactionsStream(String roomId) {
    return _database.ref('reactions/$roomId').onValue;
  }
}