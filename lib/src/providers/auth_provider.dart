// lib/src/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spotify_auth_tokens.dart';
import '../services/spotify_auth_service.dart';
import '../services/token_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Authentication state
class AuthState {
  final SpotifyAuthTokens? tokens;
  final Map<String, dynamic>? userProfile;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  const AuthState({
    this.tokens,
    this.userProfile,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  bool get isAuthenticated => tokens != null || isGuest;
  bool get hasSpotify => tokens != null;

  AuthState copyWith({
    SpotifyAuthTokens? tokens,
    Map<String, dynamic>? userProfile,
    bool? isLoading,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      tokens: tokens ?? this.tokens,
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

/// Authentication notifier
class AuthNotifier extends Notifier<AuthState> {
  late final SpotifyAuthService _spotifyAuth;
  late final TokenStorageService _tokenStorage;

  @override
  AuthState build() {
    _spotifyAuth = SpotifyAuthService();
    _spotifyAuth.initialize();
    _tokenStorage = TokenStorageService();

    _initialize();
    return const AuthState();
  }

  /// Initialize auth state from stored tokens
  Future<void> _initialize() async {
    try {
      final hasTokens = await _tokenStorage.hasTokens();
      if (hasTokens) {
        final tokens = await _tokenStorage.getTokens();
        final profile = await _tokenStorage.getUserProfile();

        if (tokens != null) {
          // Check if token is expired and refresh if needed
          if (tokens.isExpired || tokens.willExpireSoon) {
            await _refreshTokens(tokens.refreshToken);
          } else {
            state = state.copyWith(
              tokens: tokens,
              userProfile: profile,
            );
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize auth: $e');
    }
  }

  /// Login with Spotify
  Future<void> loginWithSpotify() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ignore: avoid_print
      print('🎵 [AUTH] Starting Spotify OAuth flow...');

      // Perform OAuth flow
      final tokens = await _spotifyAuth.authenticate();
      // ignore: avoid_print
      print('✅ [AUTH] OAuth successful! Got tokens');

      // Save tokens
      await _tokenStorage.saveTokens(tokens);
      // ignore: avoid_print
      print('💾 [AUTH] Tokens saved to storage');

      // Get user profile
      final profile = await _spotifyAuth.getUserProfile(tokens.accessToken);
      // ignore: avoid_print
      print('👤 [AUTH] Got user profile: ${profile['display_name']}');

      await _tokenStorage.saveUserProfile(profile);

      // Sign in to Firebase with custom token (optional)
      // This allows us to associate Spotify users with Firebase
      await _signInToFirebase(profile['id'] as String);

      state = state.copyWith(
        tokens: tokens,
        userProfile: profile,
        isLoading: false,
        isGuest: false,
      );

      // ignore: avoid_print
      print('🎉 [AUTH] Login complete! User authenticated');
    } catch (e) {
      // ignore: avoid_print
      print('❌ [AUTH] Login failed: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Spotify login failed: $e',
      );
      rethrow;
    }
  }

  /// Continue as guest (anonymous Firebase auth)
  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Sign in anonymously to Firebase
      await firebase_auth.FirebaseAuth.instance.signInAnonymously();

      state = state.copyWith(
        isLoading: false,
        isGuest: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Guest login failed: $e',
      );
      rethrow;
    }
  }

  /// Refresh access token
  Future<void> _refreshTokens(String refreshToken) async {
    try {
      final newTokens = await _spotifyAuth.refreshAccessToken(refreshToken);
      await _tokenStorage.saveTokens(newTokens);

      state = state.copyWith(tokens: newTokens);
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh token: $e');
      // If refresh fails, log out
      await logout();
    }
  }

  /// Get valid access token (refreshes if needed)
  Future<String> getValidAccessToken() async {
    if (state.tokens == null) {
      throw Exception('Not authenticated with Spotify');
    }

    if (state.tokens!.isExpired || state.tokens!.willExpireSoon) {
      await _refreshTokens(state.tokens!.refreshToken);
    }

    return state.tokens!.accessToken;
  }

  /// Sign in to Firebase (optional - for backend integration)
  Future<void> _signInToFirebase(String spotifyUserId) async {
    try {
      // For now, we'll use anonymous auth
      // In production, you'd create a custom token on your backend
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await firebase_auth.FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      // Non-critical error, just log it
      // ignore: avoid_print
      // print('Firebase sign-in failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _tokenStorage.deleteTokens();
      await firebase_auth.FirebaseAuth.instance.signOut();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Logout failed: $e');
    }
  }
}

/// Auth provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
