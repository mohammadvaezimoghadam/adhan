import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/search/domain/entities/search_filter_type.dart';
import 'package:quran/features/search/domain/entities/search_result_item.dart';
import 'package:quran/features/search/domain/repositories/i_search_repository.dart';
import 'package:quran/features/search/infrastructure/repositories/search_repository_impl.dart';
import 'package:quran/features/search/presentation/ui/search_screen.dart';

class FakeSearchRepository implements ISearchRepository {
  @override
  Future<List<SearchResultItem>> search({
    required String query,
    SearchFilterType filter = SearchFilterType.all,
  }) async => [];

  @override
  Future<List<String>> getRecentSearches() async => ['نور', 'کوثر'];

  @override
  Future<void> saveRecentSearch(String query) async {}

  @override
  Future<void> removeRecentSearch(String query) async {}

  @override
  Future<void> clearRecentSearches() async {}
}

void main() {
  testWidgets('SearchScreen renders unified Apple-grade header with title and back button', (tester) async {
    bool backClicked = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
        ],
        child: MaterialApp(
          home: SearchScreen(
            showBackButton: true,
            onBackPressed: () {
              backClicked = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title «جستجو» is rendered
    expect(find.text('جستجو'), findsOneWidget);

    // Verify back button is present and clickable
    final backBtn = find.byTooltip('بازگشت');
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pump();
    expect(backClicked, isTrue);

    // Verify Apple search input box is present with hint text
    expect(find.text('جستجو در سوره‌ها، آیات، ترجمه...'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.search), findsWidgets);
  });

  testWidgets('SearchScreen hides back button when showBackButton is false but keeps title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
        ],
        child: const MaterialApp(
          home: SearchScreen(
            showBackButton: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title «جستجو» is rendered
    expect(find.text('جستجو'), findsOneWidget);

    // Verify back button is NOT present
    expect(find.byTooltip('بازگشت'), findsNothing);
  });
}
