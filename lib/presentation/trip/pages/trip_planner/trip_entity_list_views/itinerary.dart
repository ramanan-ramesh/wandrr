import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/editable_trip_entity/itinerary/itinerary.dart';

class ItineraryListView extends StatefulWidget {
  const ItineraryListView({super.key});

  @override
  State<ItineraryListView> createState() => _ItineraryListViewState();
}

class _ItineraryListViewState extends State<ItineraryListView> {
  late TripMetadataFacade _tripMetadataModelFacade;

  @override
  Widget build(BuildContext context) {
    _tripMetadataModelFacade = context.activeTrip.tripMetadata;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildItineraries,
      builder: (BuildContext context, TripManagementState state) {
        var activeTrip = context.activeTrip;
        var itineraryModelCollection = activeTrip.itineraryModelCollection;
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return PlatformTextElements.createHeader(
                  context: context, text: context.localizations.itinerary);
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
    if (currentState is UpdatedTripEntity<TripMetadataFacade> &&
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
