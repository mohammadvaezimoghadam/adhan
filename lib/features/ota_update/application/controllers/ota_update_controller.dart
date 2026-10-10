import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../core/services/downloader/adapters/http_adapter.dart';
import '../../domain/entities/ota_patch.dart';
import 'ota_update_state.dart';

final otaUpdateControllerProvider =
    NotifierProvider<OtaUpdateController, OtaUpdateState>(
  OtaUpdateController.new,
);

final hasOtaUpdateProvider = Provider<bool>((ref) {
  return ref.watch(otaUpdateControllerProvider.select((s) => s.hasUpdate));
});

final appVersionNameProvider = Provider<String>((ref) {
  final buildNumber = ref
      .watch(otaUpdateControllerProvider.select((s) => s.currentBuildNumber));
  if (buildNumber != null && buildNumber > 1) {
    return '۱.۰.${buildNumber - 1}';
  }
  return '۱.۰.۰';
});

final appVersionDisplayProvider = Provider<String>((ref) {
  final versionName = ref.watch(appVersionNameProvider);
  final currentPatch = ref.watch(
      otaUpdateControllerProvider.select((s) => s.currentPatchVersion));
  if (currentPatch != null && currentPatch.isNotEmpty) {
    return 'نسخه $versionName (پچ فعال: $currentPatch)';
  }
  return 'نسخه $versionName';
});

class OtaUpdateController extends Notifier<OtaUpdateState> {
  late final Dio _dio;
  StreamSubscription<PatchApplyProgress>? _progressSubscription;

  @override
  OtaUpdateState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.patchServerBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Bypasses system proxies and deep packet inspection for local/docker hosts
    configureHttpClientAdapter(_dio);

