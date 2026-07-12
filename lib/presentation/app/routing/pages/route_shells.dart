import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';

// ---------------------------------------------------------------------------
// PageShell — consistent Material/SafeArea wrapper for every route.
// ---------------------------------------------------------------------------

class PageShell extends StatelessWidget {
  final Widget child;

  const PageShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DropdownButtonHideUnderline(
        child: SafeArea(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// InitialRedirectPage — navigates to /trips after the first frame.
// ---------------------------------------------------------------------------

class InitialRedirectPage extends StatefulWidget {
  const InitialRedirectPage({super.key});

  @override
  State<InitialRedirectPage> createState() => _InitialRedirectPageState();
}

class _InitialRedirectPageState extends State<InitialRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.trips);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// TripShell — owns the TripManagementBloc lifetime and the walk/wave
// loading animation shown while the trip repository is being set up.
// ---------------------------------------------------------------------------

class TripShell extends StatefulWidget {
  final Widget child;
  final bool skipShellAnimation;

  const TripShell({
    required this.child,
    this.skipShellAnimation = false,
    super.key,
  });

  @override
  State<TripShell> createState() => _TripShellState();
}

class _TripShellState extends State<TripShell> {
  TripManagementBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= TripManagementBloc(context.activeUser!.userName);
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
  static const _cutOffPageWidth = 1000.0;

  final _minimumWalkTimeCompletionNotifier = ValueNotifier(false);
  final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');

  TripRepositoryFacade? _tripRepository;
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.skipShellAnimation) {
      _walkAnimation.isActive = false;
      _waveAnimation.isActive = false;
    } else {
      _startWalkAnimation();
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
        if (state is! LoadedRepository) {
          return;
        }
        _tripRepository = state.tripRepository;
        if (widget.skipShellAnimation) {
          setState(() => _isInitialLoadComplete = true);
        } else {
          _transitionFromWalkToWave();
        }
      },
      builder: (context, state) {
        final shouldShowShell = !_isInitialLoadComplete ||
            _walkAnimation.isActive ||
            _waveAnimation.isActive;

        if (shouldShowShell) {
          return PageShell(child: _buildAnimatedLoadingScreen(context));
        }

        return PageShell(
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
    var text = context.localizations.loading;
    if (state is LoadingTripManagement) {
      text = context.localizations.loadingYourTrips;
    } else if (state is LoadedRepository) {
      text = context.localizations.loadedYourTrips;
    }

    return Stack(
      children: [
        RiveAnimation.asset(
          Assets.walkAnimation,
          fit: BoxFit.fitHeight,
          controllers: [
            _minimumWalkTimeCompletionNotifier.value
                ? _waveAnimation
                : _walkAnimation,
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              text,
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

  void _startWalkAnimation() {
    _walkAnimation.isActive = true;
    _waveAnimation.isActive = false;
    _minimumWalkTimeCompletionNotifier.value = false;

    Future.delayed(_minimumAnimationTime, () {
      if (!mounted) {
        return;
      }
      _minimumWalkTimeCompletionNotifier.value = true;
      if (_tripRepository != null) {
        _onWalkAnimationComplete();
      }
    });
  }

  void _transitionFromWalkToWave() {
    if (_minimumWalkTimeCompletionNotifier.value) {
      _onWalkAnimationComplete();
    } else {
      _minimumWalkTimeCompletionNotifier.addListener(_onWalkAnimationComplete);
    }
  }

  void _onWalkAnimationComplete() {
    _minimumWalkTimeCompletionNotifier.removeListener(_onWalkAnimationComplete);
    if (!_minimumWalkTimeCompletionNotifier.value || !mounted) {
      return;
    }

    setState(() {
      _walkAnimation.isActive = false;
      _waveAnimation.isActive = true;
    });

    Future.delayed(_minimumAnimationTime, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _waveAnimation.isActive = false;
        _isInitialLoadComplete = true;
      });
    });
  }
}
