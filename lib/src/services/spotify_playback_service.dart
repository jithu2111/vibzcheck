// lib/src/services/spotify_playback_service.dart
import 'dart:async';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for controlling Spotify playback using the Spotify SDK
/// Handles play, pause, skip, and playback state monitoring
class SpotifyPlaybackService {
  // Singleton pattern
  static final SpotifyPlaybackService _instance = SpotifyPlaybackService._internal();
  factory SpotifyPlaybackService() => _instance;
  SpotifyPlaybackService._internal();

  // Playback state stream
  StreamSubscription<PlayerState>? _playerStateSubscription;
  final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _mockMode = false;
  bool get mockMode => _mockMode;

  /// Connect to Spotify SDK and authenticate
  /// In development mode (emulator without Spotify app), this will fail gracefully
  Future<bool> connectToSpotify(String accessToken) async {
    try {
      print('🔍 [DEBUG] DotEnv Setup Check:');
      print('   - All Keys: ${dotenv.env.keys.toList()}');
      print('   - Client ID: ${dotenv.env['SPOTIFY_CLIENT_ID']}');
      print('   - Redirect URL: ${dotenv.env['SPOTIFY_REDIRECT_URL']}');
      print('   - Access Token length: ${accessToken.length}');

      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      if (clientId == null) throw Exception("SPOTIFY_CLIENT_ID is null");

      final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'];
      if (redirectUrl == null) throw Exception("SPOTIFY_REDIRECT_URL is null");

      // Connect to Spotify Remote
      final result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
        accessToken: accessToken,
      );

      _isConnected = result;

      if (_isConnected) {
        // Subscribe to player state changes
        _playerStateSubscription = SpotifySdk.subscribePlayerState().listen(
          (playerState) {
            _playerStateController.add(playerState);
          },
          onError: (error) {
            print('❌ [PLAYBACK] Player state error: $error');
          },
        );
        print('✅ [PLAYBACK] Connected to Spotify successfully');
      }

      return _isConnected;
    } on Exception catch (e) {
      // Check if it's a development/testing scenario
      final errorString = e.toString();
      if (errorString.contains('CouldNotFindSpotifyApp') ||
          errorString.contains('UserNotAuthorizedException')) {
        if (errorString.contains('CouldNotFindSpotifyApp')) {
          print('⚠️  [PLAYBACK] Spotify app not installed - running in mock mode');
        } else {
          print('⚠️  [PLAYBACK] Spotify not authorized - running in mock mode');
          print('   Note: User needs to complete Spotify OAuth flow for real playback');
        }
        print('   App will continue with mock playback for development/testing');
        _isConnected = false;
        _mockMode = true;
        return false;
      }

      print('❌ [PLAYBACK] Failed to connect to Spotify: $e');
      _isConnected = false;
      return false;
    } catch (e) {
      print('❌ [PLAYBACK] Failed to connect to Spotify: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Play a track by Spotify URI
  Future<void> playTrack(String spotifyUri) async {
    if (_mockMode) {
      print('🎭 [MOCK PLAYBACK] Would play: $spotifyUri');
      return;
    }

    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.play(spotifyUri: spotifyUri);
      print('▶️  [PLAYBACK] Playing: $spotifyUri');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to play track: $e');
      rethrow;
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_mockMode) {
      print('🎭 [MOCK PLAYBACK] Would resume');
      return;
    }

    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.resume();
      print('▶️  [PLAYBACK] Resumed');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to resume: $e');
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_mockMode) {
      print('🎭 [MOCK PLAYBACK] Would pause');
      return;
    }

    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.pause();
      print('⏸️  [PLAYBACK] Paused');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to pause: $e');
      rethrow;
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    if (_mockMode) {
      print('🎭 [MOCK PLAYBACK] Would skip to next');
      return;
    }

    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.skipNext();
      print('⏭️  [PLAYBACK] Skipped to next');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to skip: $e');
      rethrow;
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (_mockMode) {
      print('🎭 [MOCK PLAYBACK] Would skip to previous');
      return;
    }

    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.skipPrevious();
      print('⏮️  [PLAYBACK] Skipped to previous');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to skip previous: $e');
      rethrow;
    }
  }

  /// Get current playback state
  Future<PlayerState?> getPlayerState() async {
    try {
      if (!_isConnected) {
        return null;
      }

      return await SpotifySdk.getPlayerState();
    } catch (e) {
      print('❌ [PLAYBACK] Failed to get player state: $e');
      return null;
    }
  }

  /// Seek to position in milliseconds
  Future<void> seekTo(int positionMs) async {
    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
      print('⏩ [PLAYBACK] Seeked to ${positionMs}ms');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to seek: $e');
      rethrow;
    }
  }

  /// Queue a track
  Future<void> queueTrack(String spotifyUri) async {
    try {
      if (!_isConnected) {
        throw Exception('Not connected to Spotify');
      }

      await SpotifySdk.queue(spotifyUri: spotifyUri);
      print('➕ [PLAYBACK] Queued: $spotifyUri');
    } catch (e) {
      print('❌ [PLAYBACK] Failed to queue track: $e');
      rethrow;
    }
  }

  /// Disconnect from Spotify
  Future<void> disconnect() async {
    try {
      await _playerStateSubscription?.cancel();
      _playerStateSubscription = null;

      if (_isConnected) {
        await SpotifySdk.disconnect();
        _isConnected = false;
        print('🔌 [PLAYBACK] Disconnected from Spotify');
      }
    } catch (e) {
      print('❌ [PLAYBACK] Error disconnecting: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerStateController.close();
  }
}