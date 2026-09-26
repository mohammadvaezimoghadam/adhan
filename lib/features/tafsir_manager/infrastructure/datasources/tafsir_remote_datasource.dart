import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/data/remote/network_service.dart';

abstract class ITafsirRemoteDataSource {
  Future<String> downloadAndSaveTafsir(
    String tafsirId,
    String sourceUrl, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  });
}

/// Top-level function executed in a clean isolate without capturing any outer context or closures
void _extractArchiveWorker(List<String> paths) {
  final archivePath = paths[0];
  final outDbPath = paths[1];

  final dir = Directory(dirname(outDbPath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final bytes = File(archivePath).readAsBytesSync();
  final tarBytes = XZDecoder().decodeBytes(bytes);
  final archive = TarDecoder().decodeBytes(tarBytes);
  for (final file in archive) {
    if (file.isFile && file.name.endsWith('.db')) {
      final outFile = File(outDbPath);
      if (outFile.existsSync()) {
        outFile.deleteSync();
      }
      outFile.writeAsBytesSync(file.content as List<int>, flush: true);
      return;
    }
  }
  throw Exception('هیچ فایل پایگاه داده‌ای (.db) در آرشیو یافت نشد.');
}

class TafsirRemoteDataSource implements ITafsirRemoteDataSource {
  final Dio _dio;

  TafsirRemoteDataSource(this._dio);

  @override
  Future<String> downloadAndSaveTafsir(
    String tafsirId,
    String sourceUrl, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final databasesDir = await getDatabasesPath();
    final cleanId = tafsirId.replaceAll('.', '_');

    final tempTarPath = join(tempDir.path, 'tafsir_$cleanId.tar.xz');
    final permanentDbPath = join(databasesDir, 'tafsir_$cleanId.db');

    final tempTarFile = File(tempTarPath);

    debugPrint('🚀 [Tafsir] Starting direct download for $tafsirId from $sourceUrl');

    try {
      if (tempTarFile.existsSync()) {
        try {
          tempTarFile.deleteSync();
        } catch (_) {}
      }

      // 1. Download .tar.xz archive (progress 0% -> 90%)
      await _dio.download(
        sourceUrl,
        tempTarPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onReceiveProgress != null) {
            onReceiveProgress((received * 0.90).toInt(), total);
          } else {
            onReceiveProgress?.call(received, total);
          }
        },
        cancelToken: cancelToken,
      );

      debugPrint('📦 [Tafsir] Download complete (${tempTarFile.lengthSync()} bytes). Extracting to $permanentDbPath...');

      // 2. Extract SQLite db directly into permanent databases folder via worker isolate
      await compute(_extractArchiveWorker, [tempTarPath, permanentDbPath]);

      onReceiveProgress?.call(100, 100);
      debugPrint('✅ [Tafsir] Database ready at $permanentDbPath (${File(permanentDbPath).lengthSync()} bytes).');

      return permanentDbPath;
    } catch (e, stackTrace) {
      debugPrint('❌ [Tafsir] downloadAndSaveTafsir failed: $e\n$stackTrace');
      rethrow;
    } finally {
      // 3. Clean up temporary archive file immediately
      if (tempTarFile.existsSync()) {
        try {
          tempTarFile.deleteSync();
        } catch (_) {}
      }
    }
  }
}

final tafsirRemoteDataSourceProvider = Provider<ITafsirRemoteDataSource>((ref) {
  final dio = ref.watch(networkServiceProvider);
  return TafsirRemoteDataSource(dio);
});
