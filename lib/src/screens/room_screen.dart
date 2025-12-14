import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/firebase_service.dart';
import '../services/spotify_service.dart';
import '../services/playback_engine.dart';
import '../providers/auth_provider.dart';
import '../models/song.dart';
import '../widgets/song_search_modal.dart';
import '../widgets/now_playing_banner.dart';
import '../widgets/reaction_animation_overlay.dart';
import '../widgets/fire_reaction_button.dart';
import 'room_screen_chat_tab.dart';
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
  final List<String> _activeReactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenToReactions();
  }

  void _listenToReactions() {
    _firebaseService.getReactionsStream(widget.roomId).listen((event) {
      if (!mounted) return;

      final reactionsData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (reactionsData == null) return;

      // Trigger animation for each reaction
      for (final entry in reactionsData.entries) {
        final reactionId = entry.key.toString();
        if (!_activeReactions.contains(reactionId)) {
          _onReactionReceived(reactionId);
          print('🔥 [REACTION] Received reaction: $reactionId');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendReaction() async {
    try {
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) return;

      await _firebaseService.sendReaction(
        roomId: widget.roomId,
        userId: currentUser.uid,
        reactionType: '🔥',
      );
    } catch (e) {
      print('❌ [REACTION] Failed to send reaction: $e');
    }
  }

  void _onReactionReceived(String reactionId) {
    setState(() {
      _activeReactions.add(reactionId);
    });
  }

  void _onReactionComplete(String reactionId) {
    setState(() {
      _activeReactions.remove(reactionId);
    });
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
        final hostId = roomData['hostId'] as String?;
        final members = (roomData['members'] as List?)?.cast<String>() ?? [];
        final memberNames = roomData['memberNames'] as Map<String, dynamic>? ?? {};
        final vibeColor = _getVibeColor(vibe);
        final vibeIcon = _getVibeIcon(vibe);
        final currentUserId = _firebaseService.auth.currentUser?.uid ?? '';

        return Stack(
          children: [
            // Main Scaffold
            Scaffold(
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
                        _QueueTab(roomId: widget.roomId, vibeColor: vibeColor),
                        _buildChatTab(
                          currentUserId: currentUserId,
                          hostId: hostId ?? '',
                          memberNames: memberNames,
                        ),
                        _buildMembersTab(hostName, memberNames, members, hostId, vibeColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Reaction Animations
            ..._buildReactionOverlays(),
          ],
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
    return Column(
      children: [
        // Add Song Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showSongSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spotifyGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Song to Queue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Queue List
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _firebaseService.getQueueStream(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading queue: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
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
                          'Tap the button above to add songs!',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Parse queue data safely
              // ignore: avoid_print
              print('🔍 [QUEUE] Raw snapshot value type: ${snapshot.data!.snapshot.value.runtimeType}');
              // ignore: avoid_print
              print('🔍 [QUEUE] Raw snapshot value: ${snapshot.data!.snapshot.value}');

              final queueData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              // Create a safe copy of the data to avoid concurrent modification
              final queueItems = <Map<String, dynamic>>[];

              try {
                // ignore: avoid_print
                print('🔍 [QUEUE] Processing ${queueData.length} items');

                for (final entry in queueData.entries) {
                  final data = entry.value as Map<dynamic, dynamic>;

                  // ignore: avoid_print
                  print('🔍 [QUEUE] Item: ${entry.key} -> $data');

                  queueItems.add({
                    'key': entry.key.toString(),
                    'title': data['title']?.toString() ?? 'Unknown Track',
                    'artist': data['artist']?.toString() ?? 'Unknown Artist',
                    'albumArt': data['albumArt']?.toString(),
                    'addedBy': data['addedBy']?.toString() ?? '',
                    'votes': (data['votes'] ?? 0) as int,
                  });
                }

                // Sort by votes (highest first)
                queueItems.sort((a, b) => (b['votes'] as int).compareTo(a['votes'] as int));

                // ignore: avoid_print
                print('✅ [QUEUE] Successfully parsed ${queueItems.length} items');
              } catch (e) {
                // ignore: avoid_print
                print('❌ [QUEUE] Error parsing queue data: $e');
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: queueItems.length,
                itemBuilder: (context, index) {
                  final item = queueItems[index];
                  return _buildQueueItem(item, vibeColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> item, Color vibeColor) {
    final votes = item['votes'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vibeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Album Art
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item['albumArt'] != null
                ? Image.network(
                    item['albumArt'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderAlbumArt();
                    },
                  )
                : _buildPlaceholderAlbumArt(),
          ),
          const SizedBox(width: 12),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['artist'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Voting
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                color: votes > 0 ? AppColors.spotifyGreen : AppColors.textSecondary,
                onPressed: () => _voteOnSong(item['key'], 1),
              ),
              Text(
                votes.toString(),
                style: TextStyle(
                  color: votes > 0 ? AppColors.spotifyGreen : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                color: votes < 0 ? AppColors.warmGlow : AppColors.textSecondary,
                onPressed: () => _voteOnSong(item['key'], -1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAlbumArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.coolCyan],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Future<void> _showSongSearch() async {
    final song = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SongSearchModal(),
    );

    if (song != null) {
      await _addSongToQueue(song);
    }
  }

  Future<void> _addSongToQueue(Song song) async {
    try {
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      // Get room data to check if user is host
      final roomDoc = await _firebaseService.roomsCollection.doc(widget.roomId).get();
      final roomData = roomDoc.data() as Map<String, dynamic>?;
      final hostId = roomData?['hostId'] as String?;
      final isHost = currentUser.uid == hostId;

      await _firebaseService.addSongToQueue(
        roomId: widget.roomId,
        songId: song.id,
        title: song.name,
        artist: song.artist,
        albumArt: song.albumArt ?? '',
        addedBy: currentUser.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHost
              ? '✅ Added "${song.name}" to queue'
              : '📨 Request sent: "${song.name}"'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add song: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _voteOnSong(String songKey, int voteChange) async {
    try {
      await _firebaseService.voteOnSong(
        roomId: widget.roomId,
        songKey: songKey,
        voteChange: voteChange,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildChatTab({
    required String currentUserId,
    required String hostId,
    required Map<String, dynamic> memberNames,
  }) {
    return ChatTab(
      roomId: widget.roomId,
      currentUserId: currentUserId,
      hostId: hostId,
      memberNames: memberNames,
      onReaction: _sendReaction,
    );
  }

  List<Widget> _buildReactionOverlays() {
    return _activeReactions.map((reactionId) {
      return ReactionAnimationOverlay(
        key: ValueKey(reactionId),
        onComplete: () => _onReactionComplete(reactionId),
      );
    }).toList();
  }

  Widget _buildMembersTab(
    String hostName,
    Map<String, dynamic> memberNames,
    List<String> currentMembers,
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

          // Other Members - only show members who are currently in the room
          ...memberNames.entries
              .where((entry) =>
                entry.key != hostId && currentMembers.contains(entry.key))
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

/// Separate widget for Queue tab to maintain state when switching tabs
class _QueueTab extends ConsumerStatefulWidget {
  final String roomId;
  final Color vibeColor;

  const _QueueTab({
    required this.roomId,
    required this.vibeColor,
  });

  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> with AutomaticKeepAliveClientMixin {
  final FirebaseService _firebaseService = FirebaseService();
  PlaybackEngine? _playbackEngine;
  bool _isHost = false;
  bool _isPlaying = false;

  // Track user's votes for optimistic UI updates
  // Map<songKey, voteValue> where voteValue is: 1 (upvoted), -1 (downvoted), 0 (no vote)
  final Map<String, int> _userVotes = {};

  // Track optimistic vote counts (applied before Firebase confirms)
  final Map<String, int> _optimisticVotes = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkIfHostAndStartEngine();
  }

  @override
  void dispose() {
    _playbackEngine?.stop();
    super.dispose();
  }

  Future<void> _checkIfHostAndStartEngine() async {
    final currentUser = _firebaseService.auth.currentUser;
    if (currentUser == null) return;

    final roomDoc = await _firebaseService.roomsCollection.doc(widget.roomId).get();
    final roomData = roomDoc.data() as Map<String, dynamic>?;
    final hostId = roomData?['hostId'] as String?;

    setState(() {
      _isHost = currentUser.uid == hostId;
    });

    // If user is host and has Spotify auth, start playback engine
    if (_isHost) {
      _startPlaybackEngine();
    }
  }

  Future<void> _startPlaybackEngine() async {
    try {
      // Get Spotify access token from auth provider
      final authState = ref.read(authProvider);

      // Check if user has Spotify auth
      if (authState.tokens == null) {
        print('⚠️  [PLAYBACK] Host doesn\'t have Spotify authentication');
        return;
      }

      final authNotifier = ref.read(authProvider.notifier);
      final accessToken = await authNotifier.getValidAccessToken();

      _playbackEngine = PlaybackEngine(roomId: widget.roomId);
      await _playbackEngine!.start(accessToken);

      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }

      print('✅ [PLAYBACK] Playback engine started for host');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to start playback engine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start playback: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _onPlayPause() async {
    if (_playbackEngine == null) return;

    try {
      if (_isPlaying) {
        await _playbackEngine!.pause();
      } else {
        await _playbackEngine!.resume();
      }

      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      print('❌ [PLAYBACK] Play/Pause error: $e');
    }
  }

  Future<void> _onSkip() async {
    if (_playbackEngine == null) return;

    try {
      await _playbackEngine!.skipToNext();
    } catch (e) {
      print('❌ [PLAYBACK] Skip error: $e');
    }
  }

  Future<void> _showSongSearch() async {
    final song = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SongSearchModal(),
    );

    if (song != null) {
      await _addSongToQueue(song);
    }
  }

  Future<void> _addSongToQueue(Song song) async {
    try {
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      // Get room data to check if user is host
      final roomDoc = await _firebaseService.roomsCollection.doc(widget.roomId).get();
      final roomData = roomDoc.data() as Map<String, dynamic>?;
      final hostId = roomData?['hostId'] as String?;
      final isHost = currentUser.uid == hostId;

      await _firebaseService.addSongToQueue(
        roomId: widget.roomId,
        songId: song.id,
        title: song.name,
        artist: song.artist,
        albumArt: song.albumArt ?? '',
        addedBy: currentUser.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHost
              ? '✅ Added "${song.name}" to queue'
              : '📨 Request sent: "${song.name}"'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add song: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _voteOnSong(String songKey, int voteChange) async {
    // Get current user's vote on this song (0 if no vote)
    final currentVote = _userVotes[songKey] ?? 0;
    final newVote = currentVote == voteChange ? 0 : voteChange; // Toggle vote
    final actualVoteChange = newVote - currentVote;

    // Apply optimistic update immediately
    setState(() {
      _userVotes[songKey] = newVote;
      _optimisticVotes[songKey] = (_optimisticVotes[songKey] ?? 0) + actualVoteChange;
    });

    try {
      // Sync with Firebase in background
      await _firebaseService.voteOnSong(
        roomId: widget.roomId,
        songKey: songKey,
        voteChange: actualVoteChange,
      );

      // Clear optimistic state once Firebase confirms
      if (mounted) {
        setState(() {
          _optimisticVotes.remove(songKey);
        });
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _userVotes[songKey] = currentVote;
          _optimisticVotes.remove(songKey);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  Widget _buildPlaceholderAlbumArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.coolCyan],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> item) {
    final songKey = item['key'] as String;
    final firebaseVotes = item['votes'] as int;

    // Apply optimistic updates to vote count
    final optimisticVoteChange = _optimisticVotes[songKey] ?? 0;
    final displayVotes = firebaseVotes + optimisticVoteChange;

    // Get user's current vote state
    final userVote = _userVotes[songKey] ?? 0;
    final hasUpvoted = userVote == 1;
    final hasDownvoted = userVote == -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.vibeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Album Art
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item['albumArt'] != null
                ? Image.network(
                    item['albumArt'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderAlbumArt();
                    },
                  )
                : _buildPlaceholderAlbumArt(),
          ),
          const SizedBox(width: 12),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['artist'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Voting
          Column(
            children: [
              IconButton(
                icon: Icon(
                  hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                  size: 20,
                ),
                color: hasUpvoted ? AppColors.spotifyGreen : AppColors.textSecondary,
                onPressed: () => _voteOnSong(songKey, 1),
              ),
              Text(
                displayVotes.toString(),
                style: TextStyle(
                  color: displayVotes > 0
                      ? AppColors.spotifyGreen
                      : displayVotes < 0
                        ? AppColors.warmGlow
                        : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(
                  hasDownvoted ? Icons.arrow_downward : Icons.arrow_downward_outlined,
                  size: 20,
                ),
                color: hasDownvoted ? AppColors.warmGlow : AppColors.textSecondary,
                onPressed: () => _voteOnSong(songKey, -1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Now Playing Banner
        StreamBuilder<DocumentSnapshot>(
          stream: _firebaseService.getRoomStream(widget.roomId),
          builder: (context, snapshot) {
            final roomData = snapshot.data?.data() as Map<String, dynamic>?;
            final currentTrack = roomData?['currentTrack'] as Map<String, dynamic>?;

            return NowPlayingBanner(
              title: currentTrack?['title'] as String?,
              artist: currentTrack?['artist'] as String?,
              albumArt: currentTrack?['albumArt'] as String?,
              isHost: _isHost,
              isPlaying: _isPlaying,
              onPlayPause: _isHost ? _onPlayPause : null,
              onSkip: _isHost ? _onSkip : null,
              vibeColor: widget.vibeColor,
            );
          },
        ),
        // Add Song Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showSongSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spotifyGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Song to Queue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Queue List
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _firebaseService.getQueueStream(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading queue: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
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
                          'Tap the button above to add songs!',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Parse queue data safely
              final queueData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final queueItems = <Map<String, dynamic>>[];

              try {
                final now = DateTime.now().millisecondsSinceEpoch;

                for (final entry in queueData.entries) {
                  final data = entry.value as Map<dynamic, dynamic>;
                  final addedAt = data['addedAt'] as int? ?? now;
                  final votes = (data['votes'] ?? 0) as int;

                  // Calculate age in minutes
                  final ageInMinutes = (now - addedAt) / (1000 * 60);

                  // Calculate score: votes - (age * decay factor)
                  // Decay factor of 0.1 means each minute reduces score by 0.1
                  final score = votes - (ageInMinutes * 0.1);

                  queueItems.add({
                    'key': entry.key.toString(),
                    'title': data['title']?.toString() ?? 'Unknown Track',
                    'artist': data['artist']?.toString() ?? 'Unknown Artist',
                    'albumArt': data['albumArt']?.toString(),
                    'addedBy': data['addedBy']?.toString() ?? '',
                    'votes': votes,
                    'addedAt': addedAt,
                    'score': score,
                  });
                }

                // Sort by score (highest first), then by votes if score is equal
                queueItems.sort((a, b) {
                  final scoreComparison = (b['score'] as double).compareTo(a['score'] as double);
                  if (scoreComparison != 0) return scoreComparison;
                  return (b['votes'] as int).compareTo(a['votes'] as int);
                });
              } catch (e) {
                // ignore: avoid_print
                print('❌ [QUEUE] Error parsing queue data: $e');
              }

              // Use AnimatedSwitcher for smooth transitions when list changes
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey(queueItems.map((e) => '${e['key']}_${e['votes']}').join('_')),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: queueItems.length,
                  itemBuilder: (context, index) {
                    final item = queueItems[index];
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildQueueItem(item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}