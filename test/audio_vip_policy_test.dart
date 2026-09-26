import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/subscription/domain/models/vip_subscription_state.dart';
import 'package:quran/features/subscription/domain/policy/audio_vip_policy.dart';

void main() {
  setUp(() {
    VipSubscriptionState.isAllFeaturesFree = false;
  });

  tearDown(() {
    VipSubscriptionState.isAllFeaturesFree = true;
  });

  group('AudioVipPolicy Tests', () {
    test('Parhizgar (Default reciter) should be 100% free for all 114 surahs', () {
      const parhizgarIdentifier = 'parhizgar_48kbps';

      // Test across multiple surahs with isVip = false
      expect(
        AudioVipPolicy.canPlayReciter(
          reciterIdentifier: parhizgarIdentifier,
          surahId: 1,
          isVip: false,
        ),
        isTrue,
      );

      expect(
        AudioVipPolicy.canPlayReciter(
          reciterIdentifier: parhizgarIdentifier,
          surahId: 2, // Baqarah
          isVip: false,
        ),
        isTrue,
      );

      expect(
        AudioVipPolicy.canPlayReciter(
          reciterIdentifier: parhizgarIdentifier,
          surahId: 12, // Yusuf
          isVip: false,
        ),
        isTrue,
      );

      expect(
        AudioVipPolicy.canPlayReciter(
          reciterIdentifier: parhizgarIdentifier,
          surahId: 114, // Nas
          isVip: false,
        ),
        isTrue,
      );
    });

    test('Other reciters should allow only demo surahs (1, 109, 112, 113, 114) for non-VIP users', () {
      const abdulbasitIdentifier = 'abdulbasit_murattal';

      // Demo surahs: free
      for (final surahId in [1, 109, 112, 113, 114]) {
        expect(
          AudioVipPolicy.canPlayReciter(
            reciterIdentifier: abdulbasitIdentifier,
            surahId: surahId,
            isVip: false,
          ),
          isTrue,
          reason: 'Surah $surahId should be free demo for non-VIP',
        );
      }

      // Non-demo surahs: blocked for non-VIP
      for (final surahId in [2, 3, 12, 18, 36, 55, 67]) {
        expect(
          AudioVipPolicy.canPlayReciter(
            reciterIdentifier: abdulbasitIdentifier,
            surahId: surahId,
            isVip: false,
          ),
          isFalse,
          reason: 'Surah $surahId should be blocked for non-VIP',
        );
      }
    });

    test('Other reciters should allow all surahs when user is VIP', () {
      const menshawiIdentifier = 'menshawi_murattal';

      for (final surahId in [1, 2, 12, 18, 36, 114]) {
        expect(
          AudioVipPolicy.canPlayReciter(
            reciterIdentifier: menshawiIdentifier,
            surahId: surahId,
            isVip: true,
          ),
          isTrue,
          reason: 'Surah $surahId should be permitted for VIP user',
        );
      }
    });

    test('Audio translation should require VIP', () {
      expect(AudioVipPolicy.canPlayAudioTranslation(isVip: false), isFalse);
      expect(AudioVipPolicy.canPlayAudioTranslation(isVip: true), isTrue);
    });
  });
}
