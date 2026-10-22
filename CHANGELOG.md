# Changelog

All notable changes to the JKD App are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-10-22

### Security
- Blocked public access to the PHP application logs and backup files in the Apache config, with an additional deny-all `php_site/logs/.htaccess` for defence in depth.
- Moved rate-limiting and brute-force state out of `/tmp` into a private cache directory.
- Sanitized uploaded filenames against multi-extension execution (e.g. `payload.php.json`).
- Added strict JSON schema validation in `api.php` and safe type handling in `preview.php`.
- Admin logout now requires POST with a CSRF token, and failed-login log lines are sanitized.
- Escaped HTML in `share_http.py` to prevent stored/reflected XSS.
- Added `web/.htaccess` for the WASM build: WASM MIME types, COOP/COEP cross-origin isolation, and a Content-Security-Policy.
- `WebStorageService._safeFilenamePart` now also strips dots, so a client-supplied name cannot forge secondary script extensions.

### Fixed
- `<Directory>` is not permitted in an `.htaccess` context and caused an HTTP 500; replaced with `RewriteRule ^logs(/|$) - [F,L]`.

### Added
- Presentation deck `presentation/slides.md` with `build_slides.sh` and `build_slides_html.sh` exporters.

### Changed
- The `build_web` target in `build_and_verify.sh` now forwards `--dart-define=APP_SECRET=...` when the environment variable is set.

## [3.0.0] - 2026-10-19

### Security
- Fixed zip-slip path traversal when restoring backup and media ZIP archives (archive entry names are now validated before extraction).
- Removed the hardcoded app secret from the Flutter client; it is now injected at build time via `--dart-define=APP_SECRET=...`.
- Added `php_site/secrets.php` to `.gitignore` and rotated `APP_SECRET`, `TOKEN_SIGNING_KEY`, and the admin password.
- Hardened upload filename sanitization (NUL/control characters and leading dots) and token validation (future-dated timestamps are now rejected).

### Added
- Text-to-speech for training mode and warmup now works in the web app.

### Changed
- Moved the PHP web backend from `web/` to `php_site/`.
- Upgraded `file_picker` 10→13, `permission_handler` 12→13, `record` 6→7, `share_plus` 12→13, `video_player` →2.14, and other dependencies; migrated the `file_picker` API (`FilePickerResult` → `List<PlatformFile>`, static `FilePicker.*`).
- Added a `build_web` target to `build_and_verify.sh` and included it in the `all` pipeline.

## [2.8.1] - 2026-10-07

### Fixed
- Reorderable list: migrated from deprecated `onReorder` to `onReorderItem` (Flutter 3.42+), removing the manual index correction.
- Wear OS app: assets and privacy policy are now committed, so fresh checkouts analyze and build cleanly.

### Changed
- CI: `flutter analyze` no longer analyzes the nested Wear OS project (local-only build).

## [2.8.0] - 2026-10-07

### Added
- Glossary: missing JKD concepts (Chi, Jeet Da/Que/Sao, Lai Sao, Ha/Jun/Go Da).
- Series: "24 Coups de poings" completed — 2 overhead moves added (arrière L, avant R) and series renamed from 22 to 24 Coups de poings.
- Training programs: translated into French.

### Changed
- Series data: "24 Coups de poings" moved to a dedicated asset file (`jkd-series-24-coups-de-poings.json`); Garmin `JKDSeries.mc` regenerated accordingly.

## [2.7.0] - 2026-10-04

### Added
- **5 Ways of Attack**: new glossary category and tab (placed before "General") covering the five attack methods — Simple Angled Attack (SAA), Immobilization Attack (IA/HIA), Progressive Indirect Attack (PIA), Attack by Combination (ABC) and Attack by Drawing (ABD) — with English and French definitions.
- Media: live video recording, plus photo/video icons on glossary items.
- Media: tabbed media gallery with video support.
- Series detail: card view shown by default.

### Changed
- Combo editor labels (Answer / Simultaneous / Chain) are now translated.
- README is now in French; the English version moved to `README.en.md`.

### Fixed
- Warmup crash, TTS deadlock, HR bar, angle text and small-screen list layout.
- Combo-builder: counter editing bugs.
- Camera crash on Linux.
- Floating SnackBar presented off-screen on the series list.
- Various small fixes.

### Refactored
- Combo-builder: extracted move converter and workspace controller.
- Enforced layering: no `screens/` imports in `widgets/` and `services/`.

### Security
- Removed an exposed Garmin developer key from the repository.

### Documentation
- `AGENTS.md`: raised the max file size limit from 1,000 to 1,500 lines.
