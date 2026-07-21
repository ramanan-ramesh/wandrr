import 'dart:async';

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
// PageShell - consistent Material/SafeArea wrapper for every route.
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
// InitialRedirectPage - navigates to /trips after the first frame.
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
// TripShell - owns the TripManagementBloc lifetime and the walk/wave
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

/// Walk -> Wave -> Done animation phases shown while the trip repository is
/// being set up. Progression is driven by a periodic poll (see
/// [_TripShellContentState._evaluateProgress]) rather than one-shot
/// listeners/timers, so it self-corrects regardless of *when* the
/// [TripManagementBloc] actually reaches [LoadedRepository] relative to
/// this widget's lifecycle (fresh page load, browser refresh, hot-restart,
/// slow network, etc.) instead of relying on catching a single transition
/// event at exactly the right moment.
enum _LoadingPhase { walk, wave, done }

class _TripShellContentState extends State<_TripShellContent> {
  static const _minimumAnimationTime = Duration(seconds: 2);
  static const _pollInterval = Duration(milliseconds: 150);
  static const _cutOffPageWidth = 1000.0;
  final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');
  TripRepositoryFacade? _tripRepository;
  _LoadingPhase _phase = _LoadingPhase.walk;
  DateTime _phaseStartedAt = DateTime.now();
  Timer? _pollTimer;
  @override
  void initState() {
    super.initState();
    // Even when the shell animation is skipped (navigating between /trips/*
    // sub-routes where the repository is normally already loaded), the
    // repository may still be null on a *fresh* page load/refresh directly
    // into a sub-route (e.g. opening /trips/:tripId/print in a new tab). In
    // that case we must still wait for LoadedRepository before rendering
    // widget.child - never eagerly mark ourselves done. _evaluateProgress
    // (called from didChangeDependencies/listener/poll) will fast-track to
    // `done` the moment the repository is available, without the minimum
    // animation delay.
    _walkAnimation.isActive = !widget.skipShellAnimation;
    _waveAnimation.isActive = false;
    _phaseStartedAt = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _evaluateProgress());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defensive catch-up: the TripManagementBloc may have already reached
    // LoadedRepository before this widget started listening (e.g. a
    // cached/singleton repository resolving synchronously on a fresh page
    // load or web hot-restart). Capture that directly instead of relying
    // solely on the BlocConsumer listener below to observe a *future*
    // transition.
    _tripRepository ??=
        _repositoryIfLoaded(context.read<TripManagementBloc>().state);
    _evaluateProgress();
  }

  TripRepositoryFacade? _repositoryIfLoaded(TripManagementState state) {
    return state is LoadedRepository ? state.tripRepository : null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listener: (context, state) {
        _tripRepository ??= _repositoryIfLoaded(state);
        _evaluateProgress();
      },
      builder: (context, state) {
        if (_phase != _LoadingPhase.done) {
          return PageShell(
            child: widget.skipShellAnimation
                ? const Center(child: CircularProgressIndicator())
                : _buildAnimatedLoadingScreen(context),
          );
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

  /// Re-evaluates whether the current loading phase should advance. Safe to
  /// call redundantly/idempotently from the poll timer, the bloc listener,
  /// and [didChangeDependencies] alike.
  void _evaluateProgress() {
    if (!mounted || _phase == _LoadingPhase.done) {
      return;
    }
    if (widget.skipShellAnimation) {
      if (_tripRepository != null) {
        _advanceTo(_LoadingPhase.done);
      }
      return;
    }
    final elapsedInPhase = DateTime.now().difference(_phaseStartedAt);
    if (elapsedInPhase < _minimumAnimationTime) {
      return;
    }
    if (_phase == _LoadingPhase.walk) {
      if (_tripRepository != null) {
        _advanceTo(_LoadingPhase.wave);
      }
    } else if (_phase == _LoadingPhase.wave) {
      _advanceTo(_LoadingPhase.done);
    }
  }

  void _advanceTo(_LoadingPhase phase) {
    if (phase == _LoadingPhase.done) {
      _pollTimer?.cancel();
    }
    setState(() {
      _phase = phase;
      _phaseStartedAt = DateTime.now();
      _walkAnimation.isActive = phase == _LoadingPhase.walk;
      _waveAnimation.isActive = phase == _LoadingPhase.wave;
    });
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
            _phase == _LoadingPhase.wave ? _waveAnimation : _walkAnimation,
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
}
