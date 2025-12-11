# Firebase Database Schema for VibzCheck

## Overview
This document defines the complete database structure for VibzCheck, the collaborative Spotify queue application. We use **Firestore** for persistent data and **Realtime Database** for live updates.

---

## Firestore Collections

### 1. `rooms` Collection
Stores room metadata and configuration.

```json
{
  "roomId": {
    "name": "Friday Night Party",
    "hostId": "user123",
    "vibe": "Party", // Options: "Chill", "Party", "Workout", "Study"
    "password": "abc123", // Optional, null if public
    "createdAt": Timestamp,
    "isActive": true,
    "currentTrack": {
      "songId": "spotify:track:xyz",
      "title": "Song Name",
      "artist": "Artist Name",
      "albumArt": "https://...",
      "startedAt": Timestamp
    },
    "members": ["user123", "user456"], // Array of user IDs
    "settings": {
      "autoRemoveThreshold": -3, // Remove songs with this many downvotes
      "allowGuestVoting": true,
      "maxQueueSize": 50
    }
  }
}
```

**Indexes Required:**
- `hostId` (for querying user's rooms)
- `isActive` (for active room discovery)
- `createdAt` (for sorting)

---

### 2. `users` Collection
Stores user profiles.

```json
{
  "userId": {
    "displayName": "John Doe",
    "spotifyId": "spotify_user_123",
    "photoUrl": "https://...",
    "email": "user@example.com",
    "isPremium": true, // Can be host
    "lastActive": Timestamp,
    "preferences": {
      "favoriteVibes": ["Party", "Chill"],
      "defaultVibe": "Party"
    }
  }
}
```

---

### 3. `rooms/{roomId}/messages` Subcollection
Chat messages within a room.

```json
{
  "messageId": {
    "userId": "user123",
    "message": "This song is fire!",
    "timestamp": Timestamp
  }
}
```

**Indexes Required:**
- `timestamp` (for ordering)

---

## Firebase Realtime Database

### 1. `queues/{roomId}` Node
The dynamic song queue with real-time voting.

```json
{
  "queues": {
    "room123": {
      "songKey1": {
        "songId": "spotify:track:abc",
        "title": "Song Title",
        "artist": "Artist Name",
        "albumArt": "https://...",
        "addedBy": "user456",
        "votes": 5, // Net votes (upvotes - downvotes)
        "addedAt": 1638360000000, // Unix timestamp
        "audioFeatures": {
          "energy": 0.8,
          "valence": 0.7,
          "tempo": 120
        }
      },
      "songKey2": {
        "songId": "spotify:track:def",
        "title": "Another Song",
        "artist": "Another Artist",
        "albumArt": "https://...",
        "addedBy": "user123",
        "votes": -2,
        "addedAt": 1638360100000
      }
    }
  }
}
```

**Queue Sorting Logic:**
```
Priority Score = (Current Timestamp - addedAt) / 1000 + votes * 10
```
Songs are sorted by descending priority score.

---

### 2. `votes/{roomId}/{songKey}` Node
Track individual user votes (prevent duplicate voting).

```json
{
  "votes": {
    "room123": {
      "songKey1": {
        "user123": 1,  // 1 = upvote, -1 = downvote
        "user456": -1
      }
    }
  }
}
```

---

### 3. `reactions/{roomId}` Node
Ephemeral reactions (auto-delete after 5 seconds, handled client-side).

```json
{
  "reactions": {
    "room123": {
      "reactionKey1": {
        "userId": "user123",
        "type": "fire", // "fire", "heart", "cry"
        "timestamp": 1638360000000
      }
    }
  }
}
```

---

### 4. `playback/{roomId}` Node
Real-time playback state (Host-controlled).

```json
{
  "playback": {
    "room123": {
      "isPlaying": true,
      "currentTrack": {
        "songId": "spotify:track:abc",
        "position": 45000, // Position in ms
        "duration": 180000
      },
      "lastUpdated": 1638360000000
    }
  }
}
```

---

## Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Rooms collection
    match /rooms/{roomId} {
      // Anyone can read active rooms
      allow read: if resource.data.isActive == true;

      // Only authenticated users can create rooms
      allow create: if request.auth != null;

      // Only host can update/delete room
      allow update, delete: if request.auth.uid == resource.data.hostId;

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }

    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

### Realtime Database Rules
```json
{
  "rules": {
    "queues": {
      "$roomId": {
        ".read": true,
        ".write": "auth != null"
      }
    },
    "votes": {
      "$roomId": {
        "$songKey": {
          "$userId": {
            ".write": "auth.uid === $userId"
          }
        },
        ".read": true
      }
    },
    "reactions": {
      "$roomId": {
        ".read": true,
        ".write": "auth != null"
      }
    },
    "playback": {
      "$roomId": {
        ".read": true,
        ".write": "auth != null"
      }
    }
  }
}
```

---

## Setup Instructions

### 1. Enable Services in Firebase Console
- Go to Firebase Console → Your Project
- **Firestore**: Build → Firestore Database → Create Database (Start in test mode)
- **Realtime Database**: Build → Realtime Database → Create Database (Start in test mode)
- **Authentication**: Build → Authentication → Enable Anonymous Auth (for guest mode)

### 2. Create Indexes in Firestore
Navigate to Firestore → Indexes and create:
- Collection: `rooms`, Fields: `isActive ASC`, `createdAt DESC`
- Collection: `rooms/{roomId}/messages`, Fields: `timestamp ASC`

### 3. Apply Security Rules
- Copy the Firestore rules to Firestore → Rules tab
- Copy the Realtime Database rules to Realtime Database → Rules tab
- **Important**: Change from test mode to production rules before launch!

### 4. Set Up Cloud Functions (Future Enhancement)
For auto-cleanup and advanced features:
- Remove inactive rooms after 24 hours
- Delete reactions older than 5 seconds
- Send notifications when your song is next in queue

---

## Data Flow Examples

### Creating a Room
1. User creates room → Firestore `rooms` collection
2. Room ID returned → User becomes host
3. Listen to `rooms/{roomId}` for real-time updates

### Adding a Song
1. User searches Spotify API
2. Add song to Realtime Database `queues/{roomId}`
3. All clients receive real-time update
4. Queue re-sorted based on votes + time

### Voting
1. User clicks upvote/downvote
2. Check `votes/{roomId}/{songKey}/{userId}` for existing vote
3. Update vote using Transaction (prevents race conditions)
4. Increment/decrement `queues/{roomId}/{songKey}/votes`
5. If votes < threshold, auto-remove song

### Real-time Playback Sync
1. Host app controls Spotify SDK
2. Host updates `playback/{roomId}` every 5 seconds
3. Guests listen to `playback/{roomId}` for UI updates
4. Show "Now Playing" banner on all devices

---

## Performance Considerations

1. **Offline Persistence**: Enabled in `main.dart` for Firestore
2. **Pagination**: Chat limited to last 100 messages
3. **Queue Size Limit**: Max 50 songs per room
4. **Cache Strategy**: Album art cached using `cached_network_image`
5. **Realtime Listeners**: Automatically disconnect when user leaves room

---

This schema is designed to handle the core "Must-Solve Challenges" you identified:
- ✅ Real-time vote synchronization (Realtime Database Transactions)
- ✅ Complex playlist state management (Priority score algorithm)
- ✅ Offline support (Firestore persistence)