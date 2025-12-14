// lib/src/services/spotify_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/song.dart';

/// Spotify API Service
/// Handles Spotify API calls for both authenticated users and guests
/// - Authenticated users: Use their personal access token
/// - Guests: Use Client Credentials flow for app-level access
class SpotifyService {
  // Singleton pattern
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  // Spotify API endpoints
  static const String _tokenEndpoint = 'https://accounts.spotify.com/api/token';
  static const String _searchEndpoint = 'https://api.spotify.com/v1/search';

  // OAuth configuration from .env
  late final String _clientId;
  late final String _clientSecret;

  // Client Credentials token cache
  String? _clientCredentialsToken;
  DateTime? _tokenExpiry;

  /// Initialize the service with environment variables
  void initialize() {
    _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    _clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

    if (_clientId.isEmpty) {
      throw Exception(
          'SPOTIFY_CLIENT_ID not found in .env file. Please add your Spotify Client ID.');
    }

    if (_clientSecret.isEmpty) {
      throw Exception(
          'SPOTIFY_CLIENT_SECRET not found in .env file. Please add your Spotify Client Secret.');
    }
  }

  /// Get a Client Credentials token for guest users
  /// This allows guests to search Spotify without logging in
  Future<String> getClientCredentialsToken() async {
    // Return cached token if still valid
    if (_clientCredentialsToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      // ignore: avoid_print
      print('🎫 [SPOTIFY] Using cached client credentials token');
      return _clientCredentialsToken!;
    }

    try {
      // ignore: avoid_print
      print('🔐 [SPOTIFY] Requesting new client credentials token...');

      // Encode client ID and secret
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        _clientCredentialsToken = jsonResponse['access_token'] as String;

        // Set expiry (Spotify tokens typically last 3600 seconds = 1 hour)
        // We'll set it to expire 5 minutes early to be safe
        final expiresIn = (jsonResponse['expires_in'] as int?) ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));

        // ignore: avoid_print
        print('✅ [SPOTIFY] Client credentials token obtained, expires in $expiresIn seconds');

        return _clientCredentialsToken!;
      } else {
        // ignore: avoid_print
        print('❌ [SPOTIFY] Failed to get client credentials token: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to get client credentials token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('💥 [SPOTIFY] Client credentials exception: $e');
      throw Exception('Failed to get client credentials token: $e');
    }
  }

  /// Search for tracks on Spotify
  /// - [query]: The search query (e.g., "Taylor Swift")
  /// - [accessToken]: Optional user access token. If null, uses client credentials
  /// - [limit]: Maximum number of results to return (default: 20)
  Future<List<Song>> search({
    required String query,
    String? accessToken,
    int limit = 20,
  }) async {
    try {
      // Get the appropriate access token
      final token = accessToken ?? await getClientCredentialsToken();

      // ignore: avoid_print
      print('🔍 [SPOTIFY] Searching for: "$query" (using ${accessToken != null ? 'user' : 'client'} token)');

      // Build search URL
      final url = Uri.parse(_searchEndpoint).replace(
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': limit.toString(),
        },
      );

      // Make the API request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final tracks = jsonResponse['tracks']?['items'] as List?;

        if (tracks == null || tracks.isEmpty) {
          // ignore: avoid_print
          print('ℹ️ [SPOTIFY] No tracks found for query: "$query"');
          return [];
        }

        // Parse tracks into Song objects
        final songs = tracks
            .map((trackJson) => Song.fromSpotifyJson(trackJson as Map<String, dynamic>))
            .toList();

        // ignore: avoid_print
        print('✅ [SPOTIFY] Found ${songs.length} tracks');

        return songs;
      } else if (response.statusCode == 401) {
        // Token expired, clear cache and retry once
        // ignore: avoid_print
        print('⚠️ [SPOTIFY] Token expired, clearing cache and retrying...');
        _clientCredentialsToken = null;
        _tokenExpiry = null;

        // Retry once (but only if we were using client credentials)
        if (accessToken == null) {
          return await search(query: query, accessToken: accessToken, limit: limit);
        } else {
          throw Exception('User access token expired. Please refresh token.');
        }
      } else {
        // ignore: avoid_print
        print('❌ [SPOTIFY] Search failed: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Spotify search failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('💥 [SPOTIFY] Search exception: $e');
      throw Exception('Failed to search Spotify: $e');
    }
  }

  /// Get track details by Spotify track ID
  Future<Song?> getTrack(String trackId, {String? accessToken}) async {
    try {
      final token = accessToken ?? await getClientCredentialsToken();

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/tracks/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Song.fromSpotifyJson(jsonResponse);
      } else {
        // ignore: avoid_print
        print('❌ [SPOTIFY] Failed to get track: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('💥 [SPOTIFY] Get track exception: $e');
      return null;
    }
  }

  /// Clear cached client credentials token (useful for logout)
  void clearCache() {
    _clientCredentialsToken = null;
    _tokenExpiry = null;
  }
}