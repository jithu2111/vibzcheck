import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import 'dart:ui';

/// Room detail screen - Shows room code, members, and queue with tabs
class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyRoomCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    try {
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser != null) {
        await _firebaseService.leaveRoom(widget.roomId, currentUser.uid);
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getVibeColor(String vibe) {
    switch (vibe) {
      case 'chill':
        return AppColors.coolCyan;
      case 'party':
        return AppColors.warmGlow;
      case 'hype':
        return AppColors.spotifyGreen;
      case 'study':
        return AppColors.primaryPurple;
      default:
        return AppColors.primaryPurple;
    }
  }

  IconData _getVibeIcon(String vibe) {
    switch (vibe) {
      case 'chill':
        return Icons.nightlight_round;
      case 'party':
        return Icons.celebration;
      case 'hype':
        return Icons.bolt;
      case 'study':
        return Icons.menu_book_rounded;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebaseService.getRoomStream(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading room',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            ),
          );
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>?;

        if (roomData == null) {
          return Scaffold(
            backgroundColor: AppColors.deepBlack,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Room not found',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final roomName = roomData['name'] as String;
        final roomCode = roomData['roomCode'] as String;
        final vibe = roomData['vibe'] as String;
        final hostName = roomData['hostName'] as String? ?? 'Unknown Host';
        final members = (roomData['members'] as List?)?.length ?? 0;
        final memberNames = roomData['memberNames'] as Map<String, dynamic>? ?? {};
        final vibeColor = _getVibeColor(vibe);
        final vibeIcon = _getVibeIcon(vibe);

        return Scaffold(
          backgroundColor: AppColors.deepBlack,
          body: Column(
            children: [
              // Glass App Bar
              _buildGlassAppBar(roomName, roomCode, vibeColor),

              // Tab Bar
              _buildTabBar(vibeColor),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQueueTab(vibeColor),
                    _buildChatTab(),
                    _buildMembersTab(hostName, memberNames, roomData['hostId'], vibeColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassAppBar(String roomName, String roomCode, Color vibeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vibeColor.withValues(alpha: 0.15),
            AppColors.deepBlack.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: vibeColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/home'),
                    ),
                    const SizedBox(width: 8),

                    // Room Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.key,
                                size: 12,
                                color: vibeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Code: $roomCode',
                                style: TextStyle(
                                  color: vibeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _copyRoomCode(roomCode),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: vibeColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Leave Button
                    IconButton(
                      onPressed: _leaveRoom,
                      icon: const Icon(Icons.logout, color: AppColors.warmGlow),
                      tooltip: 'Leave Room',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color vibeColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: vibeColor,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.queue_music), text: 'Queue'),
          Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          Tab(icon: Icon(Icons.people_outline), text: 'Members'),
        ],
      ),
    );
  }

  Widget _buildQueueTab(Color vibeColor) {
    return Container(
      color: AppColors.deepBlack,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.queue_music,
                size: 80,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 24),
              const Text(
                'Queue is empty',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add songs to get the party started!',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      color: AppColors.deepBlack,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 24),
              const Text(
                'No messages yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start a conversation with your room members!',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab(
    String hostName,
    Map<String, dynamic> memberNames,
    String? hostId,
    Color vibeColor,
  ) {
    return Container(
      color: AppColors.deepBlack,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Host
          _buildMemberTile(
            name: hostName,
            isHost: true,
            vibeColor: vibeColor,
          ),

          // Other Members
          ...memberNames.entries
              .where((entry) => entry.key != hostId)
              .map((entry) => _buildMemberTile(
                    name: entry.value.toString(),
                    isHost: false,
                    vibeColor: vibeColor,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildMemberTile({
    required String name,
    required bool isHost,
    required Color vibeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHost
              ? vibeColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isHost
                  ? LinearGradient(
                      colors: [vibeColor, vibeColor.withValues(alpha: 0.6)],
                    )
                  : null,
              color: isHost ? null : AppColors.coolCyan.withValues(alpha: 0.2),
            ),
            child: Icon(
              isHost ? Icons.star : Icons.person,
              color: isHost ? Colors.white : AppColors.coolCyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isHost)
                  Text(
                    'Host',
                    style: TextStyle(
                      color: vibeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Online Indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.spotifyGreen,
              boxShadow: [
                BoxShadow(
                  color: AppColors.spotifyGreen.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}