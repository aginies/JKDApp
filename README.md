# JKD App - Jeet Kune Do Notes

A comprehensive Flutter application for managing Jeet Kune Do training series, techniques, and combinations.

## Features

### Core Functionality
- **Series Management**: Create and organize training series for Jun Fan Gung Fu, Jun Fan Kick Boxing, and **JKD Moves** (Footwork).
- **Move Glossary**: Extensive database of punches, kicks, packs, trapping, and specialized JKD movements.
- **Combo Builder**: Visual interface to build complex combinations with support for **sub-numbering** (e.g., 1a, 1b, 1c).
- **Training Mode**: Text-to-speech guided training with configurable intervals and looping.
- **Random Reader**: Specialized training tool for JKD Footwork that calls out moves randomly within a selected series.
- **Multi-language**: Full support for English and French.

### Advanced Features
- **Theme Personalization**: Choose your own **Theme Color** from a wide palette (Blue, Red, Green, etc.).
- **Adaptive UI**: Interface elements automatically adjust colors for maximum readability in Light, Dark, and AMOLED modes.
- **Counter Moves**: Add defensive responses to attacks with automatic tab navigation during editing.
- **Media Gallery**: Attach instructional photos to techniques with auto-compression and swipe navigation.
- **Integrated Logging**: View and save application logs directly from settings for troubleshooting.
- **PDF Export**: Generate printable training sheets.
- **Backup & Restore**: Full support for Series, Glossary, and Media (ZIP) backups.

## Project Structure

```
lib/
├── models/              # Data models (Move, JkdSeries)
├── services/            # Business logic and APIs
│   ├── database_service.dart   # SQLite management (Current Version: 13)
│   ├── series_provider.dart     # State & Settings provider
│   ├── logging_service.dart     # App event tracking
│   ├── localization_service.dart
│   └── ...
├── screens/
│   ├── series_list_screen.dart  # Main dashboard with Categories
│   ├── settings_screen.dart     # App configuration & Theme chooser
│   ├── series_list/
│   │   └── widgets/
│   │       └── random_reader_widget.dart  # Footwork training tool
│   └── series_detail/
│       ├── widgets/
│       │   └── move_list_display_widget.dart # Hierarchical list with sub-letters
│       └── ...
└── utils/               # Utility classes (Category, Translation, etc.)
```

## JKD Footwork Training (Random Reader)

The **Random Reader** is a specialized tool found in the "JKD Moves" tab. It is designed for reactive footwork drills:
1. **Sequence**: It announces the Series name (in English) once, waits 1s, and then calls out move numbers (1-6) in the selected language.
2. **Configuration**:
   - **Series Selection**: Choose specific footwork patterns (Step and Slide, Pendulum, etc.).
   - **Guard**: Toggle between Left and Right guard.
   - **Delay**: Adjustable timing from 0.4s to 2.5s for progressive speed training.
3. **Visuals**: A prominent display shows the current move in large text for quick reference.

## Sub-Numbering System (Hierarchy)

You can now group variations of a move using letters (a, b, c...):
- **Visual Grouping**: Sub-items are automatically indented to the right.
- **Clean Numbering**: The main sequence number is displayed once at the top of the group, with large yellow letters indicating the sub-variation.
- **Rhythmic Training**: The training mode and random reader respect this hierarchy for a more natural flow.

## Personalization & Display

- **Theme Color**: Change the app's primary accent color in Settings.
- **AMOLED Support**: Optimized "True Black" mode for OLED screens.
- **Adaptive Tabs**: Tab titles dynamically switch between White (Dark/AMOLED) and Primary color (Light) for perfect contrast.
- **Visual Loading**: The JKD logo in the top bar rotates while the database is initializing or loading data.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅ Full | Primary mobile platform support |
| Windows  | ✅ Full | Fully supported desktop platform |
| MacOS    | ✅ Full | Fully supported desktop platform |
| Linux    | ⚠️ Partial | Voice recognition disabled, TTS uses `spd-say` |
| iOS      | ⚠️ Limited | Supported by code but not officially built (Apple Developer account) |

## Recent Updates (v1.8.0)

- **Database v13**: Added `sub_letter` support and automatic system series re-seeding.
- **Improved Logging**: Logs now include versioning and timestamps, saveable as `jkd_app-VERSION-DATE-HOUR.log`.
- **Glossary Overhaul**: Improved readability in dark themes and fixed missing category icons.
- **Default Theme**: Switched default app color to **Blue**.
- **Refined Detail View**: Simplified labels and improved scrolling behavior for long series.

## Development

### Building
```bash
flutter pub get
flutter run
```

## Contributors
- **Antoine Giniès** (Author & Lead Developer)
