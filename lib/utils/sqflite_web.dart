/// Web sqflite setup (sqlite3 compiled to WASM, persisted in IndexedDB).
///
/// Requires `sqlite3.wasm` and `sqflite_sw.js` in the web/ folder
/// (generated with `dart run sqflite_common_ffi_web:setup`).
library;

import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi;

void initSqfliteFfi() {
  // The WASM factory lazily loads its binaries; nothing to do here.
}

DatabaseFactory get databaseFactoryFfi => ffi.databaseFactoryFfiWeb;
