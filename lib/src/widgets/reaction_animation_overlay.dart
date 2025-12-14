// lib/src/widgets/reaction_animation_overlay.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Overlay widget that shows fire emoji flying from bottom to top
/// Auto-removes after animation completes
class ReactionAnimationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const ReactionAnimationOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<ReactionAnimationOverlay> createState() =>
      _ReactionAnimationOverlayState();
}

class _ReactionAnimationOverlayState extends State<ReactionAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  final math.Random _random = math.Random();
  late double _horizontalOffset;

  @override
  void initState() {
    super.initState();

    // Random horizontal offset for variety
    _horizontalOffset = (_random.nextDouble() - 0.5) * 100;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Position: bottom to top
    _positionAnimation = Tween<double>(
      begin: 1.0,
      end: -0.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Opacity: fade in, stay, fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    // Slight rotation for natural feel
    _rotationAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Scale: start big, get smaller
    _scaleAnimation = Tween<double>(
      begin: 1.5,
      end: 0.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: (screenSize.width / 2) - 40 + _horizontalOffset,
          top: screenSize.height * _positionAnimation.value,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🔥',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}