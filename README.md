# JKD App - Jeet Kune Do Notes

A comprehensive Flutter application for managing Jeet Kune Do training series, techniques, and combinations.

## Features

### Core Functionality
- **Series Management**: Create and organize training series for Jun Fan Gung Fu, Jun Fan Kick Boxing, and **JKD Moves** (Footwork).
- **Move Glossary**: Extensive database of punches, kicks, packs, trapping, and specialized JKD movements.
- **Combo Builder**: Visual interface to build complex combinations with support for **sub-numbering** (e.g., 1a, 1b, 1c).
- **Training Mode**: Text-to-speech guided training with configurable intervals and looping.
- **Training Programs**: Structured multi-day training regimens with progress tracking, daily assignments, and completion statistics.
- **Multi-language**: Full support for English and French.

### Advanced Features
- **Wearable Support**: Dedicated companion apps for **Wear OS** and **Garmin** watches.
- **Theme Personalization**: Choose your own **Theme Color** from a wide palette (Blue, Red, Green, etc.).
- **Adaptive UI**: Interface elements automatically adjust colors for maximum readability in Light, Dark, and AMOLED modes.
- **Counter Moves**: Add defensive responses to attacks with automatic tab navigation during editing.
- **Media Gallery**: Attach instructional photos to techniques with auto-compression and swipe navigation.
- **Integrated Logging**: Multi-level logging system (INFO, WARN, ERROR) with in-app viewer and export/share capabilities for easier troubleshooting.
- **PDF Export**: Generate printable training sheets.
- **Backup & Restore**: Full support for Series, Glossary, and Media (ZIP) backups.
- **Cloud Library**: Share and download community-contributed training series via the integrated web service.

## Web Cloud Storage

The project includes a full PHP-based web backend and interface located in the `/web` directory:
- **Central Repository**: A cloud-based library for discovering and sharing JKD training series.
- **Web Interface**: Browse, search, and preview series content directly in any web browser.
- **REST API**: Seamless integration with the mobile app for automated uploads and downloads.
- **Admin Tools**: Built-in moderation and content management tools.
- **Logging & Debugging**: Centralized logging of all API requests, uploads, and administrative actions in `web/logs/app.log`.

## Wearable Extensions

### Wear OS App
A fully native companion app designed for hands-free training on watches like the Samsung Galaxy Watch 6 or Pixel Watch:
- **Bubble Layout**: Each action step is displayed in its own clearly defined, color-coded bubble.
- **Smart Formatting**: Automatically converts complex chains (e.g., "L Jab -> R Cross") into a vertical, easy-to-read flow.
- **Auto-Advance**: Configurable timer (2s to 30s) allows you to train without touching the watch.
- **Visual Countdown**: A circular border gradient (Red -> Yellow -> Green) provides a real-time progress cue.
- **Dual-Column Mode**: Automatically switches between 1 and 2 columns based on move length to maximize screen space.
- **Auto-Scrolling**: Seamlessly loops long descriptions up and down so you never miss a detail.

### Garmin ConnectIQ
Integrates with Garmin watches (Fenix, Forerunner, etc.) via the Garmin SDK:
- **Remote Sync**: Synchronizes current training series and progress to the watch face.
- **Audio Feedback**: Works in tandem with the phone's TTS engine for a unified coaching experience.

## Project Structure

```
.
├── garmin_app/          # Garmin ConnectIQ source code (Monkey C)
├── wear_os_app/         # Native Wear OS Flutter application
├── web/                 # PHP Backend and Web Interface for Cloud Storage
├── lib/                 # Main Mobile/Desktop application source
│   ├── models/          # Data models (Move, JkdSeries)
│   ├── services/        # Business logic (DB, Garmin Sync, Hashing)
│   ├── screens/         # UI Screens
│   └── ...
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
| Wear OS  | ✅ Full | Native app for Watch 4/5/6/7, Pixel Watch, etc. |
| Garmin   | ✅ Full | ConnectIQ extension for compatible Garmin devices |
| Windows  | ✅ Full | Fully supported desktop platform |
| MacOS    | ✅ Full | Fully supported desktop platform |
| Linux    | ⚠️ Partial | Voice recognition disabled, TTS uses `spd-say` |
| iOS      | ⚠️ Limited | Supported by code but not officially built |

## Recent Updates (v2.2.0+1)

- **Wear OS Launch**: Complete standalone watch application with Bubble Layout.
- **Garmin Extension**: Remote synchronization support for Garmin devices.
- **Automated Updates**: System series and glossary now update automatically via asset hashing (no reset required).
- **Personal Backups**: Added option to export only custom (non-system) series.
- **Database v13**: Added `sub_letter` support and automatic system series re-seeding.

## Development

### Building
```bash
flutter pub get
flutter run
```

## Contributors
- **Antoine Giniès** (Author & Lead Developer)
