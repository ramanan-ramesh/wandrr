import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/constants.dart';

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
            // If authenticated at root, redirect to trips
            return const _PageShell(child: _InitialRedirect());
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
        // ShellRoute for trip-related pages - keeps TripManagementBloc alive
        ShellRoute(
          builder: (context, state, child) {
            return _TripShell(child: child);
          },
          routes: [
            // Trips list route
            GoRoute(
              path: AppRoutes.trips,
              builder: (context, state) => const _TripsListPage(),
            ),
            // Trip editor route
            GoRoute(
              path: AppRoutes.tripEditor,
              builder: (context, state) {
                final tripId = state.pathParameters['tripId'];
                return _TripEditorPage(tripId: tripId!);
              },
            ),
          ],
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

/// Widget that redirects to trips on first frame
class _InitialRedirect extends StatefulWidget {
  const _InitialRedirect();

  @override
  State<_InitialRedirect> createState() => _InitialRedirectState();
}

class _InitialRedirectState extends State<_InitialRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.trips);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Shell widget that provides TripManagementBloc to all trip routes
/// This ensures the bloc is created only once and persists across navigation
class _TripShell extends StatefulWidget {
  final Widget child;

  const _TripShell({required this.child});

  @override
  State<_TripShell> createState() => _TripShellState();
}

class _TripShellState extends State<_TripShell> {
  TripManagementBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create bloc only once, using didChangeDependencies to safely access inherited widgets
    if (_bloc == null) {
      final currentUserName = context.activeUser!.userName;
      final localizations = context.localizations;
      _bloc = TripManagementBloc(currentUserName, localizations);
    }
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bloc == null) {
      return const SizedBox.shrink();
    }

    return BlocProvider<TripManagementBloc>.value(
      value: _bloc!,
      child: _TripShellContent(child: widget.child),
    );
  }
}

/// Content of the trip shell that listens to bloc state for loading animation
class _TripShellContent extends StatefulWidget {
  final Widget child;

  const _TripShellContent({required this.child});

  @override
  State<_TripShellContent> createState() => _TripShellContentState();
}

class _TripShellContentState extends State<_TripShellContent> {
  static const _minimumAnimationTime = Duration(seconds: 2);
  final _minimumWalkTimeCompletionNotifier = ValueNotifier(false);
  TripRepositoryFacade? _tripRepository;
  bool _isInitialLoadComplete = false;

  final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');

  @override
  void initState() {
    super.initState();
    _tryStartWalkAnimation();
  }

