import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/print_page.dart';

import 'app_routes.dart';
import 'pages/not_found_route_page.dart';
import 'pages/route_shells.dart';
import 'pages/trip_route_pages.dart';

class AppRouter {
  final AppDataFacade appDataRepository;
  late final GoRouter router;

  AppRouter({required this.appDataRepository}) {
    router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.root,
      debugLogDiagnostics: true,
      redirect: _handleRedirect,
      routes: _routes,
      errorBuilder: (context, state) => NotFoundRoutePage(path: state.uri.path),
    );
  }

  List<RouteBase> get _routes {
    return [
      GoRoute(path: AppRoutes.root, builder: _buildRootPage),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PageShell(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => PageShell(
          child: OnBoardingPage(
            onNavigateToNextPage: () => context.go(AppRoutes.login),
          ),
        ),
      ),
      ShellRoute(
        builder: _buildTripShell,
        routes: [
          GoRoute(
            path: AppRoutes.trips,
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.tripEditor,
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return _tripEditorPage(state: state, tripId: tripId);
            },
          ),
          GoRoute(
            path: AppRoutes.printTrip,
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return _fadePage(
                state: state,
                child: PrintTripPage(tripId: tripId),
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildRootPage(BuildContext context, GoRouterState state) {
    final hasActiveUser = appDataRepository.userManagement.activeUser != null;
    return PageShell(
      child: hasActiveUser ? const InitialRedirectPage() : const StartupPage(),
    );
  }

  Widget _buildTripShell(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final shouldSkipShellAnimation = state.uri.path != AppRoutes.trips &&
        state.uri.path.startsWith('/trips/');
    return TripShell(
      skipShellAnimation: shouldSkipShellAnimation,
      child: child,
    );
  }

  CustomTransitionPage<void> _fadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      child: child,
    );
  }

  CustomTransitionPage<void> _tripEditorPage({
    required GoRouterState state,
    required String tripId,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: TripEditorRoutePage(tripId: tripId),
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final activeUser = appDataRepository.userManagement.activeUser;
    final isLoggedIn = activeUser != null;
    final currentPath = state.uri.path;

    const publicRoutes = [
      AppRoutes.root,
      AppRoutes.login,
      AppRoutes.onboarding,
    ];

    if (isLoggedIn &&
        (currentPath == AppRoutes.login ||
            currentPath == AppRoutes.onboarding)) {
      return AppRoutes.trips;
    }

    if (!isLoggedIn && !publicRoutes.contains(currentPath)) {
      return AppRoutes.root;
    }

    return null;
  }
}
