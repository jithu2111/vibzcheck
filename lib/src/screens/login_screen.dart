// lib/src/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSpotifyLogin() {
    // TODO: Implement Spotify OAuth
    // For now, navigate to home
    context.go('/home');
  }

  void _handleGuestLogin() {
    // TODO: Implement anonymous Firebase auth
    // For now, navigate to home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepBlack,
              AppColors.primaryPurple.withValues(alpha: 0.15),
              AppColors.warmGlow.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // App Logo/Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Animated icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryPurple,
                              AppColors.warmGlow,
                            ],
                          ),
                          boxShadow: [
                            AppColors.primaryGlow,
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 60,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            AppColors.warmGlow,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'VibzCheck',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'The Digital Aux Cord',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pass the vibe, not the phone',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Buttons Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Connect with Spotify Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _handleSpotifyLogin,
                            icon: const Icon(
                              Icons.music_note,
                              size: 24,
                            ),
                            label: const Text('Connect with Spotify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.spotifyGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.textDisabled,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'OR',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textDisabled,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.textDisabled,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Continue as Guest Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _handleGuestLogin,
                            icon: const Icon(
                              Icons.person_outline,
                              size: 24,
                            ),
                            label: const Text('Continue as Guest'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: AppColors.primaryPurple.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Feature highlights
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.queue_music,
                          text: 'Collaborative queue',
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem(
                          icon: Icons.thumb_up_outlined,
                          text: 'Vote on songs',
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem(
                          icon: Icons.qr_code_scanner,
                          text: 'Join with QR code',
                        ),
                      ],
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

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryPurple,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}