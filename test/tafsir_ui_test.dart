import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_reader/domain/entities/ayah_entity.dart';
import 'package:quran/features/tafsir_manager/application/controllers/surah_tafsir_provider.dart';
import 'package:quran/features/tafsir_manager/application/controllers/tafsir_manager_controller.dart';
import 'package:quran/features/tafsir_manager/application/states/tafsir_manager_state.dart';
import 'package:quran/features/tafsir_manager/domain/entities/tafsir_entity.dart';
import 'package:quran/features/tafsir_manager/infrastructure/datasources/tafsir_catalog.dart';
import 'package:quran/features/tafsir_manager/presentation/ui/tafsir_reader_screen.dart';
import 'package:quran/features/tafsir_manager/presentation/widgets/tafsir_manager_bottom_sheet.dart';
import 'package:quran/features/tafsir_manager/presentation/widgets/tafsir_selection_dialog.dart';
import 'package:quran/features/surah_list/application/controllers/surah_list_controller.dart';
import 'package:quran/features/surah_list/application/states/surah_list_state.dart';
import 'package:quran/features/surah_list/domain/entities/surah_entity.dart';

void main() {
  testWidgets('TafsirManagerBottomSheet renders pickers and action button properly', (tester) async {
    const mockSurah = SurahEntity(
      number: 1,
      name: 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: 'Al-Faatiha',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
      startPage: 1,
      startJuz: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListControllerProvider.overrideWith(
            () => FakeSurahListController([mockSurah]),
          ),
          tafsirManagerControllerProvider.overrideWith(
            () => FakeTafsirManagerController(TafsirCatalog.allTafsirs),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TafsirManagerBottomSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify modal header title
    expect(find.text('انتخاب سوره و تفسیر'), findsOneWidget);

    // Verify picker subtitles
    expect(find.text('سوره'), findsOneWidget);
    expect(find.text('تفسیر'), findsOneWidget);

    // Verify Tafsir entries from catalog are present
    expect(find.textContaining('تفسیر نور'), findsWidgets);
    expect(find.textContaining('تفسیر المیزان'), findsWidgets);
  });

  testWidgets('TafsirReaderScreen renders ayahs and Surah navigation footer without errors', (tester) async {
    const mockSurah1 = SurahEntity(
      number: 1,
      name: 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: 'Al-Faatiha',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
      startPage: 1,
      startJuz: 1,
    );

    const mockSurah2 = SurahEntity(
      number: 2,
      name: 'سُورَةُ البَقَرَةِ',
      englishName: 'Al-Baqara',
      englishNameTranslation: 'The Cow',
      numberOfAyahs: 286,
      revelationType: 'Medinan',
      startPage: 2,
      startJuz: 1,
    );

    const mockSurah3 = SurahEntity(
      number: 3,
      name: 'سُورَةُ آلِ عِمْرَانَ',
      englishName: 'Aal-i-Imraan',
      englishNameTranslation: 'The Family of Imraan',
      numberOfAyahs: 200,
      revelationType: 'Medinan',
      startPage: 50,
      startJuz: 3,
    );

    const downloadedTafsir = TafsirEntity(
      id: 'fa-gharaati',
      name: 'تفسیر نور',
      authorName: 'حجت‌الاسلام محسن قرائتی',
      description: 'تفسیر روان و کاربردی آیات قرآن',
      sourceUrl: 'https://example.com/tafsir.json',
      isDownloaded: true,
    );

    const mockAyah = AyahEntity(
      id: 1,
      surahId: 2,
      ayahNumber: 1,
      arabicText: 'الم',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListControllerProvider.overrideWith(
            () => FakeSurahListController([mockSurah1, mockSurah2, mockSurah3]),
          ),
          tafsirManagerControllerProvider.overrideWith(
            () => FakeTafsirManagerController([downloadedTafsir]),
          ),
          tafsirAyahsProvider(2).overrideWith(
            (ref) async => [mockAyah],
          ),
          surahTafsirProvider((surahNumber: 2, tafsirId: 'fa-gharaati')).overrideWith(
            (ref) async => {1: 'تفسیر الم در ابتدای سوره بقره'},
          ),
        ],
        child: const MaterialApp(
          home: TafsirReaderScreen(
            surahId: 2,
            surahName: 'البقرة',
            tafsirId: 'fa-gharaati',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Surah header (Persian name from extension)
    expect(find.textContaining('بقره'), findsWidgets);
    expect(find.textContaining('تفسیر نور'), findsWidgets);

    // Verify Ayah and Tafsir card
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('تفسیر الم در ابتدای سوره بقره'), findsOneWidget);

    // Verify navigation buttons (both footer and dynamic floating buttons for Surah 2 boundaries)
    expect(find.textContaining('سوره قبلی'), findsWidgets);
    expect(find.textContaining('سوره بعدی'), findsWidgets);
    expect(find.textContaining('فاتحه'), findsWidgets);
    expect(find.textContaining('آل عمران'), findsWidgets);
  });

  testWidgets('TafsirSelectionDialog renders tafsir list, download status, and handles taps',
      (WidgetTester tester) async {
    final downloadedTafsir = TafsirCatalog.allTafsirs.first.copyWith(isDownloaded: true);
    final nonDownloadedTafsir = TafsirCatalog.allTafsirs[1].copyWith(isDownloaded: false);

    const testAyah = AyahEntity(
      id: 1,
      surahId: 2,
      ayahNumber: 5,
      arabicText: 'أُولَٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tafsirManagerControllerProvider.overrideWith(
            () => FakeTafsirManagerController([downloadedTafsir, nonDownloadedTafsir]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TafsirSelectionDialog.show(
                  context,
                  ayah: testAyah,
                  surahName: 'بقره',
                ),
                child: const Text('باز کردن دیالوگ'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('باز کردن دیالوگ'));
    await tester.pumpAndSettle();

    // Verify dialog opened with Ayah title
    expect(find.textContaining('تفسیر سوره بقره'), findsOneWidget);
    expect(find.text(downloadedTafsir.name), findsOneWidget);
    expect(find.text(nonDownloadedTafsir.name), findsOneWidget);
    // Verify standard close button (xmark_circle_fill) is present and closes the dialog
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pumpAndSettle();
    expect(find.textContaining('تفسیر سوره بقره'), findsNothing);
  });

  testWidgets('TafsirReaderScreen dynamic buttons adapt between Ayah navigation and Surah navigation',
      (WidgetTester tester) async {
    const mockSurah1 = SurahEntity(
      number: 1,
      name: 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: 'Al-Faatiha',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
      startPage: 1,
      startJuz: 1,
    );
    const mockSurah2 = SurahEntity(
      number: 2,
      name: 'سُورَةُ البَقَرَةِ',
      englishName: 'Al-Baqara',
      englishNameTranslation: 'The Cow',
      numberOfAyahs: 286,
      revelationType: 'Medinan',
      startPage: 2,
      startJuz: 1,
    );
    const mockSurah3 = SurahEntity(
      number: 3,
      name: 'سُورَةُ آلِ عِمْرَانَ',
      englishName: 'Aal-i-Imraan',
      englishNameTranslation: 'The Family of Imraan',
      numberOfAyahs: 200,
      revelationType: 'Medinan',
      startPage: 50,
      startJuz: 3,
    );

    const downloadedTafsir = TafsirEntity(
      id: 'fa-gharaati',
      name: 'تفسیر نور',
      authorName: 'حجت‌الاسلام محسن قرائتی',
      description: 'تفسیر روان و کاربردی آیات قرآن',
      sourceUrl: 'https://example.com/tafsir.json',
      isDownloaded: true,
    );

    final mockAyahs = List.generate(
      10,
      (i) => AyahEntity(
        id: i + 1,
        surahId: 2,
        ayahNumber: i + 1,
        arabicText: 'متن عربی آیه ${i + 1}',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListControllerProvider.overrideWith(
            () => FakeSurahListController([mockSurah1, mockSurah2, mockSurah3]),
          ),
          tafsirManagerControllerProvider.overrideWith(
            () => FakeTafsirManagerController([downloadedTafsir]),
          ),
          tafsirAyahsProvider(2).overrideWith(
            (ref) async => mockAyahs,
          ),
          surahTafsirProvider((surahNumber: 2, tafsirId: 'fa-gharaati')).overrideWith(
            (ref) async => {for (var i = 1; i <= 10; i++) i: 'تفسیر آیه $i'},
          ),
        ],
        child: const MaterialApp(
          home: TafsirReaderScreen(
            surahId: 2,
            surahName: 'البقرة',
            tafsirId: 'fa-gharaati',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // At Ayah 1: Top button shows 'سوره قبلی (فاتحه)' and bottom button shows 'بعدی'
    expect(find.text('سوره قبلی (فاتحه)'), findsWidgets);
    expect(find.text('بعدی'), findsOneWidget);
  });

  testWidgets('TafsirReaderScreen directly renders at initialAyahNumber without jump or reset',
      (WidgetTester tester) async {
    const mockSurah1 = SurahEntity(
      number: 1,
      name: 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: 'Al-Faatiha',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
      startPage: 1,
      startJuz: 1,
    );
    const mockSurah2 = SurahEntity(
      number: 2,
      name: 'سُورَةُ البَقَرَةِ',
      englishName: 'Al-Baqara',
      englishNameTranslation: 'The Cow',
      numberOfAyahs: 286,
      revelationType: 'Medinan',
      startPage: 2,
      startJuz: 1,
    );

    const downloadedTafsir = TafsirEntity(
      id: 'fa-gharaati',
      name: 'تفسیر نور',
      authorName: 'حجت‌الاسلام محسن قرائتی',
      description: 'تفسیر روان و کاربردی آیات قرآن',
      sourceUrl: 'https://example.com/tafsir.json',
      isDownloaded: true,
    );

    final mockAyahs = List.generate(
      20,
      (i) => AyahEntity(
        id: i + 1,
        surahId: 2,
        ayahNumber: i + 1,
        arabicText: 'متن عربی آیه ${i + 1}',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListControllerProvider.overrideWith(
            () => FakeSurahListController([mockSurah1, mockSurah2]),
          ),
          tafsirManagerControllerProvider.overrideWith(
            () => FakeTafsirManagerController([downloadedTafsir]),
          ),
          tafsirAyahsProvider(2).overrideWith(
            (ref) async => mockAyahs,
          ),
          surahTafsirProvider((surahNumber: 2, tafsirId: 'fa-gharaati')).overrideWith(
            (ref) async => {for (var i = 1; i <= 20; i++) i: 'تفسیر آیه $i'},
          ),
        ],
        child: const MaterialApp(
          home: TafsirReaderScreen(
            surahId: 2,
            surahName: 'البقرة',
            tafsirId: 'fa-gharaati',
            initialAyahNumber: 15,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Ayah 15 and its tafsir are rendered
    expect(find.text('متن عربی آیه 15'), findsOneWidget);
    expect(find.text('تفسیر آیه 15'), findsOneWidget);
    // Floating buttons in middle of surah show 'قبلی' and 'بعدی'
    expect(find.text('قبلی'), findsOneWidget);
    expect(find.text('بعدی'), findsOneWidget);
  });
}

class FakeSurahListController extends SurahListController {
  final List<SurahEntity> _mockSurahs;
  FakeSurahListController(this._mockSurahs);

  @override
  SurahListState build() {
    return SurahListState(surahs: _mockSurahs, isLoading: false);
  }
}

class FakeTafsirManagerController extends TafsirManagerController {
  final List<TafsirEntity> mockTafsirs;
  FakeTafsirManagerController(this.mockTafsirs);

  @override
  FutureOr<TafsirManagerState> build() {
    return TafsirManagerState(tafsirs: mockTafsirs);
  }
}
