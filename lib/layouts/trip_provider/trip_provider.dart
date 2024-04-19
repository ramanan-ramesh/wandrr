import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_planner_page.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'home_page/home_page.dart';

class TripProvider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("TripProvider-build");
    return FutureBuilder(
      future: TripManagement.createInstance(
          RepositoryProvider.of<PlatformDataRepository>(context)
              .appLevelData
              .activeUser!),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return RepositoryProvider<TripManagement>(
            create: (context) => snapshot.data!,
            child: BlocProvider<TripManagementBloc>(
              create: (context) => TripManagementBloc(
                  RepositoryProvider.of<TripManagement>(context)),
              child: BlocConsumer<TripManagementBloc, TripManagementState>(
                buildWhen: (previousState, currentState) {
                  if (currentState is LoadedTripMetadatas ||
                      currentState is LoadedTrip) {
                    return true;
                  }
                  return false;
                },
                builder: (context, state) {
                  print('builder of TripProvider created for state - ${state}');
                  if (state is LoadedTripMetadatas) {
                    return HomePage();
                  } else if (state is LoadedTrip) {
                    return TripPlannerPage(); // TODO: How to improve this page routing logic?
                  } else
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                },
                listener: (context, state) {},
              ),
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
