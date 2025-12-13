import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

/// Modal for creating a new room with vibe selection
class CreateRoomModal extends ConsumerStatefulWidget {
  const CreateRoomModal({super.key});

  @override
  ConsumerState<CreateRoomModal> createState() => _CreateRoomModalState();
}

class _CreateRoomModalState extends ConsumerState<CreateRoomModal> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();

  String _selectedVibe = 'chill';
  bool _isCreating = false;
  String? _createdRoomCode;
  String? _createdRoomId;

  // Vibe configurations with icons, colors, and descriptions
  final Map<String, Map<String, dynamic>> _vibes = {
    'chill': {
      'icon': Icons.nightlight_round,
      'label': 'Chill',
      'color': AppColors.coolCyan,
      'gradient': [AppColors.coolCyan, AppColors.primaryPurple],
      'description': 'Relaxed vibes, laid-back tunes',
    },
    'party': {
      'icon': Icons.celebration,
      'label': 'Party',
      'color': AppColors.warmGlow,
      'gradient': [AppColors.warmGlow, AppColors.spotifyGreen],
      'description': 'High energy, dance floor bangers',
    },
    'hype': {
      'icon': Icons.bolt,
      'label': 'Hype',
      'color': AppColors.spotifyGreen,
      'gradient': [AppColors.spotifyGreen, AppColors.primaryPurple],
      'description': 'Intense beats, pump-up anthems',
    },
    'study': {
      'icon': Icons.menu_book_rounded,
      'label': 'Study',
      'color': AppColors.primaryPurple,
      'gradient': [AppColors.primaryPurple, AppColors.coolCyan],
      'description': 'Focus music, concentration zone',
    },
  };

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is authenticated
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      _showError('You must be logged in to create a room');
      return;
    }

    // Check if user has Spotify (required for hosting)
    if (!authState.hasSpotify) {
      _showError('You need a Spotify account to host a room');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Get Firebase service and current user
      final firebaseService = FirebaseService();
      final currentUser = firebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final result = await firebaseService.createRoom(
        roomName: _roomNameController.text.trim(),
        hostId: currentUser.uid,
        vibe: _selectedVibe,
      );

      if (mounted) {
        setState(() {
          _createdRoomCode = result['roomCode'];
          _createdRoomId = result['roomId'];
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        _showError('Failed to create room: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warmGlow,
      ),
    );
  }

  void _copyRoomCode() {
    if (_createdRoomCode != null) {
      Clipboard.setData(ClipboardData(text: _createdRoomCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room code copied to clipboard!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If room is created, show success screen with room code
    if (_createdRoomCode != null) {
      return _buildSuccessScreen();
    }

    // Otherwise show create room form
    return _buildCreateForm();
  }

  Widget _buildSuccessScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepBlack,
            AppColors.primaryPurple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.spotifyGreen, AppColors.coolCyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spotifyGreen.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),

            // Success Title
            const Text(
              'Room Created!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Share this code with your friends',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Room Code Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppColors.primaryGlow],
              ),
              child: Column(
                children: [
                  const Text(
                    'ROOM CODE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _createdRoomCode!,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 16,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Copy Button
            OutlinedButton.icon(
              onPressed: _copyRoomCode,
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('Copy Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primaryPurple, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enter Room Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_createdRoomId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enter Room',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepBlack,
            AppColors.primaryPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.warmGlow],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Create Room',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Room Name Input
                TextFormField(
                  controller: _roomNameController,
                  enabled: !_isCreating,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., Friday Night Vibes',
                    hintStyle: const TextStyle(color: AppColors.textDisabled),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warmGlow),
                    ),
                    prefixIcon: const Icon(Icons.music_note, color: AppColors.primaryPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    if (value.trim().length < 3) {
                      return 'Room name must be at least 3 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Room name must be less than 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Vibe Selection
                const Text(
                  'Choose Your Vibe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _vibes.entries.map((entry) {
                    final vibeKey = entry.key;
                    final vibe = entry.value;
                    final isSelected = _selectedVibe == vibeKey;

                    return GestureDetector(
                      onTap: _isCreating
                          ? null
                          : () {
                              setState(() {
                                _selectedVibe = vibeKey;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: vibe['gradient'])
                              : null,
                          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.primaryPurple.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (vibe['color'] as Color).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vibe['icon'],
                              color: isSelected ? Colors.white : vibe['color'],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              vibe['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Vibe description
                Text(
                  _vibes[_selectedVibe]!['description'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Create Button
                ElevatedButton(
                  onPressed: _isCreating ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.textDisabled,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.primaryPurple.withValues(alpha: 0.8);
                      }
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.textDisabled;
                      }
                      return AppColors.primaryPurple;
                    }),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}