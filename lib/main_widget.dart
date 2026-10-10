import 'features/tafakor/application/controllers/tafakor_auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common/constants/app_constants.dart';
import 'core/routes/go_router_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/presentation/theme_controller.dart';

class MainWidget extends ConsumerWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm up Tafakor auth state eagerly at root level
    ref.watch(tafakorAuthControllerProvider);
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Color(0xFF1C1C1E),
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Color(0xFF1C1C1E),
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Color(0xFFFFFFFF),
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Color(0xFFFFFFFF),
                systemNavigationBarIconBrightness: Brightness.dark,
              );

        Widget content = child ?? const SizedBox.shrink();
        if (kIsWeb) {
          content = Container(
            color: isDark ? const Color(0xFF101716) : const Color(0xFFF0EAE1),
            child: content,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: content,
          ),
        );
      },
    );
  }
}
