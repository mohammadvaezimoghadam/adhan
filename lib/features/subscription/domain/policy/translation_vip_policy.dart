import '../models/vip_subscription_state.dart';

/// Defines VIP access policy for Quran text translations.
class TranslationVipPolicy {
  /// The default free translation bundled in the local database.
  /// Makarem Shirazi (fa.makarem) is pre-packaged in the database.
  static const String freeTranslationId = 'fa.makarem';

  /// Returns true if the given translation is 100% free for everyone.
  static bool isTranslationFree(String translationId) {
    return translationId == freeTranslationId;
  }

  /// Returns true if the user has permission to download or read this translation.
  static bool canAccessTranslation({
    required String translationId,
    required bool hasVip,
  }) {
    if (VipSubscriptionState.isAllFeaturesFree || hasVip) return true;
    return isTranslationFree(translationId);
  }
}
