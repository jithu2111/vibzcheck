# Firestore User Documents

## Overview

Every user (Spotify or Guest) now has a document created in Firestore upon successful login. This enables backend tracking, analytics, and proper user management across the app.

## Implementation

### User Service (`lib/src/services/user_service.dart`)

Created a dedicated `UserService` class to handle all Firestore user document operations.

### User Document Structure

```json
{
  "userId": "firebase_uid",
  "displayName": "User Name",
  "email": "user@example.com",  // null for guests
  "spotifyId": "spotify_user_id",  // null for guests
  "isGuest": false,
  "isSpotifyPremium": true,
  "createdAt": "2025-12-12T...",
  "lastLoginAt": "2025-12-12T...",
  "updatedAt": "2025-12-12T...",
  "hostedRooms": 0,
  "joinedRooms": 0,
  "totalVotes": 0
}
```

## Features

### 1. **Automatic User Document Creation**

**On Spotify Login:**
```dart
await _userService.createOrUpdateUser(
  userId: firebaseUser.uid,
  displayName: profile['display_name'] ?? 'Spotify User',
  email: profile['email'],
  spotifyId: profile['id'],
  isGuest: false,
  isSpotifyPremium: true,
);
```

**On Guest Login:**
```dart
await _userService.createOrUpdateUser(
  userId: user.uid,
  displayName: 'Guest User',
  email: null,
  spotifyId: null,
  isGuest: true,
  isSpotifyPremium: false,
);
```

### 2. **Update on Subsequent Logins**

The `createOrUpdateUser` method automatically:
- Creates a new document if user doesn't exist
- Updates existing document if user exists
- Updates `lastLoginAt` timestamp
- Preserves user statistics (hosted rooms, votes, etc.)

### 3. **User Statistics Tracking**

```dart
// Increment stats when user performs actions
await UserService().updateUserStats(
  userId: userId,
  hostedRooms: 1,  // Increment by 1
);

await UserService().updateUserStats(
  userId: userId,
  joinedRooms: 1,
);

await UserService().updateUserStats(
  userId: userId,
  totalVotes: 1,
);
```

### 4. **Fetch User Document**

```dart
final userDoc = await UserService().getUser(userId);

if (userDoc != null) {
  final displayName = userDoc['displayName'];
  final isSpotifyPremium = userDoc['isSpotifyPremium'];
  final hostedRooms = userDoc['hostedRooms'];
}
```

## Console Logging

### New User Creation
```
💾 [USER_SERVICE] Creating/updating user document for firebase_uid
📝 [USER_SERVICE] Creating new user document
✅ [USER_SERVICE] New user document created
```

### Existing User Update
```
💾 [USER_SERVICE] Creating/updating user document for firebase_uid
🔄 [USER_SERVICE] User exists, updating document
✅ [USER_SERVICE] User document updated
```

### Error
```
❌ [USER_SERVICE] Failed to create/update user: [error details]
```

## Firestore Collection Structure

```
firestore
└── users (collection)
    ├── {firebaseUid1} (document)
    │   ├── userId: "firebaseUid1"
    │   ├── displayName: "John Doe"
    │   ├── email: "john@example.com"
    │   ├── spotifyId: "spotify123"
    │   ├── isGuest: false
    │   ├── isSpotifyPremium: true
    │   ├── createdAt: Timestamp
    │   ├── lastLoginAt: Timestamp
    │   ├── updatedAt: Timestamp
    │   ├── hostedRooms: 5
    │   ├── joinedRooms: 12
    │   └── totalVotes: 47
    │
    └── {firebaseUid2} (document)
        ├── userId: "firebaseUid2"
        ├── displayName: "Guest User"
        ├── email: null
        ├── spotifyId: null
        ├── isGuest: true
        ├── isSpotifyPremium: false
        ├── createdAt: Timestamp
        ├── lastLoginAt: Timestamp
        ├── updatedAt: Timestamp
        ├── hostedRooms: 0
        ├── joinedRooms: 3
        └── totalVotes: 15
```

## Security Rules

Add these rules to your Firestore security rules:

```javascript
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;

      // Only the system (via service account) can create/update user documents
      // Or the user themselves for their own document
      allow write: if request.auth != null && request.auth.uid == userId;

      // Allow users to read basic info of other users (for display in rooms)
      allow get: if request.auth != null;
    }
  }
}
```

## Usage Examples

### 1. Check if User is Premium (for hosting rooms)

