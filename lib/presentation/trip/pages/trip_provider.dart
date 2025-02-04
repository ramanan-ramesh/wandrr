import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_planner_page.dart';

class TripProvider extends StatelessWidget {
  TripRepositoryFacade? _tripRepository;

  @override
  Widget build(BuildContext pageContext) {
    var currentUserName = pageContext.activeUser!.userName;
    return BlocProvider<TripManagementBloc>(
      create: (BuildContext context) =>
          TripManagementBloc(currentUserName, pageContext.localizations),
      child: BlocConsumer<TripManagementBloc, TripManagementState>(
        builder: (BuildContext context, TripManagementState state) {
          if (state is LoadedRepository) {
            _tripRepository = state.tripRepository;
            return RepositoryProvider(
              create: (context) => _tripRepository!,
              child: HomePage(),
            );
          } else if (state is NavigateToHome) {
            return RepositoryProvider(
                create: (context) => _tripRepository!, child: HomePage());
          } else if (state is ActivatedTrip) {
            return RepositoryProvider(
                create: (context) => _tripRepository!,
                child: TripPlannerPage());
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        buildWhen: (previousState, currentState) {
          return currentState is LoadedRepository ||
              currentState is Loading ||
              currentState is NavigateToHome ||
              currentState is ActivatedTrip;
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
          }
        },
      ),
    );
  }
}
