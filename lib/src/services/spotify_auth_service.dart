// lib/src/services/spotify_auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/spotify_auth_tokens.dart';

/// Spotify OAuth 2.0 Authentication Service
/// Handles the complete OAuth flow and token management
class SpotifyAuthService {
  // Singleton pattern
  static final SpotifyAuthService _instance = SpotifyAuthService._internal();
  factory SpotifyAuthService() => _instance;
  SpotifyAuthService._internal();

  // Spotify OAuth endpoints
  static const String _authorizationEndpoint =
      'https://accounts.spotify.com/authorize';
  static const String _tokenEndpoint =
      'https://accounts.spotify.com/api/token';

  // OAuth configuration from .env
  late final String _clientId;
  late final String _redirectUri;

  // Scopes needed for VibzCheck
  static const List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'streaming',
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-library-read',
  ];

  /// Initialize the service with environment variables
  void initialize() {
    _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    _redirectUri = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? 'vibzcheck://callback';

    if (_clientId.isEmpty) {
      throw Exception(
          'SPOTIFY_CLIENT_ID not found in .env file. Please add your Spotify Client ID.');
    }
  }

  /// Start the OAuth 2.0 authorization flow
  /// Returns tokens if successful, throws exception on failure
  Future<SpotifyAuthTokens> authenticate() async {
    try {
      // Step 1: Build authorization URL with PKCE
      // ignore: avoid_print
      print('🔐 [SPOTIFY] Generating PKCE code verifier and challenge...');
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUrl = Uri.parse(_authorizationEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'scope': _scopes.join(' '),
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
          'show_dialog': 'false', // Don't force approval screen every time
        },
      );

      // ignore: avoid_print
      print('🌐 [SPOTIFY] Opening browser for authorization...');

      // Step 2: Set up app links listener to catch the callback
      final appLinks = AppLinks();
      final completer = Completer<Uri>();

      // Listen for incoming links
      late StreamSubscription<Uri> linkSubscription;
      linkSubscription = appLinks.uriLinkStream.listen((uri) {
        // ignore: avoid_print
        print('🔙 [SPOTIFY] Received callback: $uri');
        if (!completer.isCompleted && uri.scheme == 'vibzcheck') {
          completer.complete(uri);
          linkSubscription.cancel();
        }
      });

      // Launch the Spotify authorization URL in browser
      if (!await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      )) {
        linkSubscription.cancel();
        throw Exception('Could not launch authorization URL');
      }

      // Wait for the callback with timeout
      final callbackUri = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          linkSubscription.cancel();
          throw Exception('OAuth timeout - no callback received');
        },
      );

      // ignore: avoid_print
      print('✅ [SPOTIFY] Successfully received callback');

      // Step 3: Extract authorization code from callback
      final code = callbackUri.queryParameters['code'];
      if (code == null) {
        throw Exception('Authorization code not found in callback');
      }

      // ignore: avoid_print
      print('🎫 [SPOTIFY] Got authorization code, exchanging for tokens...');

      // Step 4: Exchange code for tokens
      final tokens = await _exchangeCodeForTokens(code, codeVerifier);

      // ignore: avoid_print
      print('✅ [SPOTIFY] Successfully obtained access and refresh tokens');

      return tokens;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [SPOTIFY] Authentication failed: $e');
      throw Exception('Spotify authentication failed: $e');
    }
  }

  /// Exchange authorization code for access and refresh tokens
  Future<SpotifyAuthTokens> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    try {
      // ignore: avoid_print
      print('🔄 [SPOTIFY] Sending token exchange request to Spotify...');

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': codeVerifier,
        },
      );

      // ignore: avoid_print
      print('📡 [SPOTIFY] Token exchange response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // ignore: avoid_print
        print('✨ [SPOTIFY] Token exchange successful!');
        return SpotifyAuthTokens.fromJson(jsonResponse);
      } else {
        // ignore: avoid_print
        print('⚠️ [SPOTIFY] Token exchange error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Token exchange failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('💥 [SPOTIFY] Token exchange exception: $e');
      throw Exception('Failed to exchange code for tokens: $e');
    }
  }

  /// Refresh an expired access token using the refresh token
  Future<SpotifyAuthTokens> refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Spotify doesn't return a new refresh token, so we keep the old one
        return SpotifyAuthTokens.fromJson({
          ...jsonResponse,
          'refresh_token': refreshToken,
        });
      } else {
        throw Exception(
            'Token refresh failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to refresh access token: $e');
    }
  }

  /// Generate a random code verifier for PKCE (Proof Key for Code Exchange)
  String _generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      128,
      (i) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generate code challenge from code verifier (SHA256)
  String _generateCodeChallenge(String verifier) {
    // Hash the verifier using SHA256
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);

    // Convert to base64url encoding (RFC 4648)
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Get user profile information
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to get user profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
}
