# Spotify OAuth 2.0 Implementation Guide

## ✅ What's Been Implemented

The complete Spotify OAuth 2.0 flow with PKCE (Proof Key for Code Exchange) has been implemented for VibzCheck.

### Files Created:

1. **`lib/src/models/spotify_auth_tokens.dart`**
   - Model for storing access tokens, refresh tokens, and expiry info
   - Methods for checking if tokens are expired

2. **`lib/src/services/spotify_auth_service.dart`**
   - Complete OAuth 2.0 authorization code flow
   - PKCE implementation for security
   - Token refresh functionality
   - User profile fetching

3. **`lib/src/services/token_storage_service.dart`**
   - Secure token storage using SharedPreferences
   - Save/retrieve/delete tokens
   - Store user profile data

4. **`lib/src/providers/auth_provider.dart`**
   - Riverpod state management for authentication
   - Handles Spotify login
   - Handles guest login (Firebase anonymous)
   - Auto token refresh when expired

5. **Updated `lib/src/screens/login_screen.dart`**
   - Integrated with auth provider
   - Loading states
   - Error handling with snackbars

---

## How It Works

### 1. User Clicks "Connect with Spotify"

```dart
await ref.read(authProvider.notifier).loginWithSpotify();
```

### 2. OAuth Flow Begins

1. **Authorization URL** is generated with:
   - Client ID (from `.env`)
   - Redirect URI (`vibzcheck://callback`)
   - Scopes (permissions needed)
   - SHA256 PKCE code challenge

2. **Browser Opens** via `url_launcher`
   - User sees Spotify login page in external browser
   - User grants permissions
   - `app_links` listens for the callback

3. **Callback Received**
   - Deep link callback caught by `app_links`
   - Authorization code extracted from URI
   - Exchanges code for tokens

4. **Tokens Stored**
   - Access token (expires in 1 hour)
   - Refresh token (long-lived)
   - Saved securely in SharedPreferences

5. **User Profile Fetched**
   - Gets Spotify user data
   - Stores in local storage

6. **Firebase Sign-In** (optional)
   - Anonymous auth for backend integration
   - Links Spotify user with Firebase

---

## Spotify Scopes Requested

The app requests these permissions:

```dart
- user-read-private           // Read user profile
- user-read-email             // Read user email
- user-read-playback-state    // See what's playing
- user-modify-playback-state  // Control playback
- user-read-currently-playing // Current track info
- streaming                   // Play music
- playlist-read-private       // Read playlists
- playlist-read-collaborative // Read collaborative playlists
- user-library-read           // Read saved tracks
```

---

## Token Management

### Auto-Refresh Logic

Tokens are automatically refreshed when:
- Token is expired (`isExpired`)
- Token will expire soon (`willExpireSoon` - within 5 minutes)

```dart
if (tokens.isExpired || tokens.willExpireSoon) {
  await _refreshTokens(tokens.refreshToken);
}
```

### Getting a Valid Token

```dart
final token = await ref.read(authProvider.notifier).getValidAccessToken();
// Always returns a fresh, valid access token
```

---

## Testing the OAuth Flow

### Prerequisites

1. ✅ Spotify Developer App created
2. ✅ Client ID added to `.env`
3. ✅ Redirect URI `vibzcheck://callback` added to Spotify Dashboard
4. ✅ Deep linking configured (Android/iOS)

### Test Steps

1. Run the app:
   ```bash
   flutter run
   ```

2. Tap "Connect with Spotify"

3. **Expected Flow:**
   - Browser opens with Spotify login
   - Login with your Spotify account
   - Grant permissions
   - App redirects back
   - Navigate to home screen

4. **Check Storage:**
   - Tokens are saved in SharedPreferences
   - User profile is saved

5. **Test Token Refresh:**
   - Wait 5 minutes
   - Make any Spotify API call
   - Token should auto-refresh

---

## Troubleshooting

### Issue: "Redirect URI mismatch"
**Solution:** Make sure `vibzcheck://callback` is exactly as configured in:
- `.env` file
- Spotify Developer Dashboard
- AndroidManifest.xml / Info.plist

### Issue: "Client ID not found"
**Solution:** Check `.env` file has:
```
SPOTIFY_CLIENT_ID=your_actual_client_id_here
SPOTIFY_REDIRECT_URL=vibzcheck://callback
```

### Issue: Browser doesn't redirect back
**Solution:**
- Android: Check AndroidManifest.xml has the intent-filter (line 31-38)
- iOS: Check Info.plist has CFBundleURLSchemes (line 55-63)

### Issue: "Token refresh failed"
**Solution:**
- Check internet connection
- Verify refresh token is still valid
- May need to re-authenticate

---

## Security Features

✅ **PKCE (Proof Key for Code Exchange) with SHA256**
- Prevents authorization code interception
- Uses SHA256 hashing for code challenge
- Cryptographically secure random code verifier generation
- No client secret needed in mobile app

✅ **Secure Storage**
- Tokens stored in SharedPreferences
- Not exposed in code

✅ **Auto Expiry Handling**
- Tokens auto-refresh before expiry
- Graceful error handling

✅ **Firebase Integration**
- Anonymous auth for guests
- Backend can verify users

---

## Next Steps

### Using the Tokens

To make Spotify API calls:

```dart
// Get valid token
final token = await ref.read(authProvider.notifier).getValidAccessToken();

// Make API request
final response = await http.get(
  Uri.parse('https://api.spotify.com/v1/me/player'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

### Implementing Spotify Features

1. **Search Songs** - Use Spotify Search API
2. **Get Track Info** - Use Tracks API
3. **Control Playback** - Use Player API
4. **Get User Playlists** - Use Playlists API

---

## Environment Variables Required

Make sure your `.env` file contains:

```env
SPOTIFY_CLIENT_ID=c995764e4db14f7a859b86af4fb3430e
SPOTIFY_REDIRECT_URL=vibzcheck://callback
```

---

## Auth State Management

The `authProvider` exposes:

```dart
class AuthState {
  final SpotifyAuthTokens? tokens;
  final Map<String, dynamic>? userProfile;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  bool get isAuthenticated => tokens != null || isGuest;
  bool get hasSpotify => tokens != null;
}
```

**Usage in UI:**

```dart
final authState = ref.watch(authProvider);

if (authState.isLoading) {
  return CircularProgressIndicator();
}

if (authState.hasSpotify) {
  final userName = authState.userProfile?['display_name'];
  return Text('Welcome, $userName!');
}
```

---

## Summary

✅ Full OAuth 2.0 implementation
✅ PKCE for security
✅ Token storage and auto-refresh
✅ Firebase integration for backend
✅ Guest mode support
✅ Production-ready error handling

The OAuth flow is complete and ready to use! 🎉
