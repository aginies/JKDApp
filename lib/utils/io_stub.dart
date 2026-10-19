/// Web stubs for the `dart:io` APIs used by this app.
///
/// On web, `kIsWeb` is true and all platform-only features (file export,
/// backup, media, TTS, Garmin, ...) are disabled in the UI. These stubs
/// keep the library compiling for the web target and make any accidental
/// call fail gracefully with a clear [UnsupportedError] (caught by the
/// existing try/catch blocks) instead of a compile error or a crash.
library;

/// Minimal stand-in for `dart:io`'s [Platform].
///
/// Only the members used by the app are provided. On web every
/// operating-system flag is false, which is the correct behavior.
class Platform {
  Platform._();

  static const String operatingSystem = 'web';
  static const String localeName = 'en';

  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isFuchsia => false;
}

/// Minimal stand-in for `dart:io`'s [FileSystemEntity].
class FileSystemEntity {
  FileSystemEntity(this.path);

  final String path;

  bool get isFile => false;
  bool get isDirectory => false;
}

/// Minimal stand-in for `dart:io`'s [File].
///
/// Reads report "does not exist"; writes and other operations throw
/// [UnsupportedError], which callers already handle with try/catch.
class File extends FileSystemEntity {
  File(super.path);

  Never _unsupported() =>
      throw UnsupportedError('dart:io File is not available on web: $path');

  @override
  bool get isFile => true;

  Uri get uri => Uri.parse(path);

  Future<bool> exists() async => false;
  Future<void> writeAsString(String contents, {bool flush = false}) =>
      _unsupported();
  Future<void> writeAsBytes(List<int> bytes, {bool flush = false}) =>
      _unsupported();
  Future<String> readAsString() => _unsupported();
  Future<List<int>> readAsBytes() => _unsupported();
  Future<void> create({bool recursive = false}) => _unsupported();
  Future<void> delete() => _unsupported();
  Future<File> copy(String newPath) => _unsupported();
  Future<int> length() => _unsupported();
}

/// Minimal stand-in for `dart:io`'s [Directory].
class Directory extends FileSystemEntity {
  Directory(super.path);

  Never _unsupported() => throw UnsupportedError(
    'dart:io Directory is not available on web: $path',
  );

  @override
  bool get isDirectory => true;

  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) => _unsupported();
  Future<void> delete({bool recursive = false}) => _unsupported();
  // Matches dart:io: list() is a Stream (callers use .toList() / await for).
  Stream<FileSystemEntity> list({bool recursive = false}) =>
      const Stream.empty();
  List<FileSystemEntity> listSync({bool recursive = false}) => const [];
}

/// Minimal stand-in for `dart:io`'s [Process].
///
/// Only used by the Linux spd-say TTS path, which is never reached on web.
class Process {
  static Future<void> _unsupported() =>
      throw UnsupportedError('dart:io Process is not available on web');

  static Future<void> run(String executable, List<String> args) =>
      _unsupported();
}
