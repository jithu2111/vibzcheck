import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/create_room_modal.dart';
import '../services/firebase_service.dart';

/// Home/Lobby screen - Main hub for creating and joining rooms
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'all'; // all, chill, party, hype, study

  /// Safely get profile image URL from Spotify profile
  String? _getProfileImageUrl(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final images = profile['images'];
    if (images == null || images is! List || images.isEmpty) return null;
    return images[0]?['url'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.deepBlack,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.3),
                      AppColors.deepBlack,
                    ],
                  ),
                ),
              ),
              title: Row(
                children: [
                  // Profile Avatar
                  ProfileAvatar(
                    imageUrl: _getProfileImageUrl(authState.userProfile),
                    displayName: authState.userProfile?['display_name'] ?? 'Guest',
                    isGuest: authState.isGuest,
                    size: AvatarSize.small,
                    onlineStatus: OnlineStatus.online,
                  ),
                  const SizedBox(width: 12),
                  // User Info
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.userProfile?['display_name'] ?? 'Guest User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authState.isGuest ? 'Guest Mode' : 'Spotify Connected',
                          style: TextStyle(
                            color: authState.isGuest
                                ? AppColors.coolCyan
                                : AppColors.spotifyGreen,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Join by Code Button
              IconButton(
                icon: const Icon(Icons.numbers, color: Colors.white),
                tooltip: 'Join by Code',
                onPressed: () => _showJoinByCodeDialog(context),
              ),
              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Rooms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Vibes', Icons.grid_view),
                        const SizedBox(width: 8),
                        _buildFilterChip('chill', 'Chill', Icons.nightlight_round),
                        const SizedBox(width: 8),
                        _buildFilterChip('party', 'Party', Icons.celebration),
                        const SizedBox(width: 8),
                        _buildFilterChip('hype', 'Hype', Icons.bolt),
                        const SizedBox(width: 8),
                        _buildFilterChip('study', 'Study', Icons.menu_book_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rooms List
          StreamBuilder<QuerySnapshot>(
            stream: firebaseService.roomsCollection
                .where('isActive', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading rooms: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                );
              }

              final rooms = snapshot.data?.docs ?? [];

              // Filter rooms by vibe
              final filteredRooms = _selectedFilter == 'all'
                  ? rooms
                  : rooms.where((room) {
                      final data = room.data() as Map<String, dynamic>;
                      return data['vibe'] == _selectedFilter;
                    }).toList();

              if (filteredRooms.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_off,
                            size: 64,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'all'
                                ? 'No active rooms yet'
                                : 'No ${_selectedFilter} rooms found',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first to create one!',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final room = filteredRooms[index];
                      final roomData = room.data() as Map<String, dynamic>;
                      return _buildRoomCard(context, room.id, roomData, authState);
                    },
                    childCount: filteredRooms.length,
                  ),
                ),
              );
            },
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Floating Action Button - Create Room
      floatingActionButton: authState.hasSpotify
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateRoomModal(context),
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Room',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connect Spotify to host a room'),
                    backgroundColor: AppColors.warmGlow,
                  ),
                );
              },
              backgroundColor: AppColors.textDisabled,
              icon: const Icon(Icons.lock, color: Colors.white),
              label: const Text(
                'Spotify Required',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    Color chipColor;

    switch (filter) {
      case 'chill':
        chipColor = AppColors.coolCyan;
        break;
      case 'party':
        chipColor = AppColors.warmGlow;
        break;
      case 'hype':
        chipColor = AppColors.spotifyGreen;
        break;
      case 'study':
        chipColor = AppColors.primaryPurple;
        break;
      default:
        chipColor = AppColors.primaryPurple;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [chipColor, chipColor.withValues(alpha: 0.7)])
              : null,
          color: isSelected ? null : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : chipColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : chipColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    String roomId,
    Map<String, dynamic> roomData,
    AuthState authState,
  ) {
    final vibe = roomData['vibe'] as String;
    final roomName = roomData['name'] as String;
    final members = (roomData['members'] as List?)?.length ?? 0;
    final hasPassword = roomData['password'] != null;
    final currentTrack = roomData['currentTrack'] as Map<String, dynamic>?;

    // Vibe color
    Color vibeColor;
    IconData vibeIcon;
    switch (vibe) {
      case 'chill':
        vibeColor = AppColors.coolCyan;
        vibeIcon = Icons.nightlight_round;
        break;
      case 'party':
        vibeColor = AppColors.warmGlow;
        vibeIcon = Icons.celebration;
        break;
      case 'hype':
        vibeColor = AppColors.spotifyGreen;
        vibeIcon = Icons.bolt;
        break;
      case 'study':
        vibeColor = AppColors.primaryPurple;
        vibeIcon = Icons.menu_book_rounded;
        break;
      default:
        vibeColor = AppColors.primaryPurple;
        vibeIcon = Icons.music_note;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            AppColors.deepBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vibeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _joinRoom(context, roomId, roomData, authState),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Vibe Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [vibeColor, vibeColor.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: vibeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(vibeIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Room Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$members ${members == 1 ? 'person' : 'people'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasPassword) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.lock,
                                  color: AppColors.textSecondary,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Join Button
                    Icon(
                      Icons.arrow_forward_ios,
                      color: vibeColor,
                      size: 20,
                    ),
                  ],
                ),

                // Current Track (if playing)
                if (currentTrack != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: AppColors.spotifyGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTrack['title'] ?? 'Unknown Track',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentTrack['artist'] ?? 'Unknown Artist',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.spotifyGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: AppColors.spotifyGreen,
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'NOW',
                                style: TextStyle(
                                  color: AppColors.spotifyGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateRoomModal(BuildContext context) async {
    final roomId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateRoomModal(),
    );

    if (roomId != null && mounted) {
      // Navigate to the created room
      context.push('/room/$roomId');
    }
  }

  Future<void> _joinRoom(
    BuildContext context,
    String roomId,
    Map<String, dynamic> roomData,
    AuthState authState,
  ) async {
    try {
      // Join room
      final firebaseService = FirebaseService();
      final currentUser = firebaseService.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Get display name
      final displayName = authState.userProfile?['display_name'] ??
                         (authState.isGuest ? 'Guest User' : 'User');

      await firebaseService.joinRoom(roomId, currentUser.uid, displayName);

      if (mounted) {
        // Navigate to room screen
        context.push('/room/$roomId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showJoinByCodeDialog(BuildContext context) async {
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: const Text(
          'Join Room',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 4-digit room code',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                hintText: '0000',
                hintStyle: TextStyle(color: AppColors.textDisabled.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Join',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (code == null || code.trim().isEmpty) return;

    // Validate code format
    if (code.trim().length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room code must be 4 digits'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final firebaseService = FirebaseService();
      final roomId = await firebaseService.findRoomByCode(code.trim());

      if (roomId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room not found. Please check the code.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Join the room
      final currentUser = firebaseService.auth.currentUser;
      final authState = ref.read(authProvider);

      if (currentUser != null) {
        // Get display name
        final displayName = authState.userProfile?['display_name'] ??
                           (authState.isGuest ? 'Guest User' : 'User');

        await firebaseService.joinRoom(roomId, currentUser.uid, displayName);

        if (mounted) {
          // Navigate to room screen
          context.push('/room/$roomId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}