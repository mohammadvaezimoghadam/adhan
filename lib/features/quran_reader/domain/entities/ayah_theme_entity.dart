import 'package:flutter/material.dart';
import '../../../../common/constants/app_constants.dart';

class AyahThemeEntity {
  final String id;
  final String name;
  final String previewAsset;
  final Color oddColor;
  final Color evenColor;
  final Color borderColor;
  final Color headerTextColor;
  final Color dividerColor;
  final bool isDark;

  const AyahThemeEntity({
    required this.id,
    required this.name,
    required this.previewAsset,
    required this.oddColor,
    required this.evenColor,
    required this.borderColor,
    required this.headerTextColor,
    required this.dividerColor,
    required this.isDark,
  });

  Color getBackgroundColor({required bool isOdd, bool isSolid = false}) {
    if (isSolid) return evenColor;
    return isOdd ? oddColor : evenColor;
  }
}

abstract class AyahThemePresets {
  static const String defaultThemeId = 'classic_ivory';

  static const AyahThemeEntity classicIvory = AyahThemeEntity(
    id: 'classic_ivory',
    name: 'عاجی مصحف',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFFF1EBE0),
    evenColor: Color(0xFFFAF8F5),
    borderColor: Color(0xFFE2D9C8),
    headerTextColor: Color(0xFF1E6B5C),
    dividerColor: Color(0x611E6B5C),
    isDark: false,
  );

  static const AyahThemeEntity pureWhite = AyahThemeEntity(
    id: 'pure_white',
    name: 'سفید مینیمال',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFFFFFFFF),
    evenColor: Color(0xFFF9F9FB),
    borderColor: Color(0xFFECECEE),
    headerTextColor: Color(0xFF0F766E),
    dividerColor: Color(0x590F766E),
    isDark: false,
  );

  static const AyahThemeEntity sacredEmerald = AyahThemeEntity(
    id: 'sacred_emerald',
    name: 'سبز زمرّدی',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFFE5F1EE),
    evenColor: Color(0xFFEEF6F4),
    borderColor: Color(0xFFBCE0D7),
    headerTextColor: Color(0xFF065F46),
    dividerColor: Color(0x66065F46),
    isDark: false,
  );

  static const AyahThemeEntity warmSepia = AyahThemeEntity(
    id: 'warm_sepia',
    name: 'سپیا (کاهی)',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFFF2E7D3),
    evenColor: Color(0xFFF8F0E2),
    borderColor: Color(0xFFE2D2B8),
    headerTextColor: Color(0xFF7C4A1E),
    dividerColor: Color(0x6B7C4A1E),
    isDark: false,
  );

  static const AyahThemeEntity midnightSlate = AyahThemeEntity(
    id: 'midnight_slate',
    name: 'دودی شب',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFF1B2423),
    evenColor: Color(0xFF131A19),
    borderColor: Color(0xFF2C3836),
    headerTextColor: Color(0xFF5EEAD4),
    dividerColor: Color(0x805EEAD4),
    isDark: true,
  );

  static const AyahThemeEntity oledBlack = AyahThemeEntity(
    id: 'oled_black',
    name: 'مشکی مطلق',
    previewAsset: AppConstants.ayahCardBgAsset,
    oddColor: Color(0xFF000000),
    evenColor: Color(0xFF080808),
    borderColor: Color(0xFF222222),
    headerTextColor: Color(0xFFE5B869),
    dividerColor: Color(0x99E5B869),
    isDark: true,
  );

  static const List<AyahThemeEntity> all = [
    classicIvory,
    pureWhite,
    sacredEmerald,
    warmSepia,
    midnightSlate,
    oledBlack,
  ];

  static AyahThemeEntity getById(String? id) {
    if (id == null) return classicIvory;
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => classicIvory,
    );
  }
}
