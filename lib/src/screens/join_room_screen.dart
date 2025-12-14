import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

/// Join room screen with numpad input for 4-digit code
class JoinRoomScreen extends ConsumerStatefulWidget {
  final String guestName;

  const JoinRoomScreen({
    super.key,
    required this.guestName,
  });

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _roomCode = '';
  bool _isJoining = false;
  String? _errorMessage;

  void _onNumberTap(String number) {
    if (_roomCode.length < 4) {
      setState(() {
        _roomCode += number;
        _errorMessage = null;
      });

      // Auto-submit when 4 digits entered
      if (_roomCode.length == 4) {
        _joinRoom();
      }
    }
  }

  void _onBackspace() {
    if (_roomCode.isNotEmpty) {
      setState(() {
        _roomCode = _roomCode.substring(0, _roomCode.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _roomCode = '';
      _errorMessage = null;
    });
  }

  Future<void> _joinRoom() async {
    if (_roomCode.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit room code';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      // Find room by code
      final roomId = await _firebaseService.findRoomByCode(_roomCode);

      if (roomId == null) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Room not found. Check the code and try again.';
          _roomCode = '';
        });
        return;
      }

      // Get current user
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Authentication error. Please try again.';
        });
        return;
      }

      // Join the room
      await _firebaseService.joinRoom(roomId, currentUser.uid, widget.guestName);

      // Navigate to room screen
      if (mounted) {
        context.go('/room/$roomId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Failed to join room: ${e.toString()}';
          _roomCode = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${widget.guestName}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Enter the 4-digit room code',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Room Code Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Code Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AppColors.primaryGlow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final hasDigit = index < _roomCode.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 45,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: hasDigit ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: hasDigit ? 0.4 : 0.2),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                hasDigit ? _roomCode[index] : '',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warmGlow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warmGlow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.warmGlow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.warmGlow,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Loading Indicator
                  if (_isJoining)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.spotifyGreen),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Joining room...',
                            style: TextStyle(
                              color: AppColors.spotifyGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Numpad
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Numbers 1-3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Numbers 4-6
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Numbers 7-9
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Clear, 0, Backspace
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.clear,
                        onTap: _onClear,
                        label: 'Clear',
                      ),
                      _buildNumberButton('0'),
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                        label: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: _isJoining ? null : () => _onNumberTap(number),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.3),
              AppColors.coolCyan.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: _isJoining ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}