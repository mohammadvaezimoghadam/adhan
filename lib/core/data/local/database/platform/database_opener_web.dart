import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory? _webDbFactory;

Future<Database> openQuranDatabase({
  required String dbName,
  required String assetDbPath,
}) async {
  debugPrint('⚡ [Web Database] Bypassing asset $assetDbPath load on Web to save 8.5MB host bandwidth.');
  try {
    if (_webDbFactory == null) {
      final options = SqfliteFfiWebOptions(
        sharedWorkerUri: Uri.parse('sqflite_sw.js'),
        // ignore: invalid_use_of_visible_for_testing_member
        forceAsBasicWorker: true,
      );
      _webDbFactory = createDatabaseFactoryFfiWeb(options: options);
      databaseFactory = _webDbFactory!;
    }
    final factory = _webDbFactory!;
    // Open in-memory or empty web database without transferring the 8.5MB asset
    final db = await factory.openDatabase(inMemoryDatabasePath);
    return db;
  } catch (e, st) {
    debugPrint('⚠️ [Web Database Warning] $e\n$st');
    rethrow;
  }
}
