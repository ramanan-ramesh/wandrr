import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/shimmer.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/constants.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_planner_page.dart';

class TripProvider extends StatelessWidget {
  @override
  Widget build(BuildContext pageContext) {
    var currentUserName = pageContext.activeUser!.userName;
    return BlocProvider<TripManagementBloc>(
      create: (BuildContext context) =>
          TripManagementBloc(currentUserName, pageContext.localizations),
      child: _TripProviderContentPage(),
    );
  }
}

class _TripProviderContentPage extends StatefulWidget {
  const _TripProviderContentPage({super.key});

  @override
  State<_TripProviderContentPage> createState() =>
      _TripProviderContentPageState();
}

class _TripProviderContentPageState extends State<_TripProviderContentPage> {
  TripRepositoryFacade? _tripRepository;
  static const _assetImage = 'assets/images/plan_itinerary.jpg';
  static const _minimumShimmerTime = Duration(seconds: 2);
  var _hasMinimumShimmerTimePassed = false;

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<TripManagementBloc>(context).state
        is LoadingTripManagement) {
      if (!_hasMinimumShimmerTimePassed) {
        _tryTriggerStartAnimation();
      }
    }
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        if ((state is LoadedRepository) && _hasMinimumShimmerTimePassed) {
          _tripRepository = state.tripRepository;
          return _createTripContentPage(HomePage());
        } else if (state is NavigateToHome && _hasMinimumShimmerTimePassed) {
          return _createTripContentPage(HomePage());
        } else if (state is ActivatedTrip && _hasMinimumShimmerTimePassed) {
          return _createTripContentPage(TripPlannerPage());
        }
        return Shimmer(
          child: Image.asset(
            _assetImage,
            fit: BoxFit.fitHeight,
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState != previousState &&
                currentState is LoadedRepository ||
            currentState is LoadingTripManagement ||
            currentState is NavigateToHome ||
            currentState is ActivatedTrip ||
            currentState is LoadingTrip;
      },
      listener: (context, state) {
        if (state.isTripEntityUpdated<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = state as UpdatedTripEntity;
          if (tripMetadataUpdatedState.dataState == DataState.Create) {
            context.addTripManagementEvent(LoadTrip(
                tripMetadata: tripMetadataUpdatedState
                    .tripEntityModificationData.modifiedCollectionItem));
          }
          if (tripMetadataUpdatedState.dataState == DataState.Delete) {
            if (state.tripEntityModificationData.isFromEvent) {
              context.addTripManagementEvent(GoToHome());
            }
          }
        } else if (state is LoadingTripManagement) {
          _tryTriggerStartAnimation();
        } else if (state is LoadingTrip) {
          _tryTriggerStartAnimation();
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
          contentPageLayoutConstraints = BoxConstraints(
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

  void _tryTriggerStartAnimation() {
    _hasMinimumShimmerTimePassed = false;
    Future.delayed(_minimumShimmerTime, () {
      setState(() {
        _hasMinimumShimmerTimePassed = true;
      });
    });
  }
}
