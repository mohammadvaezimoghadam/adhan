import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../common/constants/app_constants.dart';

part 'tafakor_topic.freezed.dart';

@freezed
abstract class TafakorTopic with _$TafakorTopic {
  const TafakorTopic._();

  const factory TafakorTopic({
    required int id,
    required String name,
    String? image,
    String? description,
    String? postBadge,
    int? createdBy,
    String? createdByPhone,
    String? createdAt,
    @Default(false) bool telegramBotActive,
    @Default(false) bool baleBotActive,
    @Default(0) int postCount,
  }) = _TafakorTopic;

  String? get fullImageUrl {
    if (image == null || image!.trim().isEmpty) return null;
    final img = image!.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    final baseUri = Uri.tryParse(AppConstants.tafakorBaseUrl);
    if (baseUri != null) {
      final hostPort =
          '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      return img.startsWith('/') ? '$hostPort$img' : '$hostPort/$img';
    }
    return img;
  }

  static String normalizePhone(String phone) {
    var p = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (p.startsWith('+98')) {
      p = '0${p.substring(3)}';
    } else if (p.startsWith('0098')) {
      p = '0${p.substring(4)}';
    } else if (p.startsWith('98') && p.length == 12) {
      p = '0${p.substring(2)}';
    } else if (!p.startsWith('0') && p.length == 10) {
      p = '0$p';
    }
    return p;
  }

  bool isOwner(String? userPhone) {
    if (userPhone == null || userPhone.isEmpty || createdByPhone == null) {
      return false;
    }
    return normalizePhone(userPhone) == normalizePhone(createdByPhone!);
  }
}
