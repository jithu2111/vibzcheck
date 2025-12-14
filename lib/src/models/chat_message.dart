// lib/src/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for chat messages in a room
class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final bool isHost;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    required this.isHost,
  });

  /// Create ChatMessage from Firestore document
  factory ChatMessage.fromFirestore(
    DocumentSnapshot doc,
    String hostId,
    Map<String, dynamic> memberNames,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] as String;
    final timestamp = data['timestamp'] as Timestamp?;

    return ChatMessage(
      id: doc.id,
      userId: userId,
      userName: memberNames[userId]?.toString() ?? 'Unknown',
      message: data['message'] as String? ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      isHost: userId == hostId,
    );
  }

  /// Get relative time string (e.g., "2m ago", "1h ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}