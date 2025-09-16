import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/trip_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/itinerary/itinerary.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

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
        var itineraryModelCollection =
            activeTrip.itineraryCollection.toList(growable: false);
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: PlatformTextElements.createHeader(
                  context: context, text: context.localizations.itinerary),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              sliver: SliverList.builder(
                itemCount: itineraryModelCollection.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: ItineraryListItem(
                        itineraryFacade: itineraryModelCollection[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state is ProcessSectionNavigation &&
            state.section.toLowerCase() ==
                NavigationSections.itinerary.toLowerCase()) {
          if (state.dateTime == null) {
            unawaited(context.tripNavigator.jumpToList(context));
          }
        }
      },
    );
  }

  //TODO: List not rebuilt when trip dates are changed. Especially when a date is removed
  bool _shouldBuildItineraries(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is UpdatedTripEntity<TripMetadataFacade> &&
        currentState.dataState == DataState.update) {
      var modifiedTripMetadata =
          currentState.tripEntityModificationData.modifiedCollectionItem;
      var areStartDatesSame = modifiedTripMetadata.startDate!
          .isOnSameDayAs(_tripMetadataModelFacade.startDate!);
      var areEndDatesSame = modifiedTripMetadata.endDate!
          .isOnSameDayAs(_tripMetadataModelFacade.endDate!);
      _tripMetadataModelFacade = modifiedTripMetadata.clone();
      return !areStartDatesSame || !areEndDatesSame;
    }
    return false;
  }
}
