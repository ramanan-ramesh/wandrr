import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/database_connectors/data_states.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_entity_facades/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/layouts/trip_provider/home_page/home_page.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_planner_page.dart';
import 'package:wandrr/repositories/trip_management/trip_repository.dart';

class TripProvider extends StatelessWidget {
  TripRepositoryImplementation? _tripRepositoryImplementation;
  TripManagementBloc? _tripManagementBloc;

  @override
  Widget build(BuildContext context) {
    print("TripProvider-build");
    var platformDataRepository = context.getPlatformDataRepository();
    var platformUser = context.getAppLevelData().activeUser!;
    return FutureBuilder(
      future: TripRepositoryImplementation.createInstanceAsync(
          userName: platformUser.userName,
          currencyConverter: platformDataRepository.currencyConverter),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done &&
            _tripRepositoryImplementation == null) {
          _tripRepositoryImplementation = snapshot.data!;
          return RepositoryProvider<TripRepositoryFacade>(
            create: (context) => _tripRepositoryImplementation!,
            child: BlocProvider<TripManagementBloc>(
              create: (context) {
                if (_tripManagementBloc != null) {
                  return _tripManagementBloc!;
                }
                _tripManagementBloc = TripManagementBloc(snapshot.data!,
                    platformDataRepository.appData.activeUser!.userName);
                return _tripManagementBloc!;
              },
              child: _TripProviderContentPage(),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class _TripProviderContentPage extends StatelessWidget {
  const _TripProviderContentPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is NavigateToHome || currentState is ActivatedTrip) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        print('builder of TripProvider created for state - ${state}');
        if (state is NavigateToHome) {
          return HomePage();
        } else if (state is ActivatedTrip) {
          return TripPlannerPage(); // TODO: How to improve page routing logic?
        } else {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
      listener: (context, state) {
        if (state.isTripEntity<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = state as UpdatedTripEntity;
          if (tripMetadataUpdatedState.dataState == DataState.Create) {
            context.addTripManagementEvent(LoadTrip(
                tripMetadata: tripMetadataUpdatedState
                    .tripEntityModificationData.modifiedCollectionItem));
          }
        }
      },
    );
  }
}
