// lib/src/widgets/profile_avatar_demo.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'profile_avatar.dart';

/// Demo screen showcasing all ProfileAvatar variations
class ProfileAvatarDemo extends StatelessWidget {
  const ProfileAvatarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'ProfileAvatar Component',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Sizes',
              children: [
                _buildRow([
                  _buildDemo(
                    'Small',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      size: AvatarSize.small,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                  _buildDemo(
                    'Medium',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      size: AvatarSize.medium,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                  _buildDemo(
                    'Large',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      size: AvatarSize.large,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                  _buildDemo(
                    'XL',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      size: AvatarSize.extraLarge,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Online Status',
              children: [
                _buildRow([
                  _buildDemo(
                    'Online',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                  _buildDemo(
                    'Offline',
                    const ProfileAvatar(
                      displayName: 'Jane Smith',
                      onlineStatus: OnlineStatus.offline,
                    ),
                  ),
                  _buildDemo(
                    'Away',
                    const ProfileAvatar(
                      displayName: 'Bob Wilson',
                      onlineStatus: OnlineStatus.away,
                    ),
                  ),
                  _buildDemo(
                    'Hidden',
                    const ProfileAvatar(
                      displayName: 'Alice Brown',
                      onlineStatus: OnlineStatus.hidden,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'User Types',
              children: [
                _buildRow([
                  _buildDemo(
                    'Spotify',
                    const ProfileAvatar(
                      displayName: 'Spotify User',
                      isGuest: false,
                      onlineStatus: OnlineStatus.online,
                      size: AvatarSize.large,
                    ),
                  ),
                  _buildDemo(
                    'Guest',
                    const ProfileAvatar(
                      displayName: 'Guest User',
                      isGuest: true,
                      onlineStatus: OnlineStatus.online,
                      size: AvatarSize.large,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'With/Without Border',
              children: [
                _buildRow([
                  _buildDemo(
                    'With Border',
                    const ProfileAvatar(
                      displayName: 'John Doe',
                      showBorder: true,
                      size: AvatarSize.large,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                  _buildDemo(
                    'No Border',
                    const ProfileAvatar(
                      displayName: 'Jane Smith',
                      showBorder: false,
                      size: AvatarSize.large,
                      onlineStatus: OnlineStatus.online,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Interactive',
              children: [
                _buildDemo(
                  'Tappable',
                  ProfileAvatar(
                    displayName: 'Tap Me',
                    size: AvatarSize.large,
                    onlineStatus: OnlineStatus.online,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Avatar tapped!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Real World Examples',
              children: [
                _buildExample(
                  title: 'Room Host',
                  child: const Row(
                    children: [
                      ProfileAvatar(
                        displayName: 'DJ Mike',
                        isGuest: false,
                        onlineStatus: OnlineStatus.online,
                        size: AvatarSize.medium,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DJ Mike',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Host • Premium',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildExample(
                  title: 'Room Member (Guest)',
                  child: const Row(
                    children: [
                      ProfileAvatar(
                        displayName: 'Guest',
                        isGuest: true,
                        onlineStatus: OnlineStatus.online,
                        size: AvatarSize.small,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest User',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Member',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildRow(List<Widget> items) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: items,
    );
  }

  Widget _buildDemo(String label, Widget avatar) {
    return Column(
      children: [
        avatar,
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExample({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
