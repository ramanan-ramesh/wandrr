import 'dart:async';

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
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/data/trip/services/budgeting_service.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/print_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/trip_print_loading_shell.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';

/// Route path constants
class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String trips = '/trips';
  static const String tripEditor = '/trips/:tripId';
  static const String printTrip = '/trips/:tripId/print';

  /// Generate trip editor path with specific trip ID
  static String tripEditorPath(String tripId) => '/trips/$tripId';

  /// Generate print trip path with specific trip ID
  static String printTripPath(String tripId) => '/trips/$tripId/print';
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
        // ShellRoute for trip-related pages - keeps TripManagementBloc alive.
        // Detects if initial route is a specific trip to skip shell animation.
        ShellRoute(
          builder: (context, state, child) {
            final isTripEditorRoute = state.uri.path != AppRoutes.trips &&
                state.uri.path.startsWith('/trips/');
            return _TripShell(
              skipShellAnimation: isTripEditorRoute,
              child: child,
            );
          },
          routes: [
            // Trips list route
            GoRoute(
              path: AppRoutes.trips,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const _TripsListPage(),
                transitionDuration: const Duration(milliseconds: 380),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder: (context, animation, secondary, child) =>
                    FadeTransition(
                  opacity:
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: child,
                ),
              ),
            ),
            // Trip editor route — immersive hero-like transition
            GoRoute(
              path: AppRoutes.tripEditor,
              pageBuilder: (context, state) {
                final tripId = state.pathParameters['tripId']!;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: _TripEditorPage(tripId: tripId),
                  transitionDuration: const Duration(milliseconds: 450),
                  reverseTransitionDuration: const Duration(milliseconds: 320),
                  transitionsBuilder: (context, animation, secondary, child) {
                    // Slide from right
                    final slide = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic));
                    // Fade in
                    final fade = CurvedAnimation(
                        parent: animation, curve: Curves.easeOut);
                    // Subtle scale from 0.96 to 1.0
                    final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
                        CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic));
                    return FadeTransition(
                      opacity: fade,
                      child: ScaleTransition(
                        scale: scale,
                        child: SlideTransition(position: slide, child: child),
                      ),
                    );
                  },
                );
              },
            ),
            // Print trip page route
            GoRoute(
              path: AppRoutes.printTrip,
              pageBuilder: (context, state) {
                final tripId = state.pathParameters['tripId']!;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: _TripPrintPage(tripId: tripId),
                  transitionDuration: const Duration(milliseconds: 380),
                  reverseTransitionDuration: const Duration(milliseconds: 280),
                  transitionsBuilder: (context, animation, secondary, child) =>
                      FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation, curve: Curves.easeOut),
                    child: child,
                  ),
                );
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
  final bool skipShellAnimation;

  const _TripShell({required this.child, this.skipShellAnimation = false});

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
      _bloc = TripManagementBloc(currentUserName);
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
      child: _TripShellContent(
        skipShellAnimation: widget.skipShellAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Content of the trip shell that listens to bloc state for loading animation.
///
/// When [skipShellAnimation] is true (direct navigation to a trip editor URL),
/// the shell animation is skipped entirely — the child route (e.g. _TripEditorPage)
/// handles its own loading animation so there's only one set of animations.
class _TripShellContent extends StatefulWidget {
  final Widget child;
  final bool skipShellAnimation;

  const _TripShellContent({
    required this.child,
    this.skipShellAnimation = false,
  });

  @override
  State<_TripShellContent> createState() => _TripShellContentState();
}

class _TripShellContentState extends State<_TripShellContent> {
  static const _minimumAnimationTime = Duration(seconds: 2);
  final _minimumWalkTimeCompletionNotifier = ValueNotifier(false);
  TripRepositoryFacade? _tripRepository;
  bool _isInitialLoadComplete = false;
  static const _cutOffPageWidth = 1000.0;

  final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');

  @override
  void initState() {
    super.initState();
    if (widget.skipShellAnimation) {
      // Skip animation — mark animations as inactive; _isInitialLoadComplete
      // will be set to true when LoadedRepository arrives.
      _walkAnimation.isActive = false;
      _waveAnimation.isActive = false;
    } else {
      _tryStartWalkAnimation();
    }
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
          if (widget.skipShellAnimation) {
            // Skip animation entirely — go straight to loaded state
            setState(() {
              _isInitialLoadComplete = true;
            });
          } else {
            _tryStopWalkStartWaveAnimation();
          }
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
                context.isBigLayout = constraints.maxWidth >= _cutOffPageWidth;
                return widget.child;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLoadingScreen(BuildContext context) {
    final state = context.tripManagementState;
    var textToDisplay = context.localizations.loading;

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
      final bloc = context.tripManagementBloc;
      final state = context.tripManagementState;
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

/// Trip editor page widget that handles loading a specific trip.
/// Shows available trip metadata immediately; content shimmers until fully loaded.
class _TripEditorPage extends StatefulWidget {
  final String tripId;

  const _TripEditorPage({required this.tripId});

  @override
  State<_TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<_TripEditorPage> {
  bool _hasTriedLoadingTrip = false;
  ApiServicesRepositoryFacade? _apiServicesRepository;
  BudgetingServiceFacade? _budgetingService;
  TripMetadataFacade? _loadingMetadata;

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
      _apiServicesRepository = null;
      _budgetingService = null;
      _loadingMetadata = null;
      _tryLoadTrip();
    }
  }

  void _tryLoadTrip() {
    if (_hasTriedLoadingTrip) {
      return;
    }

    final state = context.tripManagementState;
    if (state is LoadedRepository ||
        state is NavigateToHome ||
        state is UpdatedTripEntity) {
      _loadTripById();
    } else if (state is ActivatedTrip) {
      final tripRepo = context.tripRepository;
      if (tripRepo.activeTrip?.tripMetadata.id != widget.tripId) {
        _loadTripById();
      } else {
        _hasTriedLoadingTrip = true;
      }
    } else if (state is LoadingTripManagement || state is LoadingTrip) {
      // Handled by listener
    } else {
      _loadTripById();
    }
  }

  void _loadTripById() {
    _hasTriedLoadingTrip = true;
    final tripRepo = context.tripRepository;
    final tripMetadata = tripRepo.tripMetadataCollection.items
        .where((trip) => trip.id == widget.tripId)
        .firstOrNull;
    if (tripMetadata != null) {
      _loadingMetadata = tripMetadata;
      context.addTripManagementEvent(
        LoadTrip(tripMetadata: tripMetadata, shouldActivateTrip: true),
      );
    } else {
      context.go(AppRoutes.trips);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listenWhen: (_, current) =>
          current is LoadedRepository ||
          current is NavigateToHome ||
          current is ActivatedTrip ||
          current is LoadingTrip,
      listener: (context, state) {
        if (state is LoadingTrip) {
          setState(() => _loadingMetadata = state.tripMetadataFacade);
        } else if ((state is LoadedRepository || state is NavigateToHome) &&
            !_hasTriedLoadingTrip) {
          _tryLoadTrip();
        } else if (state is ActivatedTrip) {
          setState(() {
            _apiServicesRepository = state.apiServicesRepository;
            _budgetingService = state.budgetingService;
          });
        }
      },
      builder: (context, state) {
        if (state is NavigateToHome || state is LoadedRepository) {
          _apiServicesRepository = null;
          _budgetingService = null;
          return const SizedBox.shrink();
        }

        final repos = _apiServicesRepository;
        final service = _budgetingService;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
          child: (repos != null && service != null)
              ? KeyedSubtree(
                  key: const ValueKey('trip_editor_ready'),
                  child: MultiRepositoryProvider(
                    providers: [
                      RepositoryProvider<ApiServicesRepositoryFacade>.value(
                          value: repos),
                      RepositoryProvider<BudgetingServiceFacade>.value(
                          value: service),
                    ],
                    child: const TripEditorPage(),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('trip_editor_skeleton'),
                  child: _TripLoadingSkeleton(metadata: _loadingMetadata),
                ),
        );
      },
    );
  }
}

class _TripPrintPage extends StatefulWidget {
  final String tripId;

  const _TripPrintPage({required this.tripId});

  @override
  State<_TripPrintPage> createState() => _TripPrintPageState();
}

class _TripPrintPageState extends State<_TripPrintPage> {
  static const _kMinLoadingShellDuration = Duration(seconds: 2);

  bool _hasTriedLoadingTrip = false;
  bool _minLoadingDurationPassed = false;
  TripMetadataFacade? _loadingMetadata;
  Timer? _loadingShellTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingShellMinimumDelay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryLoadTrip();
  }

  @override
  void didUpdateWidget(covariant _TripPrintPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) {
      _hasTriedLoadingTrip = false;
      _minLoadingDurationPassed = false;
      _loadingMetadata = null;
      _startLoadingShellMinimumDelay();
      _tryLoadTrip();
    }
  }

  @override
  void dispose() {
    _loadingShellTimer?.cancel();
    super.dispose();
  }

  void _startLoadingShellMinimumDelay() {
    _loadingShellTimer?.cancel();
    _loadingShellTimer = Timer(_kMinLoadingShellDuration, () {
      if (!mounted) {
        return;
      }
      setState(() => _minLoadingDurationPassed = true);
    });
  }

  void _tryLoadTrip() {
    if (_hasTriedLoadingTrip) {
      return;
    }

    final state = context.tripManagementState;
    if (state is LoadedRepository ||
        state is NavigateToHome ||
        state is UpdatedTripEntity) {
      _loadTripById();
    } else if (state is ActivatedTrip) {
      final activeTripId = context.tripRepository.activeTrip?.tripMetadata.id;
      if (activeTripId == widget.tripId) {
        _hasTriedLoadingTrip = true;
      } else {
        _loadTripById();
      }
    } else if (state is LoadingTripManagement || state is LoadingTrip) {
      // Listener below handles this.
    } else {
      _loadTripById();
    }
  }

  void _loadTripById() {
    _hasTriedLoadingTrip = true;
    final tripRepo = context.tripRepository;
    final tripMetadata = tripRepo.tripMetadataCollection.items
        .where((trip) => trip.id == widget.tripId)
        .firstOrNull;

    if (tripMetadata == null) {
      context.go(AppRoutes.trips);
      return;
    }

    context.addTripManagementEvent(
      LoadTrip(tripMetadata: tripMetadata, shouldActivateTrip: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listenWhen: (_, current) =>
          current is LoadedRepository ||
          current is NavigateToHome ||
          current is ActivatedTrip ||
          current is LoadingTrip,
      listener: (context, state) {
        if (state is LoadingTrip) {
          setState(() => _loadingMetadata = state.tripMetadataFacade);
        } else if ((state is LoadedRepository || state is NavigateToHome) &&
            !_hasTriedLoadingTrip) {
          _tryLoadTrip();
        }
      },
      builder: (context, state) {
        if (state is NavigateToHome || state is LoadedRepository) {
          return const SizedBox.shrink();
        }

        final activeTrip = context.tripRepository.activeTrip;
        final canRenderPrintPage =
            activeTrip?.tripMetadata.id == widget.tripId &&
                _minLoadingDurationPassed;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
          child: canRenderPrintPage
              ? KeyedSubtree(
                  key: const ValueKey('print_page_ready'),
                  child: PrintPage(tripData: activeTrip!),
                )
              : KeyedSubtree(
                  key: const ValueKey('print_page_loading'),
                  child: TripPrintLoadingShell(metadata: _loadingMetadata),
                ),
        );
      },
    );
  }
}

/// Skeleton scaffold shown while trip services are initialising.
/// Displays available metadata (name, dates) immediately and uses
/// shimmer placeholders for content that isn't yet available.
class _TripLoadingSkeleton extends StatelessWidget {
  final TripMetadataFacade? metadata;

  const _TripLoadingSkeleton({this.metadata});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accentColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.home_rounded, color: isLight ? Colors.white : null),
        backgroundColor: isLight ? AppColors.brandPrimary : null,
        title: metadata != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metadata!.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLight ? Colors.white : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metadata!.startDate != null && metadata!.endDate != null)
                    Text(
                      '${_fmt(metadata!.startDate!)} – ${_fmt(metadata!.endDate!)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isLight
                            ? Colors.white.withValues(alpha: 0.85)
                            : null,
                      ),
                    ),
                ],
              )
            : ShimmerPlaceholder(
                width: 160,
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isBigLayout = constraints.maxWidth >= 900;

          Widget itinerarySkeleton() {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                          child: ShimmerPlaceholder(
                            height: 36,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: accentColor.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                    children: [
                      for (var i = 0; i < 2; i++) ...[
                        _TripTimelineSkeletonItem(
                            index: i, accentColor: accentColor),
                        const SizedBox(height: 12),
                      ],
                      ShimmerPlaceholder(
                        height: 68,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(height: 12),
                      ShimmerPlaceholder(
                        height: 72,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          Widget expenseListSkeleton() {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
              itemCount: 4,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ShimmerPlaceholder(
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          if (isBigLayout) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  Expanded(child: itinerarySkeleton()),
                  const SizedBox(width: 8),
                  Expanded(child: expenseListSkeleton()),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(child: itinerarySkeleton()),
              SizedBox(
                height: 230,
                child: expenseListSkeleton(),
              ),
            ],
          );
        },
      ),
      // Loading indicator in the bottom-centre where FAB would appear
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: ShimmerPlaceholder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _TripTimelineSkeletonItem extends StatelessWidget {
  final int index;
  final Color accentColor;

  const _TripTimelineSkeletonItem({
    required this.index,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final height = 72.0 + (index % 3) * 20.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            ShimmerPlaceholder(
              width: 12,
              height: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            Container(
              width: 2,
              height: height - 12,
              color: accentColor.withValues(alpha: 0.15),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShimmerPlaceholder(
            height: height,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
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
