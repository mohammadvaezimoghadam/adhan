import '../models/vip_subscription_state.dart';

/// Pure business policy governing access to Quran audio playback, reciters, and audio translations.
class AudioVipPolicy {
  /// Surah IDs that are available 100% free for ALL reciters (Demo Surahs):
  /// - 1: سوره حمد (الفاتحة)
  /// - 109: سوره کافرون
  /// - 112: سوره توحید (الإخلاص)
  /// - 113: سوره فلق
  /// - 114: سوره ناس
  static const Set<int> demoSurahIds = {1, 109, 112, 113, 114};

  /// Reference/Default reciter identifier keyword (استاد شهریار پرهیزگار).
  /// This reciter is 100% free for all 114 Surahs across the entire Quran.
  static const String defaultReciterKeyword = 'parhizgar';

  /// Returns true if the given Surah is one of the 5 free demo surahs.
  static bool isDemoSurah(int surahId) {
    return demoSurahIds.contains(surahId);
  }

  /// Returns true if the given reciter identifier belongs to the default free reciter (Parhizgar).
  static bool isDefaultReciter(String? identifier) {
    if (identifier == null || identifier.isEmpty) return false;
    return identifier.toLowerCase().contains(defaultReciterKeyword);
  }

  /// Determines whether playing a specific Surah for a specific Reciter is permitted.
  static bool canPlayReciter({
    required String? reciterIdentifier,
    required int surahId,
    required bool isVip,
  }) {
    if (VipSubscriptionState.isAllFeaturesFree || isVip) {
      return true;
    }

    if (isDefaultReciter(reciterIdentifier)) {
      return true;
    }

    if (isDemoSurah(surahId)) {
      return true;
    }

    return isVip;
  }

  /// Determines whether playing Persian audio translation (ترجمه گویای صوتی) is permitted.
  static bool canPlayAudioTranslation({required bool isVip}) {
    if (VipSubscriptionState.isAllFeaturesFree || isVip) {
      return true;
    }
    return isVip;
  }
}