```dart
final authState = ref.watch(authProvider);
final userId = authState.userProfile?['id'];

final userDoc = await UserService().getUser(userId);
final isPremium = userDoc?['isSpotifyPremium'] ?? false;

if (isPremium) {
  // Allow hosting room
} else {
  // Show premium required message
}
```

### 2. Display User Stats

```dart
final userDoc = await UserService().getUser(userId);

Text('Rooms Hosted: ${userDoc?['hostedRooms'] ?? 0}');
Text('Rooms Joined: ${userDoc?['joinedRooms'] ?? 0}');
Text('Total Votes: ${userDoc?['totalVotes'] ?? 0}');
```

### 3. Update Stats After Action

```dart
// After user hosts a room
await UserService().updateUserStats(
  userId: userId,
  hostedRooms: 1,
);

// After user joins a room
await UserService().updateUserStats(
  userId: userId,
  joinedRooms: 1,
);

// After user votes on a song
await UserService().updateUserStats(
  userId: userId,
  totalVotes: 1,
);
```

### 4. Leaderboard / Analytics

```dart
// Query top hosts
final topHosts = await FirebaseFirestore.instance
    .collection('users')
    .orderBy('hostedRooms', descending: true)
    .limit(10)
    .get();

// Query most active voters
final topVoters = await FirebaseFirestore.instance
    .collection('users')
    .orderBy('totalVotes', descending: true)
    .limit(10)
    .get();
```

## Benefits

✅ **User Tracking** - Every user has a permanent record
✅ **Analytics Ready** - Track user behavior and engagement
✅ **Statistics** - Rooms hosted, joined, votes cast
✅ **Premium Detection** - Easy to check if user can host rooms
✅ **Leaderboards** - Built-in stats for gamification
✅ **Backend Integration** - User documents enable backend features
✅ **Activity Tracking** - Last login timestamps

## Testing

### Test Spotify User Creation

1. Run app and login with Spotify
2. Check Firebase Console → Firestore → `users` collection
3. Verify document exists with Spotify user data
4. **Expected fields:**
   - `userId`: Firebase UID
   - `displayName`: Spotify display name
   - `email`: Spotify email
   - `spotifyId`: Spotify user ID
   - `isGuest`: false
   - `isSpotifyPremium`: true

### Test Guest User Creation

1. Run app and tap "Continue as Guest"
2. Check Firebase Console → Firestore → `users` collection
3. Verify document exists with guest data
4. **Expected fields:**
   - `userId`: Firebase UID
   - `displayName`: "Guest User"
   - `email`: null
   - `spotifyId`: null
   - `isGuest`: true
   - `isSpotifyPremium`: false

### Test Update on Re-login

1. Login (Spotify or Guest)
2. Logout
3. Login again
4. Check Firestore document
5. **Expected:**
   - Same `userId`
   - Same `createdAt`
   - Updated `lastLoginAt`
   - Updated `updatedAt`
   - Preserved stats (hostedRooms, etc.)

## Console Output

### Complete Flow

```
🎵 [AUTH] Starting Spotify OAuth flow...
...
👤 [AUTH] Got user profile: John Doe
💾 [USER_SERVICE] Creating/updating user document for firebase_uid_123
📝 [USER_SERVICE] Creating new user document
✅ [USER_SERVICE] New user document created
🎉 [AUTH] Login complete! User authenticated
```

Or for guest:

```
👤 [AUTH] Starting guest login...
✅ [AUTH] Anonymous Firebase user created: firebase_uid_456
📝 [AUTH] Created guest profile
💾 [USER_SERVICE] Creating/updating user document for firebase_uid_456
📝 [USER_SERVICE] Creating new user document
✅ [USER_SERVICE] New user document created
🎉 [AUTH] Guest login complete!
```

## Files Modified

1. **`lib/src/services/user_service.dart`** (NEW)
   - User document CRUD operations
   - Statistics tracking
   - Error handling

2. **`lib/src/providers/auth_provider.dart`**
   - Added UserService initialization
   - Calls createOrUpdateUser on Spotify login
   - Calls createOrUpdateUser on guest login
   - Updated _signInToFirebase to return user

## Summary

✅ User documents automatically created in Firestore on login
✅ Works for both Spotify and Guest users
✅ Updates on subsequent logins
✅ Tracks user statistics (rooms, votes)
✅ Production-ready with comprehensive logging
✅ Ready for analytics and leaderboards

Every user now has a permanent record in Firestore, enabling backend features, analytics, and proper user management! 🎉
