# JKD App - Jeet Kune Do Notes

A comprehensive Flutter application for managing Jeet Kune Do training series, techniques, and combinations.

## Features

### Core Functionality
- **Series Management**: Create and organize training series for Jun Fan Gung Fu and Jun Fan Kick Boxing
- **Move Glossary**: Extensive database of punches, kicks, packs, trapping techniques, and special moves
- **Combo Builder**: Visual interface to build complex attack/defense combinations
- **Training Mode**: Text-to-speech guided training with configurable intervals and looping
- **Voice Recognition**: Speech-to-text input for hands-free combo creation (Android/iOS only)
- **Multi-language**: Full support for English and French

### Advanced Features
- **Counter Moves**: Add defensive responses to attacks
- **Attack Methods**: SDA, PIA, SIA, BTAA, ABD, ABC
- **Media Gallery**: Attach instructional photos to techniques (take photo or select from files, auto-resized to 500px with 75% JPG compression)
- **PDF Export**: Generate printable training sheets
- **Import/Export**: Backup and restore series in JSON format
- **Glossary Backup**: Export/import the entire technique database
- **Media Backup**: ZIP backup/restore for instructional photos
- **Auto-Load Series**: Automatically loads trusted series from assets on first launch

## Project Structure

```
lib/
├── models/              # Data models (Move, Series)
├── services/            # Business logic and APIs
│   ├── database_service.dart
│   ├── voice_parsing_service.dart
│   ├── localization_service.dart
│   ├── export_service.dart
│   └── ...
├── screens/
│   ├── series_list_screen.dart
│   ├── settings_screen.dart
│   └── series_detail/   # Refactored series detail screen
│       ├── series_detail_screen.dart (main screen)
│       ├── dialogs/     # Modal dialogs
│       │   ├── voice_help_dialog.dart
│       │   ├── voice_input_dialog.dart
│       │   └── training_options_dialog.dart
│       ├── widgets/     # Reusable UI components
│       │   ├── move_display_widgets.dart
│       │   └── marquee_widget.dart
│       └── controllers/ # Business logic controllers
│           └── training_controller.dart
└── main.dart
```

## Series Files Management

### Automatic Series Loading

The app automatically loads all series files from the `assets/` directory on first launch. These are trusted system series that seed the database.

**How it works:**
1. Series files follow the naming pattern: `jkd-series-*.json`
2. All files listed in `lib/services/database_service.dart` (`_seriesFiles` array) are loaded automatically
3. Files are loaded during database initialization
4. All series are marked as system series (`is_system: 1`)

**Adding a New Series File:**
1. Create your series JSON file (e.g., `jkd-series-kicks.json`) in the `assets/` directory
2. Add the filename to the `_seriesFiles` list in `lib/services/database_service.dart`:
   ```dart
   static const List<String> _seriesFiles = [
     'assets/jkd-series-punches.json',
     'assets/jkd-series-4-counts.json',
     'assets/jkd-series-kicks.json',  // Add your new file here
   ];
   ```
3. The series will be automatically loaded on next database reset

**Series File Format:**
```json
[
  {
    "title": "Series Name",
    "category": "Jun Fan Gung Fu",
    "type": "Attack",
    "attack_method": "SDA",
    "notes": "Description",
    "is_system": 1,
    "moves": [
      {
        "name": "Jab",
        "category": "punch",
        "side": "L",
        "level": "High",
        "repetitions": 1,
        "sub_moves_json": null
      }
    ]
  }
]
```

**Note:** The glossary file (`assets/jkd-glossary.json`) contains all available techniques and is loaded separately.

## Voice Recognition

### Supported Platforms
- ✅ Android
- ✅ iOS
- ❌ Linux (disabled in settings)

### Voice Commands

**English Keywords:**
- **Sides**: left, right
- **Levels**: high, mid, middle, low
- **Chain moves**: next, then
- **Counters**: answer, counter

**French Keywords:**
- **Sides**: gauche, droite, droit
- **Levels**: haut, milieu, centre, bas
- **Chain moves**: suivant, ensuite, puis, et
- **Counters**: réponse, contre

**Examples:**
```
"left jab high" → Left jab at high level
"right cross then left hook" → Combo: right cross + left hook
"jab answer pak sao" → Jab with pak sao counter
```

### Voice Recognition Settings
The matching threshold is set to 0.3 for better speech recognition accuracy. Voice input can be toggled in Settings and is only available on supported platforms.

## Training Mode

Training mode reads each move aloud with configurable settings:
- **Start/End Index**: Choose which moves to practice
- **Interval**: 3-20 seconds between moves
- **Loop**: Repeat the sequence continuously
- **Language**: TTS in English or French

## Database Schema

The app uses SQLite for local storage:
- **series**: Training series metadata (user-created + auto-loaded system series)
- **series_moves**: Individual moves within series, including combos with sub_moves_json
- **glossary**: Technique database with translations (auto-loaded from `jkd-glossary.json`)
- **voice_records**: Voice note recordings (future feature)

**Initialization:**
- On first launch, the database is seeded with:
  - All techniques from `assets/jkd-glossary.json`
  - All series from files listed in `DatabaseService._seriesFiles`
- System series are marked with `is_system: 1` and appear in the library alongside user-created series

## Development

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Dependencies
Key packages:
- `sqflite`: Local database
- `provider`: State management
- `speech_to_text`: Voice input
- `flutter_tts`: Text-to-speech
- `pdf`: PDF generation
- `string_similarity`: Voice command matching

### Building
```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Recent Updates (2025)

### Code Refactoring
The series detail screen has been refactored from a monolithic 2,232-line file into modular components:
- **25.5% code reduction** (1,662 lines)
- **Separated concerns**: Dialogs, widgets, and controllers
- **Improved maintainability**: Easier to test and extend
- **Preserved functionality**: All features working as before

### Feature Enhancements
- **Auto-Load Series**: System automatically loads all `jkd-series-*.json` files from assets
- **Media Gallery Improvements**:
  - Added file picker to select photos from device (alongside camera capture)
  - Auto-resize images to 500px width with 75% JPG compression
  - Swipe navigation between photos in full-screen view
  - Pinch-to-zoom support
- **UI Improvements**:
  - Simplified app title to "JKD" in top bar
  - Repositioned floating action buttons to divider line in edit mode
  - Improved item scrolling: centers selected items in viewport
  - Increased left padding for better visibility of item numbers
  - Removed label clutter in edit mode (Category, Type, Method labels)
  - Left-aligned chips for consistent layout

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅ Full | All features supported |
| iOS      | ✅ Full | All features supported |
| Linux    | ⚠️ Partial | Voice recognition disabled, TTS uses `spd-say` |
| Web      | ❓ Untested | May require adjustments |

## Localization

The app supports:
- **English** (en)
- **French** (fr)

Translations are managed in `lib/services/localization_service.dart`.

## License

[Add your license here]

## Contributors

[Add contributors here]

## Version

Current version: 1.0
