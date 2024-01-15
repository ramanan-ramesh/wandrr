import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'itinerary_list_item.dart';

class ItineraryListView extends StatefulWidget {
  const ItineraryListView({super.key});

  @override
  State<ItineraryListView> createState() => _ItineraryListViewState();
}

class _ItineraryListViewState extends State<ItineraryListView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        } else if (currentState is UpdatedTripMetadata) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        var activeTrip =
            RepositoryProvider.of<TripManagement>(context).activeTrip!;
        var itineraries = activeTrip.itineraries;
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return PlatformTextElements.createHeader(
                  context: context,
                  text: AppLocalizations.of(context)!.itinerary);
            } else
              return ItineraryListItem(
                  itineraryFacade: itineraries.elementAt(index - 1));
          },
          separatorBuilder: (BuildContext context, int index) {
            return Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
          },
          itemCount: activeTrip.itineraries.length + 1,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
