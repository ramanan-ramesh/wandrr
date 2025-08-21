import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
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
          return RepositoryProvider<ApiServicesRepository>(
            create: (context) => state.apiServicesRepository,
            child: _createTripContentPage(TripPlannerPage()),
          );
        }
        return _createAnimatedLoadingScreen(context);
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
            if (state.tripEntityModificationData.isFromExplicitAction) {
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

  Widget _createAnimatedLoadingScreen(BuildContext context) {
    var currentState = BlocProvider.of<TripManagementBloc>(context).state;
    var textToDisplay = context.localizations.loading;
    if (currentState is LoadingTripManagement) {
      textToDisplay = context.localizations.loadingYourTrips;
    } else if (currentState is LoadedRepository) {
      textToDisplay = context.localizations.loadedYourTrips;
    } else if (currentState is LoadingTrip) {
      textToDisplay = context.localizations.loadingTripData;
    } else if (currentState is ActivatedTrip) {
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
          child: Text(
            textToDisplay,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _createTripContentPage(Widget contentPage) {
    return RepositoryProvider(
      create: (BuildContext context) => _tripRepository!,
      child: LayoutBuilder(builder: (context, constraints) {
        var contentPageLayoutConstraints =
            _calculateLayoutConstraints(constraints, context);
        return Scaffold(
          appBar: HomeAppBar(
            contentWidth: context.isBigLayout
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

  BoxConstraints? _calculateLayoutConstraints(
      BoxConstraints constraints, BuildContext context) {
    BoxConstraints? contentPageLayoutConstraints;
    if (constraints.maxWidth > TripProviderPageConstants.cutOffPageWidth) {
      context.isBigLayout = true;
    } else {
      context.isBigLayout = false;
      contentPageLayoutConstraints = const BoxConstraints(
          minWidth: 500, maxWidth: TripProviderPageConstants.maximumPageWidth);
    }
    return contentPageLayoutConstraints;
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
