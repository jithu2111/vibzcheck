// lib/src/services/playback_engine.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'firebase_service.dart';
import 'spotify_playback_service.dart';

/// Playback engine for room hosts
/// Monitors queue, triggers playback, and manages track progression
class PlaybackEngine {
  final String roomId;
  final FirebaseService _firebaseService = FirebaseService();
  final SpotifyPlaybackService _playbackService = SpotifyPlaybackService();

  StreamSubscription<DatabaseEvent>? _queueSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  String? _currentSongKey;
  bool _isPlaying = false;

  PlaybackEngine({required this.roomId});

  /// Start the playback engine
  Future<void> start(String spotifyAccessToken) async {
    try {
      print('🎵 [ENGINE] Starting playback engine for room: $roomId');

      // Connect to Spotify SDK (may run in mock mode if not available)
      final connected = await _playbackService.connectToSpotify(spotifyAccessToken);
      if (!connected && !_playbackService.mockMode) {
        throw Exception('Failed to connect to Spotify and not in mock mode');
      }

      if (_playbackService.mockMode) {
        print('⚠️  [ENGINE] Running in MOCK MODE - playback commands will be logged only');
      }

      // Listen to queue changes
      _queueSubscription = _firebaseService.getQueueStream(roomId).listen(
        _onQueueChanged,
        onError: (error) {
          print('❌ [ENGINE] Queue stream error: $error');
        },
      );

      // Listen to player state changes (only if actually connected)
      if (connected) {
        _playerStateSubscription = _playbackService.playerStateStream.listen(
          _onPlayerStateChanged,
          onError: (error) {
            print('❌ [ENGINE] Player state error: $error');
          },
        );
      }

      print('✅ [ENGINE] Playback engine started ${_playbackService.mockMode ? "(MOCK MODE)" : ""}');
    } catch (e) {
      print('❌ [ENGINE] Failed to start playback engine: $e');
      rethrow;
    }
  }

  /// Handle queue changes
  Future<void> _onQueueChanged(DatabaseEvent event) async {
    try {
      final queueData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (queueData == null || queueData.isEmpty) {
        print('📭 [ENGINE] Queue is empty');
        await _stopPlayback();
        return;
      }

      // Parse and sort queue
      final queueItems = <Map<String, dynamic>>[];
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in queueData.entries) {
        final data = entry.value as Map<dynamic, dynamic>;
        final addedAt = data['addedAt'] as int? ?? now;
        final votes = (data['votes'] ?? 0) as int;
        final ageInMinutes = (now - addedAt) / (1000 * 60);
        final score = votes - (ageInMinutes * 0.1);

        queueItems.add({
          'key': entry.key.toString(),
          'songId': data['songId']?.toString() ?? '',
          'title': data['title']?.toString() ?? 'Unknown Track',
          'artist': data['artist']?.toString() ?? 'Unknown Artist',
          'albumArt': data['albumArt']?.toString(),
          'votes': votes,
          'score': score,
        });
      }

      // Sort by score (highest first)
      queueItems.sort((a, b) {
        final scoreComparison = (b['score'] as double).compareTo(a['score'] as double);
        if (scoreComparison != 0) return scoreComparison;
        return (b['votes'] as int).compareTo(a['votes'] as int);
      });

      // Get top song
      final topSong = queueItems.first;
      final topSongKey = topSong['key'] as String;

      // If no song is currently playing or top song changed, play it
      if (_currentSongKey != topSongKey || !_isPlaying) {
        await _playNextSong(topSong);
      }
    } catch (e) {
      print('❌ [ENGINE] Error handling queue change: $e');
    }
  }

  /// Handle player state changes
  void _onPlayerStateChanged(PlayerState playerState) {
    try {
      _isPlaying = !playerState.isPaused;

      // Check if track ended (with null safety)
      final track = playerState.track;
      final position = playerState.playbackPosition;

      if (track != null && position != null) {
        final duration = track.duration;
        if (duration != null && position >= duration - 1000) {
          print('⏭️  [ENGINE] Track ended, moving to next');
          _playNextFromQueue();
        }
      }
    } catch (e) {
      print('❌ [ENGINE] Error handling player state: $e');
    }
  }

  /// Play the next song from queue
  Future<void> _playNextSong(Map<String, dynamic> song) async {
    try {
      final songKey = song['key'] as String;
      final songId = song['songId'] as String;
      final title = song['title'] as String;
      final artist = song['artist'] as String;
      final albumArt = song['albumArt'] as String?;

      print('▶️  [ENGINE] Playing: $title by $artist');

      // Build Spotify URI
      final spotifyUri = 'spotify:track:$songId';

      // Play track
      await _playbackService.playTrack(spotifyUri);

      // Update current track in Firebase
      await _firebaseService.updateCurrentTrack(
        roomId: roomId,
        songKey: songKey,
        songId: songId,
        title: title,
        artist: artist,
        albumArt: albumArt,
      );

      _currentSongKey = songKey;
      _isPlaying = true;

      print('✅ [ENGINE] Now playing: $title');
    } catch (e) {
      print('❌ [ENGINE] Failed to play song: $e');
    }
  }

  /// Play next song from queue (when current ends)
  Future<void> _playNextFromQueue() async {
    try {
      // Remove current song from queue
      if (_currentSongKey != null) {
        await _firebaseService.removeSongFromQueue(roomId, _currentSongKey!);
        print('🗑️  [ENGINE] Removed played song from queue');
      }

      // The queue listener will automatically trigger next song
    } catch (e) {
      print('❌ [ENGINE] Error playing next from queue: $e');
    }
  }

  /// Stop playback
  Future<void> _stopPlayback() async {
    try {
      if (_isPlaying) {
        await _playbackService.pause();
      }

      await _firebaseService.updateCurrentTrack(
        roomId: roomId,
        songKey: null,
        songId: null,
        title: null,
        artist: null,
        albumArt: null,
      );

      _currentSongKey = null;
      _isPlaying = false;

      print('⏹️  [ENGINE] Playback stopped');
    } catch (e) {
      print('❌ [ENGINE] Error stopping playback: $e');
    }
  }

  /// Manually skip to next track
  Future<void> skipToNext() async {
    await _playNextFromQueue();
  }

  /// Pause playback
  Future<void> pause() async {
    await _playbackService.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _playbackService.resume();
  }

  /// Stop the playback engine
  Future<void> stop() async {
    try {
      await _queueSubscription?.cancel();
      await _playerStateSubscription?.cancel();
      await _stopPlayback();
      await _playbackService.disconnect();

      print('🛑 [ENGINE] Playback engine stopped');
    } catch (e) {
      print('❌ [ENGINE] Error stopping engine: $e');
    }
  }
}