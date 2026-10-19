/// Native implementation of [app_dirs.dart]: delegates to path_provider.
///
/// Signatures mirror path_provider exactly: only
/// [getExternalStorageDirectory] is nullable.
library;

import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart' as pp;

Future<Directory?> getExternalStorageDirectory() =>
    pp.getExternalStorageDirectory();

Future<Directory> getApplicationDocumentsDirectory() async =>
    pp.getApplicationDocumentsDirectory();

Future<Directory> getApplicationSupportDirectory() async =>
    pp.getApplicationSupportDirectory();

Future<Directory> getTemporaryDirectory() async => pp.getTemporaryDirectory();
