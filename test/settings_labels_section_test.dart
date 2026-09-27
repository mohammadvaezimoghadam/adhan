import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/settings/presentation/ui/settings_screen.dart';
import 'package:quran/features/subscription/application/vip_subscription_controller.dart';
import 'package:quran/features/subscription/domain/models/vip_subscription_state.dart';

class MockVipSubscriptionController extends VipSubscriptionController {
  @override
  VipSubscriptionState build() {
    return const VipSubscriptionState(isVip: false);
  }
}

void main() {
  testWidgets('SettingsScreen renders برچسب‌ها section and مدیریت برچسب‌ها tile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vipSubscriptionControllerProvider.overrideWith(
            () => MockVipSubscriptionController(),
          ),
          hasVipAccessProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          home: SettingsScreen(showBackButton: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify section header "برچسب‌ها" is present
    expect(find.text('برچسب‌ها'), findsOneWidget);

    // Verify tile "مدیریت برچسب‌ها" is present
    expect(find.text('مدیریت برچسب‌ها'), findsOneWidget);

    // Verify subtitle is present
    expect(find.text('ایجاد، ویرایش و حذف برچسب‌های نشانک'), findsOneWidget);
  });
}
