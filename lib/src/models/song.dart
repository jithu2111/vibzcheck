// lib/src/models/song.dart

/// Song model representing a Spotify track
/// Contains the essential information needed to display and queue songs
class Song {
  final String id;           // Spotify track ID
  final String name;         // Track name
  final String artist;       // Artist name(s)
  final String? albumArt;    // Album cover image URL
  final String uri;          // Spotify URI (spotify:track:xxx)
  final int? durationMs;     // Track duration in milliseconds
  final String? album;       // Album name

  const Song({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArt,
    required this.uri,
    this.durationMs,
    this.album,
  });

  /// Create a Song from Spotify API JSON response
  factory Song.fromSpotifyJson(Map<String, dynamic> json) {
    // Extract artist names
    final artists = (json['artists'] as List?)
        ?.map((artist) => artist['name'] as String)
        .join(', ') ?? 'Unknown Artist';

    // Get album art (prefer medium size, fallback to first available)
    String? albumArt;
    final images = json['album']?['images'] as List?;
    if (images != null && images.isNotEmpty) {
      // Try to get medium size (300x300) or just take the first one
      albumArt = images.length > 1 ? images[1]['url'] : images[0]['url'];
    }

    return Song(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: artists,
      albumArt: albumArt,
      uri: json['uri'] as String,
      durationMs: json['duration_ms'] as int?,
      album: json['album']?['name'] as String?,
    );
  }

  /// Convert to JSON for Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'albumArt': albumArt,
      'uri': uri,
      'durationMs': durationMs,
      'album': album,
    };
  }

  /// Create a Song from Firebase JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      albumArt: json['albumArt'] as String?,
      uri: json['uri'] as String,
      durationMs: json['durationMs'] as int?,
      album: json['album'] as String?,
    );
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    if (durationMs == null) return '--:--';

    final duration = Duration(milliseconds: durationMs!);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  String toString() {
    return 'Song(name: $name, artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}