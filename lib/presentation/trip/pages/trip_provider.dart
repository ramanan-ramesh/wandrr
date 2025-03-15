import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/constants.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_planner_page.dart';

class TripProvider extends StatelessWidget {
  const TripProvider({super.key});

  @override
  Widget build(BuildContext pageContext) {
    var currentUserName = pageContext.activeUser!.userName;
    return BlocProvider<TripManagementBloc>(
      create: (BuildContext context) =>
          TripManagementBloc(currentUserName, pageContext.localizations),
      child: const _TripProviderContentPage(),
    );
  }
}

class _TripProviderContentPage extends StatefulWidget {
  const _TripProviderContentPage();

  @override
  State<_TripProviderContentPage> createState() =>
      _TripProviderContentPageState();
}

class _TripProviderContentPageState extends State<_TripProviderContentPage> {
  TripRepositoryFacade? _tripRepository;
  static const _minimumAnimationTime = Duration(seconds: 2);
  final _minimumWalkTimeCompletionNotifier = ValueNotifier(false);
  static final _walkAnimation = SimpleAnimation('Walk');
  final _waveAnimation = SimpleAnimation('Wave');

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<TripManagementBloc>(context).state
        is LoadingTripManagement) {
      if (!_minimumWalkTimeCompletionNotifier.value) {
        _tryStartWalkAnimation();
      }
    }
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        if ((state is LoadedRepository) &&
            !_walkAnimation.isActive &&
            !_waveAnimation.isActive) {
          return _createTripContentPage(const HomePage());
        } else if (state is NavigateToHome &&
            !_walkAnimation.isActive &&
            !_waveAnimation.isActive) {
          return _createTripContentPage(const HomePage());
        } else if (state is ActivatedTrip &&
            !_walkAnimation.isActive &&
            !_waveAnimation.isActive) {
          return _createTripContentPage(const TripPlannerPage());
        }
        return RiveAnimation.asset(
          'assets/walk_animation.riv',
          fit: BoxFit.fitHeight,
          controllers: [
            _minimumWalkTimeCompletionNotifier.value
                ? _waveAnimation
                : _walkAnimation
          ],
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState != previousState &&
                currentState is LoadedRepository ||
            currentState is LoadingTripManagement ||
            currentState is NavigateToHome ||
            currentState is ActivatedTrip ||
            currentState is LoadingTrip &&
                !_walkAnimation.isActive &&
                !_waveAnimation.isActive;
      },
      listener: (context, state) {
        if (state.isTripEntityUpdated<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = state as UpdatedTripEntity;
          if (tripMetadataUpdatedState.dataState == DataState.create) {
            context.addTripManagementEvent(LoadTrip(
                tripMetadata: tripMetadataUpdatedState
                    .tripEntityModificationData.modifiedCollectionItem));
          }
          if (tripMetadataUpdatedState.dataState == DataState.delete) {
            if (state.tripEntityModificationData.isFromEvent) {
              context.addTripManagementEvent(GoToHome());
            }
          }
        } else if (state is LoadingTripManagement) {
          _tryStartWalkAnimation();
        } else if (state is LoadingTrip) {
          _tryStartWalkAnimation();
        } else if (state is LoadedRepository) {
          _tripRepository = state.tripRepository;
          _tryStopWalkStartWaveAnimation();
        } else if (state is ActivatedTrip) {
          _tryStopWalkStartWaveAnimation();
        }
      },
    );
  }

  Widget _createTripContentPage(Widget contentPage) {
    return RepositoryProvider(
      create: (BuildContext context) => _tripRepository!,
      child: LayoutBuilder(builder: (context, constraints) {
        var appLevelData = context.appDataModifier;
        BoxConstraints? contentPageLayoutConstraints;
        if (constraints.maxWidth > TripProviderPageConstants.cutOffPageWidth) {
          appLevelData.isBigLayout = true;
        } else {
          appLevelData.isBigLayout = false;
          contentPageLayoutConstraints = const BoxConstraints(
              minWidth: 500,
              maxWidth: TripProviderPageConstants.maximumPageWidth);
        }
        return Scaffold(
          appBar: HomeAppBar(
            contentWidth: appLevelData.isBigLayout
                ? TripProviderPageConstants.maximumPageWidth
                : null,
          ),
          body: Center(
            child: Container(
              constraints: contentPageLayoutConstraints,
              child: contentPage,
            ),
          ),
        );
      }),
    );
  }

  void _tryStartWalkAnimation() {
    _walkAnimation.isActive = true;
    _waveAnimation.isActive = false;
    _minimumWalkTimeCompletionNotifier.value = false;
    setState(() {
      Future.delayed(_minimumAnimationTime, () {
        _minimumWalkTimeCompletionNotifier.value = true;
      });
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
    if (_minimumWalkTimeCompletionNotifier.value) {
      setState(() {
        _walkAnimation.isActive = false;
        _waveAnimation.isActive = true;
        Future.delayed(_minimumAnimationTime, () {
          _waveAnimation.isActive = false;
          setState(() {});
        });
      });
    }
  }
}
