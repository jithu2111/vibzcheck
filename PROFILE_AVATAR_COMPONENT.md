# ProfileAvatar Component

## Overview

A beautiful, reusable profile avatar component with online status indicator, support for multiple sizes, and automatic styling for Spotify vs Guest users.

## Features

✅ **Multiple Sizes** - Small, Medium, Large, Extra Large presets
✅ **Online Status Indicator** - Online, Offline, Away, Hidden
✅ **User Type Styling** - Automatic styling for Spotify vs Guest users
✅ **Image Support** - Profile images with fallback to initials
✅ **Loading States** - Built-in loading indicator for network images
✅ **Error Handling** - Graceful fallback if image fails to load
✅ **Tap Callback** - Optional onTap handler
✅ **Customizable Border** - Show/hide border around avatar
✅ **Responsive** - Adapts status indicator size to avatar size

## Usage

### Basic Usage

```dart
import 'package:vibzcheck/src/widgets/profile_avatar.dart';

// Simple avatar with initials
ProfileAvatar(
  displayName: 'John Doe',
)

// With online status
ProfileAvatar(
  displayName: 'John Doe',
  onlineStatus: OnlineStatus.online,
)

// Large avatar
ProfileAvatar(
  displayName: 'John Doe',
  size: AvatarSize.large,
  onlineStatus: OnlineStatus.online,
)
```

### Spotify User

```dart
ProfileAvatar(
  displayName: profile['display_name'],
  imageUrl: profile['images']?[0]?['url'],
  isGuest: false,
  onlineStatus: OnlineStatus.online,
  size: AvatarSize.large,
)
```

**Result:**
- Purple/Pink gradient background
- First letter of name as initial
- Spotify profile image if available
- Purple border with glow effect
- Green status indicator (online)

### Guest User

```dart
ProfileAvatar(
  displayName: 'Guest User',
  isGuest: true,
  onlineStatus: OnlineStatus.online,
  size: AvatarSize.medium,
)
```

**Result:**
- Cyan gradient background
- Person icon instead of initial
- Cyan border
- Green status indicator (online)

### With Tap Handler

```dart
ProfileAvatar(
  displayName: 'John Doe',
  onlineStatus: OnlineStatus.online,
  onTap: () {
    // Navigate to profile screen
    Navigator.push(...);
  },
)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `displayName` | `String` | **required** | User's display name (used for initials) |
| `imageUrl` | `String?` | `null` | Optional profile image URL |
| `isGuest` | `bool` | `false` | Whether this is a guest user (affects styling) |
| `onlineStatus` | `OnlineStatus` | `OnlineStatus.hidden` | Online status indicator |
| `size` | `AvatarSize` | `AvatarSize.medium` | Size of the avatar |
| `onTap` | `VoidCallback?` | `null` | Optional tap callback |
| `showBorder` | `bool` | `true` | Whether to show border around avatar |

## Enums

### AvatarSize

```dart
enum AvatarSize {
  small,       // 40x40
  medium,      // 60x60
  large,       // 100x100
  extraLarge,  // 120x120
}
```

### OnlineStatus

```dart
enum OnlineStatus {
  online,   // Green indicator
  offline,  // Gray indicator
  away,     // Pink/Orange indicator
  hidden,   // No indicator shown
}
```

## Examples

### Room Member List

```dart
ListView.builder(
  itemCount: members.length,
  itemBuilder: (context, index) {
    final member = members[index];
    return ListTile(
      leading: ProfileAvatar(
        displayName: member.name,
        imageUrl: member.imageUrl,
        isGuest: member.isGuest,
        onlineStatus: member.isOnline
            ? OnlineStatus.online
            : OnlineStatus.offline,
        size: AvatarSize.small,
      ),
      title: Text(member.name),
      subtitle: Text(member.isGuest ? 'Guest' : 'Premium'),
    );
  },
)
```

### Room Host Display

```dart
Row(
  children: [
    ProfileAvatar(
      displayName: hostName,
      imageUrl: hostImageUrl,
      isGuest: false,
      onlineStatus: OnlineStatus.online,
      size: AvatarSize.medium,
    ),
    SizedBox(width: 12),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hostName, style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Host • Premium'),
      ],
    ),
  ],
)
```

### Chat Message

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ProfileAvatar(
      displayName: message.senderName,
      isGuest: message.isGuest,
      size: AvatarSize.small,
      onlineStatus: OnlineStatus.hidden, // Don't show status in chat
    ),
    SizedBox(width: 8),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.senderName),
          Text(message.text),
        ],
      ),
    ),
  ],
)
```

### User Profile Screen

