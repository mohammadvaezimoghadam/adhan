import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/common/constants/app_constants.dart';
import 'package:quran/features/splash/presentation/ui/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders plain white screen and app title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial render and start animations
    await tester.pump(const Duration(milliseconds: 100));

    // Verify background image is NOT present
    expect(find.byType(Image), findsNothing);

    // Verify Scaffold background is white
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(Colors.white));

    // Verify app title text is rendered
    expect(find.text(AppConstants.appTitle), findsOneWidget);

    // Verify 'گروه تفکر' brand text is rendered at bottom
    expect(find.text('گروه تفکر'), findsOneWidget);

    // Advance time past the 1400ms timer
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
