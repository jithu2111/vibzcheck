// lib/src/screens/room_screen_chat_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';

/// Chat tab widget - displays chat messages with fire reaction button
class ChatTab extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String hostId;
  final Map<String, dynamic> memberNames;
  final VoidCallback onReaction;

  const ChatTab({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.hostId,
    required this.memberNames,
    required this.onReaction,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _firebaseService.sendChatMessage(
        roomId: widget.roomId,
        userId: widget.currentUserId,
        message: message,
      );

      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getChatStream(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading messages',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPurple,
                  ),
                );
              }

              final messages = snapshot.data!.docs
                  .map((doc) => ChatMessage.fromFirestore(
                        doc,
                        widget.hostId,
                        widget.memberNames,
                      ))
                  .toList();

              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to say something!',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Auto-scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return ChatBubble(
                    message: message,
                    isCurrentUser: message.userId == widget.currentUserId,
                  );
                },
              );
            },
          ),
        ),

        // Input Field with Fire Button
        _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Fire Reaction Button
          IconButton(
            onPressed: widget.onReaction,
            icon: const Text(
              '🔥',
              style: TextStyle(fontSize: 24),
            ),
            tooltip: 'Send fire reaction',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.warmGlow.withValues(alpha: 0.2),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: AppColors.textDisabled),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.primaryPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.coolCyan],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}