    // Detailed network logging for all OTA requests and responses
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('📡 [Dio/OTA] $obj'),
      ),
    );

    ref.onDispose(() {
      _progressSubscription?.cancel();
    });

    _loadInitialPatcherInfo();
    return const OtaUpdateState();
  }

  Future<void> _loadInitialPatcherInfo() async {
    try {
      final currentVersion = await FlutterPatcher.currentVersion;
      final buildNumber = await FlutterPatcher.appVersionCode;
      debugPrint(
        '🧩 [OTA/Init] FlutterPatcher loaded -> currentPatch: ${currentVersion ?? "none"}, appVersionCode: $buildNumber',
      );
      final prefs = await SharedPreferences.getInstance();
      final lastRecordedBuild = prefs.getInt('ota_recorded_build_code');
      String? savedNotes = prefs.getString('ota_last_release_notes');
      String? effectivePatch = currentVersion;

      // اگر کاربر APK جدیدتری نصب کرده باشد (بیلد افزایش یافته):
      if (buildNumber != null &&
          lastRecordedBuild != null &&
          buildNumber > lastRecordedBuild) {
        debugPrint(
          '🚀 [OTA/Init] Host APK upgraded ($lastRecordedBuild -> $buildNumber)! Invaliding old patch and notes.',
        );
        await prefs.remove('ota_last_release_notes');
        await prefs.remove('ota_last_patch_version');
        savedNotes = null;
        effectivePatch = null;
        try {
          await FlutterPatcher.rollback();
        } catch (_) {}
      }

      if (buildNumber != null) {
        await prefs.setInt('ota_recorded_build_code', buildNumber);
      }

      state = state.copyWith(
        currentPatchVersion: effectivePatch,
        currentBuildNumber: buildNumber,
        lastReleaseNotes: savedNotes,
      );
    } catch (e) {
      debugPrint('⚠️ [OTA/Init] Error reading patcher info: $e');
    }
  }

  /// Checks the backend patch server for any active updates.
  /// Returns `true` if a new patch is available.
  Future<bool> checkForUpdate({bool manual = false}) async {
    if (state.isDownloading) {
      debugPrint('⏳ [OTA/Check] Skipped: download is currently in progress.');
      return false;
    }

    state = state.copyWith(status: OtaStatus.checking, errorMessage: null);

    try {
      final currentPatch = await FlutterPatcher.currentVersion;
      final versionCode = await FlutterPatcher.appVersionCode;

      debugPrint('═══════════════════════════════════════════════════════════════');
      debugPrint('🔍 [OTA/Check] Initiating update check (manual: $manual)');
      debugPrint('   🌐 Server URL: ${AppConstants.patchServerBaseUrl}/check');
      debugPrint('   📦 App ID: ${AppConstants.patchAppId}');
      debugPrint('   🏷️ Version Code: $versionCode');
      debugPrint('   🧩 Current Patch: ${currentPatch ?? "none"}');
      debugPrint('═══════════════════════════════════════════════════════════════');

      final response = await _dio.get(
        '/check',
        queryParameters: {
          'app_id': AppConstants.patchAppId,
          'app_version_code': ?versionCode,
          if (currentPatch != null && currentPatch.isNotEmpty)
            'current_patch': currentPatch,
        },
      );

      final data = response.data;
      debugPrint('📥 [OTA/Check] Raw response data: $data');

      if (data is Map<String, dynamic> && data['has_update'] == true) {
        final patch = OtaPatch.fromJson(data);
        debugPrint('🎉 [OTA/Check] UPDATE AVAILABLE!');
        debugPrint('   Version: ${patch.version}');
        debugPrint('   Force Update: ${patch.isForce}');
        debugPrint('   Target Version Code: ${patch.targetVersionCode}');
        debugPrint('   Download URL: ${patch.downloadUrl}');
        debugPrint('   MD5: ${patch.md5}');
        debugPrint('   Size: ${patch.sizeBytes} bytes');
        debugPrint('   Release Notes: ${patch.releaseNotes}');

        if (patch.releaseNotes.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ota_last_release_notes', patch.releaseNotes);
            await prefs.setString('ota_last_patch_version', patch.version);
          } catch (_) {}
        }

        state = state.copyWith(
          status: OtaStatus.updateAvailable,
          patch: patch,
          currentPatchVersion: currentPatch,
          currentBuildNumber: versionCode,
          lastReleaseNotes:
              patch.releaseNotes.isNotEmpty ? patch.releaseNotes : null,
        );

        // اگر پچ دارت اختیاری بود، دانلود در پس‌زمینه خودکار شروع شود
        if (!patch.isForce && !patch.isNativeApk) {
          debugPrint('⚡ [OTA/Silent] Starting silent background patch download...');
          unawaited(startDownloadAndApply());
        }

        return true;
      } else if (data is Map<String, dynamic> &&
          (data['action'] == 'rollback' || data['should_rollback'] == true)) {
        debugPrint('⚠️ [OTA/Rollback] Rollback instructed by server! Performing FlutterPatcher.rollback()...');
        try {
          await FlutterPatcher.rollback();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('ota_last_release_notes');
          await prefs.remove('ota_last_patch_version');
          await OtaUpdateController.restartApp();
        } catch (e) {
          debugPrint('❌ [OTA/Rollback] Failed to execute rollback: $e');
        }
        return true;
      } else {
        final message = (data is Map) ? data['message'] : null;
        debugPrint('✅ [OTA/Check] App is up to date. (Server message: $message)');
        final serverNotes = (data is Map &&
                data['release_notes'] is String &&
                (data['release_notes'] as String).isNotEmpty)
            ? data['release_notes'] as String
            : null;
        if (serverNotes != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ota_last_release_notes', serverNotes);
          } catch (_) {}
        }
        state = state.copyWith(
          status: OtaStatus.upToDate,
          patch: null,
          currentPatchVersion: currentPatch,
          currentBuildNumber: versionCode,
          lastReleaseNotes: serverNotes ?? state.lastReleaseNotes,
        );
        return false;
      }
    } catch (e, st) {
      debugPrint('❌ [OTA/Check] Update check failed with exception: $e');
      if (e is DioException) {
        debugPrint('   Type: ${e.type}');
        debugPrint('   Status Code: ${e.response?.statusCode}');
        debugPrint('   Response Data: ${e.response?.data}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   URI: ${e.requestOptions.uri}');
      } else {
        debugPrint('   StackTrace: $st');
      }

      state = state.copyWith(
        status: OtaStatus.error,
        errorMessage: 'خطا در بررسی به‌روزرسانی: $e',
      );
      return false;
    }
  }

  /// Starts downloading and installing the available patch.
  Future<bool> startDownloadAndApply() async {
    final patch = state.patch;
    if (patch == null || state.isDownloading) {
      debugPrint('⚠️ [OTA/Apply] Cannot start: patch is null or already downloading.');
      return false;
    }

    if (patch.isNativeApk) {
      debugPrint('🌐 [OTA/Native] Native APK update detected. Launching download URL: ${patch.downloadUrl}');
      try {
        final uri = Uri.parse(patch.downloadUrl);
        var launched = false;
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (_) {}
        }
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } catch (e) {
        debugPrint('⚠️ [OTA/Native] Failed to launch APK download URL: $e');
      }
      return true;
    }

    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint('⬇️ [OTA/Apply] Starting patch download & apply:');
    debugPrint('   Version: ${patch.version}');
    debugPrint('   URL: ${patch.downloadUrl}');
    debugPrint('   Target Code: ${patch.targetVersionCode}');
    debugPrint('   MD5: ${patch.md5}');
    debugPrint('   Size: ${patch.sizeBytes} bytes');
    debugPrint('═══════════════════════════════════════════════════════════════');

    state = state.copyWith(
      status: OtaStatus.downloading,
      progress: 0.0,
      bytesReceived: 0,
      totalBytes: patch.sizeBytes,
      errorMessage: null,
    );

    // Cancel previous stream subscription if any
    await _progressSubscription?.cancel();

    // Listen to download and installation progress
    _progressSubscription = FlutterPatcher.applyProgress.listen(
      (progressEvent) {
        final fraction = progressEvent.fraction ?? 0.0;
        final phase = progressEvent.phase;

        OtaStatus status = OtaStatus.downloading;
        if (phase == PatchApplyPhase.verifying) {
          status = OtaStatus.verifying;
        } else if (phase == PatchApplyPhase.finalizing) {
          status = OtaStatus.finalizing;
        }

        debugPrint(
          '⏳ [OTA/Progress] Phase: ${phase.name} | ${(fraction * 100).toStringAsFixed(1)}% '
          '(${progressEvent.bytesReceived}/${progressEvent.totalBytes > 0 ? progressEvent.totalBytes : patch.sizeBytes} bytes)',
        );

        state = state.copyWith(
          status: status,
          progress: fraction,
          bytesReceived: progressEvent.bytesReceived,
          totalBytes: progressEvent.totalBytes > 0
              ? progressEvent.totalBytes
              : patch.sizeBytes,
        );
      },
      onError: (err) {
        debugPrint('❌ [OTA/Progress] Stream error: $err');
      },
    );

    try {
      final patchInfo = PatchInfo(
        version: patch.version,
        patchUrl: patch.downloadUrl,
        md5: patch.md5,
        targetVersionCode: patch.targetVersionCode,
      );

      debugPrint('⚙️ [OTA/Apply] Invoking FlutterPatcher.applyPatch()...');
      final result = await FlutterPatcher.applyPatch(patchInfo);
      await _progressSubscription?.cancel();

      debugPrint('📦 [OTA/Apply] FlutterPatcher.applyPatch finished.');
      debugPrint('   ok: ${result.ok}');
      debugPrint('   message: ${result.message}');
      debugPrint('   error: ${result.error}');

      if (result.ok) {
        debugPrint('🎉 [OTA/Apply] SUCCESS! Patch installed. App will switch to v${patch.version} upon restart.');
        final currentPatch = await FlutterPatcher.currentVersion;
        state = state.copyWith(
          status: OtaStatus.readyToRestart,
          progress: 1.0,
          currentPatchVersion: currentPatch ?? patch.version,
        );
        return true;
      } else {
        final errorMsg = result.message ?? result.error?.name ?? 'خطای ناشناخته در نصب پچ';
        debugPrint('❌ [OTA/Apply] FAILED: $errorMsg');
        state = state.copyWith(
          status: OtaStatus.error,
          errorMessage: 'خطا در نصب به‌روزرسانی: $errorMsg',
        );
        return false;
      }
    } catch (e, st) {
      await _progressSubscription?.cancel();
      debugPrint('💥 [OTA/Apply] Exception occurred: $e\n$st');
      state = state.copyWith(
        status: OtaStatus.error,
        errorMessage: 'خطا در دریافت و اعمال پچ: $e',
      );
      return false;
    }
  }

  /// Dismisses a non-forced update from current attention
  void dismissUpdate() {
    if (state.patch?.isForce == true) return;
    state = state.copyWith(status: OtaStatus.idle);
  }

  /// Triggers an immediate cold restart of the app so the newly installed patch takes effect.
  static Future<void> restartApp() async {
    try {
      debugPrint('🔄 [OTA] Initiating immediate app restart via native channel...');
      const channel = MethodChannel('com.qurantafakor.app/app_control');
      await channel.invokeMethod('restartApp');
    } catch (e) {
      debugPrint('⚠️ [OTA] Native channel restart failed: $e. Falling back to SystemNavigator.pop().');
      await SystemNavigator.pop();
    }
  }
}
