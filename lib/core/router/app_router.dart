import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/news/presentation/screens/article_detail_screen.dart';
import '../../features/news/presentation/screens/feed_screen.dart';
import '../../features/news/presentation/screens/search_screen.dart';
import '../../shared/domain/entities/article.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The router is created once; auth changes trigger a redirect re-evaluation
/// through [refreshListenable] instead of rebuilding the router.
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ValueNotifier<bool>(ref.read(authControllerProvider).isAuthenticated);
  ref
    ..listen<bool>(
      authControllerProvider.select((s) => s.isAuthenticated),
      (_, next) => isLoggedIn.value = next,
    )
    ..onDispose(isLoggedIn.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.feed,
    refreshListenable: isLoggedIn,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!isLoggedIn.value) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.feed;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.feed, builder: (context, state) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.search, builder: (context, state) => const SearchScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.favorites, builder: (context, state) => const FavoritesScreen())],
          ),
        ],
      ),
      // Full-screen route above the bottom bar.
      GoRoute(
        path: AppRoutes.article,
        parentNavigatorKey: _rootNavigatorKey,
        // `extra` is lost on cold deep links / restoration; fall back safely.
        redirect: (context, state) => state.extra is Article ? null : AppRoutes.feed,
        builder: (context, state) => ArticleDetailScreen(article: state.extra! as Article),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );

  ref.onDispose(router.dispose);
  return router;
});
