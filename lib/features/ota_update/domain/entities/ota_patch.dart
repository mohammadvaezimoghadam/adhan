import '../../../../common/constants/app_constants.dart';

class OtaPatch {
  final String version;
  final String downloadUrl;
  final String md5;
  final String sha256;
  final int sizeBytes;
  final bool isForce;
  final int targetVersionCode;
  final String releaseNotes;
  final String createdAt;
  final String updateType; // 'patch' or 'native'

  bool get isNativeApk => updateType == 'native';

  const OtaPatch({
    required this.version,
    required this.downloadUrl,
    required this.md5,
    this.sha256 = '',
    this.sizeBytes = 0,
    this.isForce = false,
    this.targetVersionCode = 1,
    this.releaseNotes = '',
    this.createdAt = '',
    this.updateType = 'patch',
  });

  factory OtaPatch.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['download_url'] ??
            json['apk_url'] ??
            json['patch_url'] ??
            json['patchUrl'] ??
            '') as String;
    final downloadUrl = rawUrl.isEmpty || rawUrl.startsWith('http')
        ? rawUrl
        : '${AppConstants.patchServerBaseUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';

    return OtaPatch(
      version: (json['version'] ?? json['version_name'] ?? '') as String,
      downloadUrl: downloadUrl,
      md5: (json['md5'] ?? '') as String,
      sha256: (json['sha256'] ?? '') as String,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      isForce: json['is_force'] == true || json['is_force'] == 1,
      targetVersionCode: (json['target_version_code'] as num?)?.toInt() ??
          (json['version_code'] as num?)?.toInt() ??
          1,
      releaseNotes: (json['release_notes'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      updateType: (json['update_type'] ?? 'patch') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'download_url': downloadUrl,
        'patch_url': downloadUrl,
        'md5': md5,
        'sha256': sha256,
        'size_bytes': sizeBytes,
        'is_force': isForce,
        'target_version_code': targetVersionCode,
        'release_notes': releaseNotes,
        'created_at': createdAt,
        'update_type': updateType,
      };

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} مگابایت';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} کیلوبایت';
    } else if (sizeBytes > 0) {
      return '$sizeBytes بایت';
    }
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtaPatch &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          downloadUrl == other.downloadUrl &&
          md5 == other.md5 &&
          sha256 == other.sha256 &&
          sizeBytes == other.sizeBytes &&
          isForce == other.isForce &&
          targetVersionCode == other.targetVersionCode &&
          releaseNotes == other.releaseNotes &&
          updateType == other.updateType;

  @override
  int get hashCode => Object.hash(
        version,
        downloadUrl,
        md5,
        sha256,
        sizeBytes,
        isForce,
        targetVersionCode,
        releaseNotes,
        updateType,
      );
}
