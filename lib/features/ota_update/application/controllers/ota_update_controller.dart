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

  Future<String> _getOrCreateDeviceId(SharedPreferences prefs) async {
    String? deviceId = prefs.getString('ota_device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'dev_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}_${(100000 + (DateTime.now().microsecond % 900000))}';
      await prefs.setString('ota_device_id', deviceId);
    }
    return deviceId;
  }

  Future<void> _loadInitialPatcherInfo() async {
    try {
      final currentVersion = await FlutterPatcher.currentVersion;
      final rawBuildNumber = await FlutterPatcher.appVersionCode;
      final buildNumber = (rawBuildNumber != null && rawBuildNumber >= 1000)
          ? (rawBuildNumber % 1000)
          : (rawBuildNumber ?? 1);
      debugPrint(
        '🧩 [OTA/Init] FlutterPatcher loaded -> currentPatch: ${currentVersion ?? "none"}, appVersionCode: $buildNumber',
      );
      final prefs = await SharedPreferences.getInstance();
      final lastRecordedBuild = prefs.getInt('ota_recorded_build_code');
      String? savedNotes = prefs.getString('ota_last_release_notes');
      String? effectivePatch = currentVersion;

      // اگر کاربر APK جدیدتری نصب کرده باشد (بیلد افزایش یافته):
      if (lastRecordedBuild != null && buildNumber > lastRecordedBuild) {
        debugPrint(
          '🚀 [OTA/Init] Host APK upgraded ($lastRecordedBuild -> $buildNumber)! Invalidating old patch and notes.',
        );
        await prefs.remove('ota_last_release_notes');
        await prefs.remove('ota_last_patch_version');
        savedNotes = null;
        effectivePatch = null;
        try {
          await FlutterPatcher.rollback();
        } catch (_) {}
      }

      // مکانیزم Crash Guard (محافظ کرش کلاینتی):
      if (effectivePatch != null && effectivePatch.isNotEmpty) {
        final crashCount = (prefs.getInt('ota_boot_crash_count') ?? 0) + 1;
        await prefs.setInt('ota_boot_crash_count', crashCount);
        debugPrint(
          '🛡️ [OTA/CrashGuard] Boot health check -> patch: $effectivePatch, crashCount: $crashCount',
        );

        if (crashCount >= 2) {
          debugPrint(
            '🚨 [OTA/CrashGuard] Crash threshold reached ($crashCount >= 2)! Triggering emergency auto-rollback...',
          );
          try {
            await FlutterPatcher.rollback();
            unawaited(_reportEvent(effectivePatch, 'ROLLBACK_TRIGGERED'));
            await prefs.remove('ota_last_release_notes');
            await prefs.remove('ota_last_patch_version');
            await prefs.setInt('ota_boot_crash_count', 0);
            effectivePatch = null;
            savedNotes = null;
          } catch (e) {
            debugPrint('❌ [OTA/CrashGuard] Auto-rollback failed: $e');
          }
        }
      } else {
        await prefs.setInt('ota_boot_crash_count', 0);
      }

      await prefs.setInt('ota_recorded_build_code', buildNumber);

      state = state.copyWith(
        currentPatchVersion: effectivePatch,
        currentBuildNumber: buildNumber,
        lastReleaseNotes: savedNotes,
      );
    } catch (e) {
      debugPrint('⚠️ [OTA/Init] Error reading patcher info: $e');
    }
  }

  /// ریست کردن شمارنده کرش پس از بارگذاری موفق و پایدار صفحه اصلی
  Future<void> resetCrashCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('ota_boot_crash_count') ?? 0;
      if (count > 0) {
        debugPrint(
          '🛡️ [OTA/CrashGuard] Main UI stable. Resetting crash counter ($count -> 0).',
        );
        await prefs.setInt('ota_boot_crash_count', 0);
      }
    } catch (e) {
      debugPrint('⚠️ [OTA/CrashGuard] Error resetting crash counter: $e');
    }
  }

  /// گزارش تله‌متری رویدادهای OTA به سرور
  Future<void> _reportEvent(
    String patchVersion,
    String event, {
    int? durationMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _getOrCreateDeviceId(prefs);
      debugPrint(
        '📊 [OTA/Report] Reporting event "$event" for patch $patchVersion...',
      );
      await _dio.post(
        '/api/v1/ota/report/',
        data: {
          'app_id': AppConstants.patchAppId,
          'patch_version': patchVersion,
          'event': event, // SUCCESS, MD5_FAILED, EXTRACT_FAILED, ROLLBACK_TRIGGERED
          'duration_ms': ?durationMs,
          'device_id': deviceId,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [OTA/Report] Telemetry report suppressed error: $e');
    }
  }

  /// Checks the backend patch server for any active updates.
  /// Returns `true` if a new patch or store update is available.
  Future<bool> checkForUpdate({bool manual = false}) async {
    if (state.isDownloading) {
      debugPrint('⏳ [OTA/Check] Skipped: download is currently in progress.');
      return false;
    }

    state = state.copyWith(status: OtaStatus.checking, errorMessage: null);

    try {
      final currentPatch = await FlutterPatcher.currentVersion;
      final rawVersionCode = await FlutterPatcher.appVersionCode;
      final deviceAbi = await FlutterPatcher.deviceAbi;
      // In Flutter --split-per-abi builds:
      // arm64-v8a: 2001 -> 1, armeabi-v7a: 1001 -> 1, x86_64: 4001 -> 1
      final versionCode = (rawVersionCode != null && rawVersionCode >= 1000)
          ? (rawVersionCode % 1000)
          : (rawVersionCode ?? 1);

      final baseVersionName =
          versionCode > 1 ? '1.0.${versionCode - 1}' : '1.0.0';
      final baseRelease = '$baseVersionName+$versionCode';

      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _getOrCreateDeviceId(prefs);

      debugPrint('═══════════════════════════════════════════════════════════════');
      debugPrint('🔍 [OTA/Check] Initiating update check (manual: $manual)');
      debugPrint('   🌐 Endpoint: ${AppConstants.patchServerBaseUrl}/api/v1/ota/check/');
      debugPrint('   📦 App ID: ${AppConstants.patchAppId}');
      debugPrint('   🏷️ Base Release: $baseRelease');
      debugPrint('   ⚙️ Device ABI: ${deviceAbi.isNotEmpty ? deviceAbi : "auto"}');
      debugPrint('   🧩 Current Patch: ${currentPatch ?? "none"}');
      debugPrint('   📡 Channel: ${AppConstants.patchChannel}');
      debugPrint('   🆔 Device ID: $deviceId');
      debugPrint('═══════════════════════════════════════════════════════════════');

      final requestData = {
        'app_id': AppConstants.patchAppId,
        'base_release': baseRelease,
        'base_version_name': baseVersionName,
        'base_build_number': versionCode,
        'abi': deviceAbi.isNotEmpty ? deviceAbi : 'arm64-v8a',
        'current_patch_version': currentPatch ?? '',
        'channel': AppConstants.patchChannel,
        'device_id': deviceId,
      };

      Response response;
      try {
        response = await _dio.post(
          '/api/v1/ota/check/',
          data: requestData,
        );
      } on DioException catch (dioErr) {
        // Fallback backward compatibility: if new route 404s, try legacy GET /check
        if (dioErr.response?.statusCode == 404) {
          debugPrint(
            '🔄 [OTA/Check] /api/v1/ota/check/ returned 404. Falling back to legacy GET /check...',
          );
          response = await _dio.get(
            '/check',
            queryParameters: {
              'app_id': AppConstants.patchAppId,
              'app_version_code': versionCode,
              if (deviceAbi.isNotEmpty) 'abi': deviceAbi,
              if (currentPatch != null && currentPatch.isNotEmpty)
                'current_patch': currentPatch,
            },
          );
        } else {
          rethrow;
        }
      }

      final data = response.data;
      debugPrint('📥 [OTA/Check] Raw response data: $data');

      if (data is! Map) {
        debugPrint('⚠️ [OTA/Check] Invalid response type: ${data.runtimeType}');
        state = state.copyWith(status: OtaStatus.upToDate);
        return false;
      }

      final status = data['status'] as String?;

      // سناریوی ۱: پچ جدید موجود است
      if (status == 'PATCH_AVAILABLE' ||
          (status == null && data['has_update'] == true)) {
        final patchMap = (data['patch'] is Map)
            ? Map<String, dynamic>.from(data['patch'] as Map)
            : Map<String, dynamic>.from(data);

        final patch = OtaPatch.fromJson(patchMap);
        debugPrint('🎉 [OTA/Check] PATCH_AVAILABLE!');
        debugPrint('   Version: ${patch.version}');
        debugPrint('   Force Update: ${patch.isForce}');
        debugPrint('   Target Version Code: ${patch.targetVersionCode}');
        debugPrint('   Download URL: ${patch.downloadUrl}');
        debugPrint('   MD5: ${patch.md5}');
        debugPrint('   Size: ${patch.sizeBytes} bytes');
        debugPrint('   Release Notes: ${patch.releaseNotes}');

        if (patch.releaseNotes.isNotEmpty) {
          try {
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
          debugPrint(
            '⚡ [OTA/Silent] Starting silent background patch download...',
          );
          unawaited(startDownloadAndApply());
        }

        return true;
      }
      // سناریوی ۲: ارتقای بیلد کامل از طریق استور ضروری است
      else if (status == 'STORE_UPDATE_REQUIRED') {
        final storeMap = (data['store'] is Map)
            ? Map<String, dynamic>.from(data['store'] as Map)
            : <String, dynamic>{};

        final storeUrl = (storeMap['store_url'] ??
            'bazaar://details?id=com.qurantafakor.app') as String;
        final storeWebUrl = (storeMap['web_url'] ??
            'https://cafebazaar.ir/app/com.qurantafakor.app') as String;
        final storeMessage = (storeMap['message'] ??
            data['message'] ??
            'نسخه جدید قرآن در کافه‌بازار منتشر شده است. لطفاً برنامه را به‌روزرسانی کنید.') as String;
        final latestVersion = (storeMap['latest_version'] ?? '') as String;
        final isMandatory = storeMap['is_mandatory'] == true;

        debugPrint('🏪 [OTA/Check] STORE_UPDATE_REQUIRED:');
        debugPrint('   Store URL: $storeUrl');
        debugPrint('   Web URL: $storeWebUrl');
        debugPrint('   Message: $storeMessage');
        debugPrint('   Mandatory: $isMandatory');

        state = state.copyWith(
          status: OtaStatus.storeUpdateRequired,
          patch: null,
          storeUrl: storeUrl,
          storeWebUrl: storeWebUrl,
          storeMessage: storeMessage,
          storeLatestVersion: latestVersion,
          storeIsMandatory: isMandatory,
          currentPatchVersion: currentPatch,
          currentBuildNumber: versionCode,
        );

        return true;
      }
      // سناریوی ۳: دستور رول‌بک از طرف سرور
      else if (data['action'] == 'rollback' || data['should_rollback'] == true) {
        debugPrint(
          '⚠️ [OTA/Rollback] Rollback instructed by server! Performing FlutterPatcher.rollback()...',
        );
        try {
          await FlutterPatcher.rollback();
          unawaited(_reportEvent(currentPatch ?? 'unknown', 'ROLLBACK_TRIGGERED'));
          await prefs.remove('ota_last_release_notes');
          await prefs.remove('ota_last_patch_version');
          await OtaUpdateController.restartApp();
        } catch (e) {
          debugPrint('❌ [OTA/Rollback] Failed to execute rollback: $e');
        }
        return true;
      }
      // سناریوی ۴: برنامه به‌روز است (UP_TO_DATE)
      else {
        final message = data['message'];
        debugPrint('✅ [OTA/Check] App is up to date. (Server message: $message)');
        final serverNotes = (data['release_notes'] is String &&
                (data['release_notes'] as String).isNotEmpty)
            ? data['release_notes'] as String
            : null;
        if (serverNotes != null) {
          try {
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

    final applyStartTime = DateTime.now();

    try {
      final rawBuildNumber = await FlutterPatcher.appVersionCode;
      // اگر سرور targetVersionCode معتبر ارسال کرده باشد از آن استفاده می‌کنیم،
      // در غیر این صورت برای جلوگیری از خطای عدم تطابق کدهای نیتیو گرادل (مانند 2001 در arm64)،
      // از کد نسخه واقعی خود دستگاه استفاده می‌شود.
      final effectiveTargetCode = (patch.targetVersionCode > 1)
          ? patch.targetVersionCode
          : (rawBuildNumber ?? 1);

      final patchInfo = PatchInfo(
        version: patch.version,
        patchUrl: patch.downloadUrl,
        md5: patch.md5,
        targetVersionCode: effectiveTargetCode,
      );

      debugPrint('⚙️ [OTA/Apply] Invoking FlutterPatcher.applyPatch()...');
      final result = await FlutterPatcher.applyPatch(patchInfo);
      await _progressSubscription?.cancel();

      debugPrint('📦 [OTA/Apply] FlutterPatcher.applyPatch finished.');
      debugPrint('   ok: ${result.ok}');
      debugPrint('   message: ${result.message}');
      debugPrint('   error: ${result.error}');

      if (result.ok) {
        debugPrint(
            '🎉 [OTA/Apply] SUCCESS! Patch installed. App will switch to v${patch.version} upon restart.');
        final durationMs =
            DateTime.now().difference(applyStartTime).inMilliseconds;
        unawaited(_reportEvent(patch.version, 'SUCCESS', durationMs: durationMs));

        final currentPatch = await FlutterPatcher.currentVersion;
        state = state.copyWith(
          status: OtaStatus.readyToRestart,
          progress: 1.0,
          currentPatchVersion: currentPatch ?? patch.version,
        );
        return true;
      } else {
        final isMd5 = result.error?.name.toLowerCase().contains('md5') == true ||
            (result.message?.toLowerCase().contains('md5') ?? false);
        unawaited(_reportEvent(
          patch.version,
          isMd5 ? 'MD5_FAILED' : 'EXTRACT_FAILED',
        ));

        final errorMsg =
            result.message ?? result.error?.name ?? 'خطای ناشناخته در نصب پچ';
        debugPrint('❌ [OTA/Apply] FAILED: $errorMsg');
        state = state.copyWith(
          status: OtaStatus.error,
          errorMessage: 'خطا در نصب به‌روزرسانی: $errorMsg',
        );
        return false;
      }
    } catch (e, st) {
      await _progressSubscription?.cancel();
      unawaited(_reportEvent(patch.version, 'EXTRACT_FAILED'));
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
