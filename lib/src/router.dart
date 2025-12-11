// lib/src/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_colors.dart';
import 'widgets/profile_avatar.dart';

// Placeholder home screen for now
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Safely get Spotify profile image URL
  String? _getProfileImageUrl(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final images = profile['images'];
    if (images == null || images is! List || images.isEmpty) return null;
    return images[0]?['url'] as String?;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'VibzCheck',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Profile Info
              if (authState.hasSpotify && authState.userProfile != null) ...[
                ProfileAvatar(
                  displayName: authState.userProfile!['display_name'] ?? 'User',
                  imageUrl: _getProfileImageUrl(authState.userProfile),
                  isGuest: false,
                  onlineStatus: OnlineStatus.online,
                  size: AvatarSize.large,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome, ${authState.userProfile!['display_name'] ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.userProfile!['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.spotifyGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Spotify Connected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'OAuth 2.0 authentication successful!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (authState.isGuest) ...[
                // Guest avatar
                ProfileAvatar(
                  displayName: authState.userProfile?['display_name'] ?? 'Guest',
                  isGuest: true,
                  onlineStatus: OnlineStatus.online,
                  size: AvatarSize.large,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome, ${authState.userProfile?['display_name'] ?? 'Guest'}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guest Mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.coolCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.coolCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.coolCyan,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Limited Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can join rooms and vote, but you need Spotify Premium to host.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              const Text(
                "Home / Lobby",
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Coming soon!",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);