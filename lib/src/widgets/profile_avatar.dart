// lib/src/widgets/profile_avatar.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Size presets for the avatar
enum AvatarSize {
  small(40),
  medium(60),
  large(100),
  extraLarge(120);

  const AvatarSize(this.size);
  final double size;

  double get fontSize {
    switch (this) {
      case AvatarSize.small:
        return 16;
      case AvatarSize.medium:
        return 24;
      case AvatarSize.large:
        return 48;
      case AvatarSize.extraLarge:
        return 56;
    }
  }

  double get statusIndicatorSize {
    switch (this) {
      case AvatarSize.small:
        return 10;
      case AvatarSize.medium:
        return 14;
      case AvatarSize.large:
        return 20;
      case AvatarSize.extraLarge:
        return 24;
    }
  }

  double get statusBorderWidth {
    switch (this) {
      case AvatarSize.small:
        return 2;
      case AvatarSize.medium:
        return 2.5;
      case AvatarSize.large:
        return 3;
      case AvatarSize.extraLarge:
        return 3.5;
    }
  }
}

/// Online status for the user
enum OnlineStatus {
  online,
  offline,
  away,
  hidden; // Don't show status indicator

  Color get color {
    switch (this) {
      case OnlineStatus.online:
        return AppColors.spotifyGreen;
      case OnlineStatus.offline:
        return AppColors.textDisabled;
      case OnlineStatus.away:
        return AppColors.warmGlow;
      case OnlineStatus.hidden:
        return Colors.transparent;
    }
  }
}

/// Reusable profile avatar component with online status indicator
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.isGuest = false,
    this.onlineStatus = OnlineStatus.hidden,
    this.size = AvatarSize.medium,
    this.onTap,
    this.showBorder = true,
  });

  /// User's display name (used for initials if no image)
  final String displayName;

  /// Optional profile image URL
  final String? imageUrl;

  /// Whether this is a guest user (affects styling)
  final bool isGuest;

  /// Online status indicator
  final OnlineStatus onlineStatus;

  /// Size of the avatar
  final AvatarSize size;

  /// Optional tap callback
  final VoidCallback? onTap;

  /// Whether to show border around avatar
  final bool showBorder;

  /// Get the first letter of display name for initial
  String get _initial {
    if (displayName.isEmpty) return '?';
    return displayName[0].toUpperCase();
  }

  /// Get gradient colors based on user type
  List<Color> get _gradientColors {
    if (isGuest) {
      return [
        AppColors.coolCyan.withValues(alpha: 0.3),
        AppColors.textSecondary.withValues(alpha: 0.3),
      ];
    } else {
      return [
        AppColors.primaryPurple,
        AppColors.warmGlow,
      ];
    }
  }

  /// Get border color based on user type
  Color get _borderColor {
    if (isGuest) {
      return AppColors.coolCyan.withValues(alpha: 0.5);
    } else {
      return AppColors.primaryPurple.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        // Main avatar
        Container(
          width: size.size,
          height: size.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _gradientColors,
            ),
            border: showBorder
                ? Border.all(
                    color: _borderColor,
                    width: 2,
                  )
                : null,
            boxShadow: !isGuest && showBorder
                ? [AppColors.primaryGlow]
                : null,
          ),
          child: _buildAvatarContent(),
        ),

        // Online status indicator
        if (onlineStatus != OnlineStatus.hidden)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size.statusIndicatorSize,
              height: size.statusIndicatorSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onlineStatus.color,
                border: Border.all(
                  color: AppColors.deepBlack,
                  width: size.statusBorderWidth,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Show profile image
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size.size,
          height: size.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initial if image fails to load
            return _buildInitial();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGuest ? AppColors.coolCyan : AppColors.primaryPurple,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Show initial
      return _buildInitial();
    }
  }

  Widget _buildInitial() {
    return Center(
      child: isGuest
          ? Icon(
              Icons.person_outline,
              size: size.size * 0.5,
              color: AppColors.coolCyan,
            )
          : Text(
              _initial,
              style: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}
