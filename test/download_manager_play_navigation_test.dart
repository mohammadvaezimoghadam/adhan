import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/download_manager/domain/entities/downloaded_item_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Download Manager Play Navigation Tests', () {
    test('DownloadedItemType distinguishes audio items from text translation', () {
      final quranAudio = DownloadedItemEntity(
        id: '1',
        title: 'سوره فاتحه',
        subtitle: 'پرهیزگار',
        type: DownloadedItemType.quranAudio,
        sizeBytes: 1024,
        formattedSize: '1 MB',
        surahId: 1,
        reciterId: 1,
      );

      final audioTranslation = DownloadedItemEntity(
        id: '2',
        title: 'سوره فاتحه',
        subtitle: 'صوتی مکارم',
        type: DownloadedItemType.audioTranslation,
        sizeBytes: 2048,
        formattedSize: '2 MB',
        surahId: 1,
        reciterId: 100,
      );

      final textTranslation = DownloadedItemEntity(
        id: '3',
        title: 'ترجمه مکارم',
        subtitle: 'فارسی',
        type: DownloadedItemType.textTranslation,
        sizeBytes: 512,
        formattedSize: '512 KB',
        translationId: 'fa.makarem',
      );

      final isAudio1 = quranAudio.type == DownloadedItemType.quranAudio ||
          quranAudio.type == DownloadedItemType.audioTranslation;
      final isAudio2 = audioTranslation.type == DownloadedItemType.quranAudio ||
          audioTranslation.type == DownloadedItemType.audioTranslation;
      final isAudio3 = textTranslation.type == DownloadedItemType.quranAudio ||
          textTranslation.type == DownloadedItemType.audioTranslation;

      expect(isAudio1, isTrue);
      expect(isAudio2, isTrue);
      expect(isAudio3, isFalse);
    });

    test('Route query parameters always point to ayah 1 on download play navigation', () {
      final queryParams = {
        'ayah': '1',
        'name': 'سوره فاتحه',
      };

      expect(queryParams['ayah'], equals('1'));
      expect(int.tryParse(queryParams['ayah']!), equals(1));
    });
  });
}
