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
- **Media Gallery**: Attach instructional photos to techniques
- **PDF Export**: Generate printable training sheets
- **Import/Export**: Backup and restore series in JSON format
- **Glossary Backup**: Export/import the entire technique database
- **Media Backup**: ZIP backup/restore for instructional photos

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
- **series**: Training series metadata
- **glossary**: Technique database with translations
- **voice_records**: Voice note recordings (future feature)

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

## Recent Refactoring (2025)

The series detail screen has been refactored from a monolithic 2,232-line file into modular components:
- **25.5% code reduction** (1,662 lines)
- **Separated concerns**: Dialogs, widgets, and controllers
- **Improved maintainability**: Easier to test and extend
- **Preserved functionality**: All features working as before

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
