// lib/src/theme/app_colors.dart
import 'package:flutter/material.dart';

/// VibzCheck Color Palette
/// Theme: Chill hangout with club energy - intimate, inviting, vibey
class AppColors {
  AppColors._();

  // --- Background & Surfaces ---
  // Club dark - easier on eyes than pure black
  static const Color deepBlack = Color(0xFF0D0D0D);

  // Subtle elevation for cards
  static const Color cardSurface = Color(0xFF1A1A1A);

  // Elevated surfaces (modals, player)
  static const Color elevatedSurface = Color(0xFF242424);

  // --- Brand Colors ---
  // Keep Spotify green for authenticity
  static const Color spotifyGreen = Color(0xFF1DB954);

  // Primary purple - club mood lighting
  static const Color primaryPurple = Color(0xFF9D4EDD);

  // --- Accent Colors ---
  // Warm glow - inviting, not aggressive
  static const Color warmGlow = Color(0xFFFF6B9D);

  // Cool accent - fresh, breathable
  static const Color coolCyan = Color(0xFF4CC9F0);

  // --- Functional Colors ---
  // Voting - friendly, not confrontational
  static const Color upvote = Color(0xFF10B981); // "this fits the vibe"
  static const Color downvote = Color(0xFFF59E0B); // "maybe next time"

  // Success/Error/Warning
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // --- Vibe Tags ---
  static const Color vibeParty = Color(0xFFFF6B9D);    // Warm pink
  static const Color vibeChill = Color(0xFF4CC9F0);    // Cool cyan
  static const Color vibeWorkout = Color(0xFFF59E0B);  // Energetic amber
  static const Color vibeStudy = Color(0xFF7C3AED);    // Focused purple

  // --- Text Hierarchy ---
  static const Color textPrimary = Color(0xFFFFFFFF);   // Bright white
  static const Color textSecondary = Color(0xFFA8A8A8); // Soft gray
  static const Color textDisabled = Color(0xFF4A4A4A);  // Subtle

  // --- Gradients ---
  // Main brand gradient (purple to pink)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, warmGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Club lights gradient (purple to cyan)
  static const LinearGradient clubGradient = LinearGradient(
    colors: [primaryPurple, coolCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sunset gradient (pink to amber)
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [warmGlow, downvote],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glassmorphism Utils ---
  // Frosted glass effect
  static Color glassWhite = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);

  // Glow effects for buttons/cards
  static BoxShadow primaryGlow = BoxShadow(
    color: primaryPurple.withValues(alpha: 0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  static BoxShadow warmGlowShadow = BoxShadow(
    color: warmGlow.withValues(alpha: 0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );
}
