# Playback Features Implementation Guide

## ✅ Completed Components

### 1. **Spotify SDK Package** (`pubspec.yaml`)
- Added `spotify_sdk: ^2.3.0` to dependencies
- Enables remote control of Spotify playback

### 2. **SpotifyPlaybackService** (`lib/src/services/spotify_playback_service.dart`)
- Singleton service for Spotify SDK integration
- Methods:
  - `connectToSpotify(accessToken)` - Connect to Spotify Remote
  - `playTrack(spotifyUri)` - Play a track
  - `pause()` / `resume()` - Control playback
  - `skipNext()` - Skip to next track
  - `getPlayerState()` - Get current playback state
  - Stream: `playerStateStream` - Real-time playback updates

### 3. **PlaybackEngine** (`lib/src/services/playback_engine.dart`)
- Autonomous playback controller for room hosts
- Features:
  - Monitors queue changes in real-time
  - Automatically plays top-voted song
  - Removes completed songs from queue
  - Handles track transitions
  - Applies time-decay scoring algorithm
- Methods:
  - `start(accessToken)` - Initialize engine
  - `skipToNext()` - Manually skip track
  - `pause()` / `resume()` - Control playback
  - `stop()` - Shutdown engine

### 4. **Firebase Service Updates** (`lib/src/services/firebase_service.dart`)
- New methods:
  - `updateCurrentTrack()` - Update `currentTrack` field in Firestore
  - `getCurrentTrack()` - Get currently playing track

### 5. **NowPlayingBanner Widget** (`lib/src/widgets/now_playing_banner.dart`)
- Beautiful UI component showing current track
- Two modes:
  - **Host Mode**: With play/pause and skip controls
  - **Guest Mode**: Read-only display (no controls)
- Features:
  - Album art display
  - Song title and artist
  - "NOW PLAYING" indicator
  - Playback controls (host only)

## 🔧 Integration Instructions

### Step 1: Update Room Screen Imports

Add these imports to `lib/src/screens/room_screen.dart`:

```dart
import '../services/playback_engine.dart';
import '../widgets/now_playing_banner.dart';
```

### Step 2: Add PlaybackEngine to _QueueTabState

Modify the `_QueueTabState` class:

```dart
class _QueueTabState extends State<_QueueTab> with AutomaticKeepAliveClientMixin {
  final FirebaseService _firebaseService = FirebaseService();
  PlaybackEngine? _playbackEngine;
  bool _isHost = false;
  bool _isPlaying = false;

  // Track user's votes for optimistic UI updates
  final Map<String, int> _userVotes = {};
  final Map<String, int> _optimisticVotes = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkIfHost();
  }

  @override
  void dispose() {
    _playbackEngine?.stop();
    super.dispose();
  }

  Future<void> _checkIfHost() async {
    final currentUser = _firebaseService.auth.currentUser;
    if (currentUser == null) return;

    final roomDoc = await _firebaseService.roomsCollection.doc(widget.roomId).get();
    final roomData = roomDoc.data() as Map<String, dynamic>?;
    final hostId = roomData?['hostId'] as String?;

    setState(() {
      _isHost = currentUser.uid == hostId;
    });

    // If user is host and has Spotify auth, start playback engine
    if (_isHost) {
      _startPlaybackEngine();
    }
  }

  Future<void> _startPlaybackEngine() async {
    try {
      // Get Spotify access token from auth provider
      final container = ProviderScope.containerOf(context);
      final authNotifier = container.read(authProvider.notifier);

      // Check if user has Spotify auth
      final authState = container.read(authProvider);
      if (authState.tokens == null) {
        print('⚠️  Host doesn\'t have Spotify authentication');
        return;
      }

      final accessToken = await authNotifier.getValidAccessToken();

      _playbackEngine = PlaybackEngine(roomId: widget.roomId);
      await _playbackEngine!.start(accessToken);

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('❌ Failed to start playback engine: $e');
    }
  }

  Future<void> _onPlayPause() async {
    if (_playbackEngine == null) return;

    if (_isPlaying) {
      await _playbackEngine!.pause();
    } else {
      await _playbackEngine!.resume();
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _onSkip() async {
    if (_playbackEngine == null) return;
    await _playbackEngine!.skipToNext();
  }

  // ... rest of existing methods
}
```

### Step 3: Add Now Playing Banner to Queue Tab UI

Modify the `build()` method in `_QueueTabState`:

```dart
@override
Widget build(BuildContext context) {
  super.build(context);

  return Column(
    children: [
      // Now Playing Banner
      StreamBuilder<DocumentSnapshot>(
        stream: _firebaseService.getRoomStream(widget.roomId),
        builder: (context, snapshot) {
          final roomData = snapshot.data?.data() as Map<String, dynamic>?;
          final currentTrack = roomData?['currentTrack'] as Map<String, dynamic>?;

          return NowPlayingBanner(
            title: currentTrack?['title'] as String?,
            artist: currentTrack?['artist'] as String?,
            albumArt: currentTrack?['albumArt'] as String?,
            isHost: _isHost,
            isPlaying: _isPlaying,
            onPlayPause: _isHost ? _onPlayPause : null,
            onSkip: _isHost ? _onSkip : null,
            vibeColor: widget.vibeColor,
          );
        },
      ),

      // Add Song Button
      Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _showSongSearch,
          // ... rest of button config
        ),
      ),

      // Queue List (existing code)
      Expanded(
        child: StreamBuilder<DatabaseEvent>(
          stream: _firebaseService.getQueueStream(widget.roomId),
          builder: (context, snapshot) {
            // ... existing queue builder code
          },
        ),
      ),
    ],
  );
}
```

### Step 4: Run Flutter Pub Get

```bash
flutter pub get
```

### Step 5: Test the Implementation

1. **As Host (with Spotify auth)**:
   - Create a room
   - Add songs to queue
   - Playback engine should automatically start playing top song
   - Use play/pause and skip controls in Now Playing banner

2. **As Guest**:
   - Join a room
   - See the Now Playing banner (read-only, no controls)
   - Vote on songs in queue
   - Banner updates when host plays different tracks

## 🎯 Features Implemented

- ✅ Spotify SDK integration
- ✅ Automatic playback of top-voted songs
- ✅ Real-time queue monitoring
- ✅ Time-decay voting algorithm
- ✅ Now Playing banner with album art
- ✅ Host playback controls (play/pause/skip)
- ✅ Guest read-only Now Playing view
- ✅ Automatic track progression
- ✅ currentTrack sync across all users

## 📝 Notes

- **Spotify Premium Required**: Spotify SDK only works with Premium accounts
- **Mobile Only**: Spotify SDK works on iOS and Android, not web
- **Authentication**: Host must be authenticated with Spotify to use playback
- **Guests**: Can see what's playing but cannot control playback
- **Auto-Play**: Engine automatically plays highest-voted song
- **Smooth Transitions**: Songs auto-advance when completed

## 🐛 Troubleshooting

If playback doesn't start:
1. Ensure host has Spotify Premium account
2. Check Spotify app is installed on device
3. Verify SPOTIFY_CLIENT_ID and SPOTIFY_REDIRECT_URI in `.env`
4. Check console for playback engine errors
5. Make sure access token is valid (not expired)

## 🔮 Future Enhancements

- Progress bar showing song position
- Volume control
- Shuffle/repeat modes
- Playback history
- Cross-fade between tracks
- Sound wave visualizations