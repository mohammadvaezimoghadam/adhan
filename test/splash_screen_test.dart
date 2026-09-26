import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/common/constants/app_constants.dart';
import 'package:quran/features/splash/presentation/ui/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders background image and app title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial render and start animations
    await tester.pump(const Duration(milliseconds: 100));

    // Verify background image is present
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    expect((imageWidget.image as AssetImage).assetName,
        AppConstants.splashBgAsset);

    // Verify app title text is rendered
    expect(find.text(AppConstants.appTitle), findsOneWidget);

    // Advance time past the 1400ms timer
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
