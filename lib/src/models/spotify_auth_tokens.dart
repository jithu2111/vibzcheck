// lib/src/models/spotify_auth_tokens.dart

/// Spotify OAuth tokens model
class SpotifyAuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // seconds
  final DateTime obtainedAt;
  final String tokenType;

  SpotifyAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.obtainedAt,
    this.tokenType = 'Bearer',
  });

  /// Check if the access token is expired
  bool get isExpired {
    final expiryTime = obtainedAt.add(Duration(seconds: expiresIn));
    return DateTime.now().isAfter(expiryTime);
  }

  /// Check if token will expire soon (within 5 minutes)
  bool get willExpireSoon {
    final expiryTime = obtainedAt.add(Duration(seconds: expiresIn));
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiryTime);
  }

  /// Create from JSON
  factory SpotifyAuthTokens.fromJson(Map<String, dynamic> json) {
    return SpotifyAuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      obtainedAt: json['obtained_at'] != null
          ? DateTime.parse(json['obtained_at'] as String)
          : DateTime.now(),
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'obtained_at': obtainedAt.toIso8601String(),
      'token_type': tokenType,
    };
  }

  /// Create a copy with updated fields
  SpotifyAuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    DateTime? obtainedAt,
    String? tokenType,
  }) {
    return SpotifyAuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      tokenType: tokenType ?? this.tokenType,
    );
  }
}
