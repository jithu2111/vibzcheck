// lib/src/widgets/now_playing_banner.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

/// Now Playing banner widget showing current track
/// Displays different UI for hosts (with controls) vs guests (read-only)
class NowPlayingBanner extends StatelessWidget {
  final String? title;
  final String? artist;
  final String? albumArt;
  final bool isHost;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSkip;
  final Color vibeColor;

  const NowPlayingBanner({
    super.key,
    this.title,
    this.artist,
    this.albumArt,
    required this.isHost,
    required this.isPlaying,
    this.onPlayPause,
    this.onSkip,
    required this.vibeColor,
  });

  @override
  Widget build(BuildContext context) {
    // If no track is playing, show empty state
    if (title == null || artist == null) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vibeColor.withValues(alpha: 0.3),
            vibeColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vibeColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: vibeColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album Art
            _buildAlbumArt(),
            const SizedBox(width: 12),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Now Playing indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: vibeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlaying ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Controls (only for host)
            if (isHost) ...[
              const SizedBox(width: 8),
              _buildHostControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: albumArt != null
          ? CachedNetworkImage(
              imageUrl: albumArt!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholderAlbumArt(),
              errorWidget: (context, url, error) => _buildPlaceholderAlbumArt(),
            )
          : _buildPlaceholderAlbumArt(),
    );
  }

  Widget _buildPlaceholderAlbumArt() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.coolCyan],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildHostControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        IconButton(
          onPressed: onPlayPause,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 40,
          ),
          color: vibeColor,
          tooltip: isPlaying ? 'Pause' : 'Play',
        ),
        // Skip button
        IconButton(
          onPressed: onSkip,
          icon: const Icon(
            Icons.skip_next,
            size: 32,
          ),
          color: vibeColor,
          tooltip: 'Skip',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            color: AppColors.textDisabled,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'No track playing',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}