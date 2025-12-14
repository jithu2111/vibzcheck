// lib/src/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';

/// Chat message bubble widget
/// Shows different styling for host vs guest messages
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // User name and host badge
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.userName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryPurple,
                              AppColors.coolCyan,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: message.isHost && !isCurrentUser
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withValues(alpha: 0.3),
                          AppColors.coolCyan.withValues(alpha: 0.2),
                        ],
                      )
                    : null,
                color: message.isHost && !isCurrentUser
                    ? null
                    : isCurrentUser
                        ? AppColors.spotifyGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: message.isHost && !isCurrentUser
                      ? AppColors.primaryPurple.withValues(alpha: 0.3)
                      : isCurrentUser
                          ? AppColors.spotifyGreen.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
              child: Text(
                message.relativeTime,
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}