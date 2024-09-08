import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/platform_elements/text.dart';

import 'itinerary_list_item.dart';

class ItineraryListView extends StatefulWidget {
  const ItineraryListView({super.key});

  @override
  State<ItineraryListView> createState() => _ItineraryListViewState();
}

class _ItineraryListViewState extends State<ItineraryListView> {
  late TripMetadataModelFacade _tripMetadataModelFacade;

  @override
  Widget build(BuildContext context) {
    _tripMetadataModelFacade = context.getActiveTrip().tripMetadata;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildItineraries,
      builder: (BuildContext context, TripManagementState state) {
        var activeTrip = context.getActiveTrip();
        var itineraryModelCollection = activeTrip.itineraryModelCollection;
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return PlatformTextElements.createHeader(
                  context: context,
                  text: AppLocalizations.of(context)!.itinerary);
            } else {
              return ItineraryListItem(
                  itineraryFacade: itineraryModelCollection[index - 1]);
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            return Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
          },
          itemCount: itineraryModelCollection.length + 1,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildItineraries(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is UpdatedTripEntity<TripMetadataModelFacade> &&
        currentState.dataState == DataState.Update) {
      var modifiedTripMetadata =
          currentState.tripEntityModificationData.modifiedCollectionItem;
      var areStartDatesSame = modifiedTripMetadata.startDate!
          .isOnSameDayAs(_tripMetadataModelFacade.startDate!);
      var areEndDatesSame = modifiedTripMetadata.endDate!
          .isOnSameDayAs(_tripMetadataModelFacade.endDate!);
      _tripMetadataModelFacade = modifiedTripMetadata;
      return !areStartDatesSame || !areEndDatesSame;
    }
    return false;
  }
}
