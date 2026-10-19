/// Native sqflite setup (sqlite3 via FFI).
library;

import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

void initSqfliteFfi() => ffi.sqfliteFfiInit();

DatabaseFactory get databaseFactoryFfi => ffi.databaseFactoryFfi;
