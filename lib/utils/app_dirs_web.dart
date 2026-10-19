/// Web implementation of [app_dirs.dart]: no filesystem.
///
/// [getExternalStorageDirectory] returns `null` (callers show an error and
/// abort, which is the desired behavior for the file-based features that
/// are disabled on web).
///
/// The other three return a stub [io.Directory] with a fake path, matching
/// path_provider's non-nullable signatures. Building path strings from it
/// is harmless; any actual file operation on it throws [UnsupportedError],
/// which the existing try/catch blocks in the callers already handle.
library;

import 'io_stub.dart' as io;

const _unsupportedRoot = '/web/unsupported';

Future<io.Directory?> getExternalStorageDirectory() async => null;

Future<io.Directory> getApplicationDocumentsDirectory() async =>
    io.Directory('$_unsupportedRoot/Documents');

Future<io.Directory> getApplicationSupportDirectory() async =>
    io.Directory('$_unsupportedRoot/Support');

Future<io.Directory> getTemporaryDirectory() async =>
    io.Directory('$_unsupportedRoot/tmp');
