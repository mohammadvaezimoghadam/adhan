import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/subscription/domain/models/vip_subscription_state.dart';
import 'package:quran/features/subscription/domain/policy/translation_vip_policy.dart';

void main() {
  setUp(() {
    VipSubscriptionState.isAllFeaturesFree = false;
  });

  tearDown(() {
    VipSubscriptionState.isAllFeaturesFree = true;
  });

  group('TranslationVipPolicy Tests', () {
    test('Default database translation (fa.makarem) should be 100% free for non-VIP', () {
      expect(TranslationVipPolicy.isTranslationFree('fa.makarem'), isTrue);
      expect(
        TranslationVipPolicy.canAccessTranslation(
          translationId: 'fa.makarem',
          hasVip: false,
        ),
        isTrue,
      );
    });

    test('Other translations (Ansarian, Fooladvand, Ghomshei, etc.) should require VIP', () {
      final premiumTranslations = [
        'fa.ansarian',
        'fa.fooladvand',
        'fa.ghomshei',
        'fa.bahrampour',
        'en.sahih',
      ];

      for (final id in premiumTranslations) {
        expect(TranslationVipPolicy.isTranslationFree(id), isFalse);
        expect(
          TranslationVipPolicy.canAccessTranslation(
            translationId: id,
            hasVip: false,
          ),
          isFalse,
          reason: '$id should not be accessible for non-VIP',
        );
      }
    });

    test('All translations should be accessible when user has VIP', () {
      final allTestTranslations = [
        'fa.makarem',
        'fa.ansarian',
        'fa.fooladvand',
        'fa.ghomshei',
        'en.sahih',
      ];

      for (final id in allTestTranslations) {
        expect(
          TranslationVipPolicy.canAccessTranslation(
            translationId: id,
            hasVip: true,
          ),
          isTrue,
          reason: '$id should be accessible for VIP user',
        );
      }
    });
  });
}
