import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/snackbars.dart';
import 'core/widgets/offline_banner.dart';

class SocietyCartApp extends ConsumerWidget {
  const SocietyCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: rootMessengerKey,
      builder: (context, child) =>
          OfflineAware(child: child ?? const SizedBox.shrink()),
    );
  }
}
