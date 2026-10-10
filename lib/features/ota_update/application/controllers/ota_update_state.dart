import '../../domain/entities/ota_patch.dart';

enum OtaStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  verifying,
  finalizing,
  readyToRestart,
  upToDate,
  error,
}

class OtaUpdateState {
  final OtaStatus status;
  final OtaPatch? patch;
  final double progress; // 0.0 to 1.0
  final int bytesReceived;
  final int totalBytes;
  final String? currentPatchVersion;
  final int? currentBuildNumber;
  final String? errorMessage;

  final String? lastReleaseNotes;

  const OtaUpdateState({
    this.status = OtaStatus.idle,
    this.patch,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.currentPatchVersion,
    this.currentBuildNumber,
    this.errorMessage,
    this.lastReleaseNotes,
  });

  bool get hasUpdate =>
      patch != null &&
      (status == OtaStatus.updateAvailable ||
          status == OtaStatus.downloading ||
          status == OtaStatus.verifying ||
          status == OtaStatus.finalizing ||
          status == OtaStatus.readyToRestart);

  bool get isDownloading =>
      status == OtaStatus.downloading ||
      status == OtaStatus.verifying ||
      status == OtaStatus.finalizing;

  bool get isReadyToRestart => status == OtaStatus.readyToRestart;

  OtaUpdateState copyWith({
    OtaStatus? status,
    OtaPatch? patch,
    double? progress,
    int? bytesReceived,
    int? totalBytes,
    String? currentPatchVersion,
    int? currentBuildNumber,
    String? errorMessage,
    String? lastReleaseNotes,
  }) {
    return OtaUpdateState(
      status: status ?? this.status,
      patch: patch ?? this.patch,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      currentPatchVersion: currentPatchVersion ?? this.currentPatchVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      errorMessage: errorMessage,
      lastReleaseNotes: lastReleaseNotes ?? this.lastReleaseNotes,
    );
  }
}
