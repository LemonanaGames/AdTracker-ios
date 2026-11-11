import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/create/create_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/home/home_screen.dart';
import '../features/life/gear_screen.dart';
import '../features/life/life_screen.dart';
import '../features/life/skills_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/social/post_detail_screen.dart';
import '../features/social/social_screen.dart';
import 'app_shell.dart';
import 'providers.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const create = '/create';
  static const social = '/social';
  static const deals = '/deals';
  static const life = '/life';
  static const gear = '/life/gear';
  static const skills = '/life/skills';
  static String post(String postId) => '/social/post/$postId';
  static String socialFor(String network) => '/social?network=$network';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects only when "has a life" flips.
  final hasLife = ValueNotifier<bool>(ref.read(gameControllerProvider).hasLife);
  ref
    ..listen(gameControllerProvider.select((s) => s.hasLife), (_, next) => hasLife.value = next)
    ..onDispose(hasLife.dispose);

  final router = GoRouter(
    initialLocation: hasLife.value ? Routes.home : Routes.onboarding,
    refreshListenable: hasLife,
    redirect: (context, state) {
      final onboarding = state.matchedLocation == Routes.onboarding;
      if (!hasLife.value && !onboarding) return Routes.onboarding;
      if (hasLife.value && onboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.create, builder: (_, _) => const CreateScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.social,
                builder: (_, state) => SocialScreen(initialNetwork: state.uri.queryParameters['network']),
                routes: [
                  GoRoute(
                    path: 'post/:postId',
                    builder: (_, state) => PostDetailScreen(postId: state.pathParameters['postId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.deals, builder: (_, _) => const DealsScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.life,
                builder: (_, _) => const LifeScreen(),
                routes: [
                  GoRoute(path: 'gear', builder: (_, _) => const GearScreen()),
                  GoRoute(path: 'skills', builder: (_, _) => const SkillsScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
