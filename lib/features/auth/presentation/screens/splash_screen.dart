import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/prefs_providers.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../data/models/app_user.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.elasticOut),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    final minDelay = Future<void>.delayed(AppConstants.splashDuration);

    User? user;
    try {
      user = await ref
          .read(authUserProvider.future)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      user = null;
    }

    AppUser? profile;
    if (user != null) {
      try {
        profile = await ref
            .read(currentAppUserProvider.future)
            .timeout(const Duration(seconds: 8));
        if (profile == null) {
          // First sign-in was interrupted before the profile was written.
          await ref.read(authRepositoryProvider).ensureUserDoc(user);
        }
      } catch (_) {
        // Offline or slow network: the router will retry once data arrives.
      }
    }

    await minDelay;
    if (!mounted) return;

    if (user == null) {
      final seen = ref.read(onboardingSeenProvider);
      context.go(seen ? Routes.login : Routes.onboarding);
    } else {
      context.go(profile?.isAdmin == true ? Routes.admin : Routes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(scale: _scale, child: const AppLogo(size: 96)),
            const SizedBox(height: Gap.l),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    AppStrings.tagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
