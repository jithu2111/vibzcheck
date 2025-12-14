// lib/src/widgets/fire_reaction_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Floating action button for sending fire reactions
/// Shows with scale animation and glow effect
class FireReactionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const FireReactionButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<FireReactionButton> createState() => _FireReactionButtonState();
}

class _FireReactionButtonState extends State<FireReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmGlow.withValues(alpha: _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _handleTap,
              backgroundColor: AppColors.warmGlow,
              elevation: 8,
              child: const Text(
                '🔥',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      },
    );
  }
}