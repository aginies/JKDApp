/// Conditional export of `dart:io` (native) or [io_stub] (web).
///
/// Import this instead of `dart:io` so the same source compiles for both
/// targets. The stub provides the same API surface for the members the
/// app uses (Platform flags, File, Directory, Process).
library;

export 'dart:io' if (dart.library.js_interop) 'io_stub.dart';
