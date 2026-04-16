# MyKOG - Architecture Plan
## Spiritual Audio Streaming App (Spotify + Apple Music Inspired)

### 🎯 Core Features
1. **Home Screen** - Personalized recommendations, daily verse, recent teachings
2. **Browse/Discover** - Categories, popular teachings, featured content  
3. **Teachings Library** - Full audio teachings collection with search
4. **Audio Player** - Immersive full-screen player with animations
5. **Profile** - User preferences, downloads, favorites

### 🎨 Design System
- **Color Palette**: Dark theme with gold accents (Spotify black + Apple Music elegance)
- **Typography**: Poppins (Spotify style) + Inter (Apple Music style)  
- **Components**: Glassmorphism effects, animated covers, mini player
- **Navigation**: Bottom tabs with smooth transitions

### 📁 Project Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── user.dart
│   ├── teaching.dart
│   └── playlist.dart
├── services/
│   ├── audio_service.dart
│   ├── teaching_service.dart
│   ├── user_service.dart
│   └── storage_service.dart
├── providers/
│   ├── audio_player_provider.dart
│   └── user_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── browse_screen.dart
│   ├── teachings_screen.dart
│   ├── audio_player_screen.dart
│   └── profile_screen.dart
├── widgets/
│   ├── glass_card.dart
│   ├── cover_flow_list.dart
│   ├── mini_player.dart
│   ├── teaching_tile.dart
│   └── custom_bottom_nav.dart
└── utils/
    └── constants.dart
```

### 🔧 Technical Implementation
- **State Management**: Provider pattern
- **Audio**: just_audio for playback
- **Storage**: SharedPreferences for local data
- **Images**: cached_network_image with fallbacks
- **Animations**: flutter_animate for smooth transitions

### 📱 Screen Hierarchy
1. **MainApp** (CupertinoTabScaffold)
   - Home Tab → HomeScreen
   - Browse Tab → BrowseScreen  
   - Library Tab → TeachingsScreen
   - Profile Tab → ProfileScreen
2. **AudioPlayerScreen** (Modal overlay)
3. **MiniPlayer** (Persistent bottom widget)

### 🎵 Audio Features
- Background playback
- Seek controls (±15s)
- Progress tracking
- Queue management
- Shuffle/Repeat modes
- Like/Favorite system

### 💾 Data Models
- **User**: Profile, preferences, listening history
- **Teaching**: Title, speaker, duration, artwork, audio URL
- **Playlist**: Custom collections, favorites, recently played

### 🎯 Next Steps
1. Create theme with dark/gold color scheme
2. Implement data models and services
3. Build main navigation structure  
4. Create core screens
5. Implement audio player functionality
6. Add animations and polish
7. Test and debug