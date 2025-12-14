// lib/src/widgets/song_search_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/spotify_service.dart';
import '../models/song.dart';
import '../providers/auth_provider.dart';

/// Modal bottom sheet for searching and selecting songs from Spotify
class SongSearchModal extends ConsumerStatefulWidget {
  const SongSearchModal({super.key});

  @override
  ConsumerState<SongSearchModal> createState() => _SongSearchModalState();
}

class _SongSearchModalState extends ConsumerState<SongSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final SpotifyService _spotifyService = SpotifyService();

  List<Song> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize Spotify service
    _spotifyService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);

      // Get user's access token if they have Spotify, otherwise use client credentials
      String? accessToken;
      if (authState.hasSpotify && authState.tokens != null) {
        accessToken = authState.tokens!.accessToken;
      }

      final results = await _spotifyService.search(
        query: query.trim(),
        accessToken: accessToken,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Failed to search: ${e.toString()}';
          _searchResults = [];
        });
      }
    }
  }

  void _selectSong(Song song) {
    // Return the selected song
    Navigator.of(context).pop(song);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepBlack,
            Color(0xFF1a1a2e),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.spotifyGreen, AppColors.coolCyan],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Search Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.music_note, color: AppColors.primaryPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Debounce search - only search after user stops typing for 500ms
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: _performSearch,
            ),
          ),

          const SizedBox(height: 20),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.spotifyGreen,
            ),
            SizedBox(height: 16),
            Text(
              'Searching Spotify...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 80,
                color: AppColors.textDisabled.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Search for songs',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Type to find tracks from Spotify',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for "${_searchController.text}" differently',
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return _buildSongTile(song);
      },
    );
  }

  Widget _buildSongTile(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSong(song),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArt != null
                      ? Image.network(
                          song.albumArt!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderArt();
                          },
                        )
                      : _buildPlaceholderArt(),
                ),
                const SizedBox(width: 12),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.album != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          song.album!,
                          style: TextStyle(
                            color: AppColors.textDisabled.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration and Add Icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (song.durationMs != null)
                      Text(
                        song.formattedDuration,
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.spotifyGreen,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.coolCyan],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}