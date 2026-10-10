import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/search/presentation/widgets/search_recent_history_view.dart';

void main() {
  testWidgets(
      'SearchRecentHistoryView renders very long search term without overflow on narrow screens',
      (tester) async {
    const veryLongTerm =
        'قُلْ يَا أَيُّهَا الْكَافِرُونَ لَا أَعْبُدُ مَا تَعْبُدُونَ وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ وَلَا أَنَا عَابِدٌ مَا عَبَدْتُمْ وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ لَكُمْ دِينُكُمْ وَلِيَ دِينِ یک عبارت طولانی تستی برای بررسی سرریز متن در سابقه جستجو';

    for (final width in [280.0, 320.0, 360.0, 480.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: SearchRecentHistoryView(
                recentSearches: const [
                  veryLongTerm,
                  'کوتاه',
                  'یک عبارت متوسط جستجو',
                  'عبارت فوق العاده طولانی دیگری که ممکن است کاربر از قرآن یا تفاسیر سرچ کند تا آیه‌ای پیدا کند',
                ],
                onSearchSelected: (_) {},
                onRemoveSearch: (_) {},
                onClearAll: () {},
              ),
            ),
          ),
        ),
      );

      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) {
        errors.add(details);
        FlutterError.presentError(details);
      };

      await tester.pumpAndSettle();

      expect(errors, isEmpty, reason: 'Overflow occurred at width $width');
      expect(find.text('جستجوهای اخیر'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    }
  });
}