  @override
  void dispose() {
    _minimumWalkTimeCompletionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listener: (context, state) {
        if (state is LoadedRepository) {
          _tripRepository = state.tripRepository;
          _tryStopWalkStartWaveAnimation();
        }
      },
      builder: (context, state) {
        // Show loading animation only during initial repository load
        if (!_isInitialLoadComplete ||
            _walkAnimation.isActive ||
            _waveAnimation.isActive) {
          return _PageShell(
            child: _buildAnimatedLoadingScreen(context),
          );
        }

        // Once loaded, provide the repository and show the child route
        return _PageShell(
          child: RepositoryProvider<TripRepositoryFacade>.value(
            value: _tripRepository!,
            child: LayoutBuilder(
              builder: (context, constraints) {
                context.isBigLayout = constraints.maxWidth >=
                    TripProviderPageConstants.cutOffPageWidth;
                return widget.child;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLoadingScreen(BuildContext context) {
    final state = context.read<TripManagementBloc>().state;
    String textToDisplay = context.localizations.loading;

    if (state is LoadingTripManagement) {
      textToDisplay = context.localizations.loadingYourTrips;
    } else if (state is LoadedRepository) {
      textToDisplay = context.localizations.loadedYourTrips;
    }

    return Stack(
      children: [
        RiveAnimation.asset(
          Assets.walkAnimation,
          fit: BoxFit.fitHeight,
          controllers: [
            _minimumWalkTimeCompletionNotifier.value
                ? _waveAnimation
                : _walkAnimation
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              textToDisplay,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _tryStartWalkAnimation() {
    _walkAnimation.isActive = true;
    _waveAnimation.isActive = false;
    _minimumWalkTimeCompletionNotifier.value = false;
    Future.delayed(_minimumAnimationTime, () {
      if (mounted) {
        _minimumWalkTimeCompletionNotifier.value = true;
        // Check if we should transition to wave animation
        if (_tripRepository != null) {
          _onWalkAnimationComplete();
        }
      }
    });
  }

  void _tryStopWalkStartWaveAnimation() {
    if (_minimumWalkTimeCompletionNotifier.value) {
      _onWalkAnimationComplete();
    } else {
      _minimumWalkTimeCompletionNotifier.addListener(_onWalkAnimationComplete);
    }
  }

  void _onWalkAnimationComplete() {
    _minimumWalkTimeCompletionNotifier.removeListener(_onWalkAnimationComplete);
    if (_minimumWalkTimeCompletionNotifier.value && mounted) {
      setState(() {
        _walkAnimation.isActive = false;
        _waveAnimation.isActive = true;
      });
      Future.delayed(_minimumAnimationTime, () {
        if (mounted) {
          setState(() {
            _waveAnimation.isActive = false;
            _isInitialLoadComplete = true;
          });
        }
      });
    }
  }
}

/// Trips list page widget
class _TripsListPage extends StatefulWidget {
  const _TripsListPage();

  @override
  State<_TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<_TripsListPage> {
  @override
  void initState() {
    super.initState();
    // Unload any active trip when navigating to the trips list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<TripManagementBloc>();
      final state = bloc.state;
      // If there's an active trip, go back to home state
      if (state is ActivatedTrip || state is LoadingTrip) {
        bloc.add(const GoToHome());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

/// Trip editor page widget that handles loading a specific trip
class _TripEditorPage extends StatefulWidget {
  final String tripId;

  const _TripEditorPage({required this.tripId});

  @override
  State<_TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<_TripEditorPage> {
  static const _minimumAnimationTime = Duration(seconds: 2);
  final _minimumWalkTimeCompletionNotifier = ValueNotifier(false);
  bool _hasTriedLoadingTrip = false;
  bool _isLoadingComplete = false;
  ApiServicesRepositoryFacade? _apiServicesRepository;

  final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  @override
  void dispose() {
    _minimumWalkTimeCompletionNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryLoadTrip();
  }

  @override
  void didUpdateWidget(covariant _TripEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) {
      _hasTriedLoadingTrip = false;
      _isLoadingComplete = false;
      _startLoadingAnimation();
      _tryLoadTrip();
    }
  }

  void _startLoadingAnimation() {
    _walkAnimation.isActive = true;
    _waveAnimation.isActive = false;
    _minimumWalkTimeCompletionNotifier.value = false;
    Future.delayed(_minimumAnimationTime, () {
      if (mounted) {
        _minimumWalkTimeCompletionNotifier.value = true;
        // Check if trip is already loaded
        final state = context.read<TripManagementBloc>().state;
        if (state is ActivatedTrip) {
          _onWalkAnimationComplete();
        }
      }
    });
  }

  void _tryStopWalkStartWaveAnimation() {
    if (_minimumWalkTimeCompletionNotifier.value) {
      _onWalkAnimationComplete();
    } else {
      _minimumWalkTimeCompletionNotifier.addListener(_onWalkAnimationComplete);
    }
  }

  void _onWalkAnimationComplete() {
    _minimumWalkTimeCompletionNotifier.removeListener(_onWalkAnimationComplete);
    if (_minimumWalkTimeCompletionNotifier.value && mounted) {
      setState(() {
        _walkAnimation.isActive = false;
        _waveAnimation.isActive = true;
      });
      Future.delayed(_minimumAnimationTime, () {
        if (mounted) {
          setState(() {
            _waveAnimation.isActive = false;
            _isLoadingComplete = true;
          });
        }
      });
    }
  }

  void _tryLoadTrip() {
    if (_hasTriedLoadingTrip) return;

    final bloc = context.read<TripManagementBloc>();
    final state = bloc.state;

    // If we have a loaded repository or are in a state where we can load a trip
    if (state is LoadedRepository ||
        state is NavigateToHome ||
        state is UpdatedTripEntity) {
      _loadTripById();
    } else if (state is ActivatedTrip) {
      // Already viewing a trip - check if it's the right one
      final tripRepo = context.read<TripRepositoryFacade>();
      if (tripRepo.activeTrip?.tripMetadata.id != widget.tripId) {
        _loadTripById();
      } else {
        _hasTriedLoadingTrip = true;
        _tryStopWalkStartWaveAnimation();
      }
    } else if (state is LoadingTripManagement || state is LoadingTrip) {
      // Still loading, will be handled by listener
    } else {
      // For any other state, try to load the trip
      _loadTripById();
    }
  }

  void _loadTripById() {
    _hasTriedLoadingTrip = true;
    final tripRepo = context.read<TripRepositoryFacade>();
    final tripMetadata = tripRepo.tripMetadataCollection.collectionItems
        .where((trip) => trip.id == widget.tripId)
        .firstOrNull;

    if (tripMetadata != null) {
      context
          .read<TripManagementBloc>()
          .add(LoadTrip(tripMetadata: tripMetadata));
    } else {
      // Trip not found, redirect to trips list
      context.go(AppRoutes.trips);
    }
  }

  Widget _buildAnimatedLoadingScreen(BuildContext context) {
    final state = context.read<TripManagementBloc>().state;
    String textToDisplay = context.localizations.loadingTripData;

    if (state is ActivatedTrip) {
      textToDisplay = context.localizations.launchingTrip;
    }

    return Stack(
      children: [
        RiveAnimation.asset(
          Assets.walkAnimation,
          fit: BoxFit.fitHeight,
          controllers: [
            _minimumWalkTimeCompletionNotifier.value
                ? _waveAnimation
                : _walkAnimation
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              textToDisplay,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listenWhen: (previous, current) =>
          current is LoadedRepository ||
          current is NavigateToHome ||
          current is ActivatedTrip,
      listener: (context, state) {
        // If we're back to a loaded state and haven't tried loading, try now
        if ((state is LoadedRepository || state is NavigateToHome) &&
            !_hasTriedLoadingTrip) {
          _tryLoadTrip();
        } else if (state is ActivatedTrip) {
          // Store the API services repository for later use
          _apiServicesRepository = state.apiServicesRepository;
          _tryStopWalkStartWaveAnimation();
        }
      },
      builder: (context, state) {
        // When navigating away (state is NavigateToHome or LoadedRepository),
        // don't show animation - just show an empty placeholder since we're leaving
        if (state is NavigateToHome || state is LoadedRepository) {
          _apiServicesRepository = null;
          return const SizedBox.shrink();
        }

        // Show animation while loading or completing the animation
        if (!_isLoadingComplete ||
            _walkAnimation.isActive ||
            _waveAnimation.isActive) {
          return _buildAnimatedLoadingScreen(context);
        }

        // Use stored API services repository if available (handles UpdatedTripEntity states)
        if (_apiServicesRepository != null) {
          return RepositoryProvider<ApiServicesRepositoryFacade>.value(
            value: _apiServicesRepository!,
            child: const TripEditorPage(),
          );
        }

        // If ActivatedTrip state, store and use the repository
        if (state is ActivatedTrip) {
          _apiServicesRepository = state.apiServicesRepository;
          return RepositoryProvider<ApiServicesRepositoryFacade>.value(
            value: _apiServicesRepository!,
            child: const TripEditorPage(),
          );
        }

        // Fallback for other states (e.g., LoadingTrip) - show animation
        return _buildAnimatedLoadingScreen(context);
      },
    );
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
