import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/trip_provider.dart';

/// Route path constants
class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String trips = '/trips';
  static const String tripEditor = '/trips/:tripId';

  /// Generate trip editor path with specific trip ID
  static String tripEditorPath(String tripId) => '/trips/$tripId';
}

/// Creates and manages the app's router configuration
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
      routes: [
        // Root route - redirects based on auth state
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            final activeUser = appDataRepository.userManagement.activeUser;
            if (activeUser == null) {
              return const _PageShell(child: StartupPage());
            }
            return const _PageShell(child: TripProviderShell());
          },
        ),
        // Login route
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const _PageShell(child: LoginPage()),
        ),
        // Onboarding route
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => _PageShell(
            child: OnBoardingPage(
              onNavigateToNextPage: () {
                context.go(AppRoutes.login);
              },
            ),
          ),
        ),
        // Trips list route (requires auth)
        GoRoute(
          path: AppRoutes.trips,
          builder: (context, state) =>
              const _PageShell(child: TripProviderShell()),
        ),
        // Trip editor route (requires auth)
        GoRoute(
          path: AppRoutes.tripEditor,
          builder: (context, state) {
            final tripId = state.pathParameters['tripId'];
            return _PageShell(child: TripProviderShell(initialTripId: tripId));
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('The page "${state.uri.path}" does not exist.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.root),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final activeUser = appDataRepository.userManagement.activeUser;
    final isLoggedIn = activeUser != null;
    final currentPath = state.uri.path;

    // Define public routes that don't require authentication
    final publicRoutes = [
      AppRoutes.root,
      AppRoutes.login,
      AppRoutes.onboarding,
    ];

    // If user is logged in and trying to access login/onboarding, redirect to trips
    if (isLoggedIn &&
        (currentPath == AppRoutes.login ||
            currentPath == AppRoutes.onboarding)) {
      return AppRoutes.trips;
    }

    // If user is not logged in and trying to access protected routes
    if (!isLoggedIn && !publicRoutes.contains(currentPath)) {
      return AppRoutes.root;
    }

    return null; // No redirect needed
  }
}

/// A wrapper widget that provides the TripManagementBloc and handles
/// navigation between trips list and trip editor based on URL
class TripProviderShell extends StatelessWidget {
  final String? initialTripId;

  const TripProviderShell({super.key, this.initialTripId});

  @override
  Widget build(BuildContext context) {
    return TripProvider(initialTripId: initialTripId);
  }
}

/// A wrapper widget that provides consistent styling for all pages
class _PageShell extends StatelessWidget {
  final Widget child;

  const _PageShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DropdownButtonHideUnderline(
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
