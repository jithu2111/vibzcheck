// lib/src/services/token_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spotify_auth_tokens.dart';

/// Service for securely storing and retrieving Spotify tokens
class TokenStorageService {
  // Singleton pattern
  static final TokenStorageService _instance =
      TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal();

  // Storage keys
  static const String _tokensKey = 'spotify_auth_tokens';
  static const String _userProfileKey = 'spotify_user_profile';

  /// Save Spotify tokens to secure storage
  Future<void> saveTokens(SpotifyAuthTokens tokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = json.encode(tokens.toJson());
      await prefs.setString(_tokensKey, tokensJson);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  /// Retrieve Spotify tokens from storage
  Future<SpotifyAuthTokens?> getTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = prefs.getString(_tokensKey);

      if (tokensJson == null) return null;

      final tokensMap = json.decode(tokensJson) as Map<String, dynamic>;
      return SpotifyAuthTokens.fromJson(tokensMap);
    } catch (e) {
      throw Exception('Failed to retrieve tokens: $e');
    }
  }

  /// Delete stored tokens (for logout)
  Future<void> deleteTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokensKey);
      await prefs.remove(_userProfileKey);
    } catch (e) {
      throw Exception('Failed to delete tokens: $e');
    }
  }

  /// Check if tokens exist in storage
  Future<bool> hasTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_tokensKey);
    } catch (e) {
      return false;
    }
  }

  /// Save user profile data
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile);
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Get saved user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson == null) return null;

      return json.decode(profileJson) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to retrieve user profile: $e');
    }
  }
}