```dart
Column(
  children: [
    ProfileAvatar(
      displayName: user.name,
      imageUrl: user.imageUrl,
      isGuest: user.isGuest,
      onlineStatus: OnlineStatus.online,
      size: AvatarSize.extraLarge,
    ),
    SizedBox(height: 16),
    Text(user.name, style: TextStyle(fontSize: 24)),
    Text(user.isGuest ? 'Guest User' : 'Premium Member'),
  ],
)
```

## Styling

### Spotify User Styling
- **Background:** Purple to Pink gradient
- **Border:** Purple with alpha
- **Glow:** Purple shadow effect
- **Initial:** First letter in white
- **Status Position:** Bottom-right corner

### Guest User Styling
- **Background:** Cyan gradient (subtle)
- **Border:** Cyan with alpha
- **Glow:** None
- **Icon:** Person outline icon in cyan
- **Status Position:** Bottom-right corner

### Status Indicator Colors
- **Online:** Spotify Green (`#1DB954`)
- **Offline:** Gray/Disabled color
- **Away:** Warm Pink/Orange
- **Hidden:** No indicator shown

## Responsive Design

The component automatically scales all elements based on the chosen size:

| Size | Avatar | Font | Status | Border |
|------|--------|------|--------|--------|
| Small | 40px | 16px | 10px | 2px |
| Medium | 60px | 24px | 14px | 2.5px |
| Large | 100px | 48px | 20px | 3px |
| Extra Large | 120px | 56px | 24px | 3.5px |

## Image Loading

The component handles image loading gracefully:

1. **Loading State:** Shows circular progress indicator
2. **Success:** Displays the image
3. **Error:** Falls back to initial/icon
4. **No URL:** Shows initial/icon immediately

## Best Practices

### 1. Use Appropriate Sizes

```dart
// Small - List items, chat messages
ProfileAvatar(displayName: name, size: AvatarSize.small)

// Medium - Cards, room members
ProfileAvatar(displayName: name, size: AvatarSize.medium)

// Large - Profile screens, home screen
ProfileAvatar(displayName: name, size: AvatarSize.large)

// Extra Large - Full profile views
ProfileAvatar(displayName: name, size: AvatarSize.extraLarge)
```

### 2. Show Status Only When Relevant

```dart
// In room member list - show status
ProfileAvatar(
  displayName: name,
  onlineStatus: isOnline ? OnlineStatus.online : OnlineStatus.offline,
)

// In chat messages - hide status
ProfileAvatar(
  displayName: name,
  onlineStatus: OnlineStatus.hidden,
)
```

### 3. Handle Missing Data

```dart
ProfileAvatar(
  displayName: user?.name ?? 'Unknown',
  imageUrl: user?.imageUrl,
  isGuest: user?.isGuest ?? true,
)
```

### 4. Add Tap Interactions

```dart
ProfileAvatar(
  displayName: name,
  onTap: () {
    // Navigate to user profile
    // Show user options
    // Start chat
  },
)
```

## Demo Screen

A comprehensive demo screen is available to view all variations:

```dart
import 'package:vibzcheck/src/widgets/profile_avatar_demo.dart';

// Navigate to demo
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfileAvatarDemo()),
);
```

The demo showcases:
- All size variations
- All online status options
- Spotify vs Guest styling
- With/without borders
- Interactive tap example
- Real-world usage examples

## Accessibility

The component includes:
- Proper contrast ratios for text and icons
- Clear visual distinction between user types
- Meaningful color choices for status indicators
- Tap target size follows Material Design guidelines (minimum 48x48 for interactive elements)

## Performance

- **Cached Network Images:** Consider adding `cached_network_image` package for better performance
- **Lazy Loading:** Images load asynchronously
- **Error Handling:** No crashes on missing/invalid images
- **Lightweight:** Minimal widget tree depth

## Future Enhancements

Potential improvements:
- [ ] Add badge/indicator for hosts
- [ ] Support for group avatars (overlapping circles)
- [ ] Animation on status change
- [ ] Custom shapes (rounded square, hexagon)
- [ ] Verified badge for premium users
- [ ] Last seen timestamp tooltip

## Files

- **Component:** `lib/src/widgets/profile_avatar.dart`
- **Demo:** `lib/src/widgets/profile_avatar_demo.dart`
- **Documentation:** `PROFILE_AVATAR_COMPONENT.md`

## Summary

✅ Production-ready profile avatar component
✅ Supports Spotify and Guest users
✅ Multiple sizes with responsive scaling
✅ Online status indicators
✅ Image loading with fallbacks
✅ Tap interactions
✅ Comprehensive demo screen
✅ Fully documented

The ProfileAvatar component is ready to use throughout the app for consistent, beautiful user representation! 🎉
