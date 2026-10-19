/// Web-compatible shim for the `path_provider` package.
///
/// `path_provider` has no web implementation, so on web every directory
/// lookup returns `null`. All callers already handle `null` by showing an
/// error message and returning, which is exactly the desired behavior for
/// the file-based features that are disabled on web (export, backup,
/// media, voice notes, ...).
///
/// The same four functions are provided on both targets:
///  - native: [app_dirs_native.dart] (delegates to path_provider)
///  - web:    [app_dirs_web.dart] (returns null)
library;

export 'app_dirs_native.dart' if (dart.library.js_interop) 'app_dirs_web.dart';
