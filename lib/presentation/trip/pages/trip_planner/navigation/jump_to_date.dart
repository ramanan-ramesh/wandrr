import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/bloc/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class JumpToDateNavigator<T extends TripEntity>
    extends AbstractPlatformDatePicker {
  final String section;
  final Iterable<T> Function() tripEntitiesGetter;

  const JumpToDateNavigator(
      {super.key, required this.section, required this.tripEntitiesGetter});

  @override
  State<JumpToDateNavigator> createState() => _JumpToDateNavigatorState();
}

class _JumpToDateNavigatorState<T extends TripEntity>
    extends State<JumpToDateNavigator> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (prev, current) {
        if (current.isTripEntityUpdated<T>()) {
          if (current is UpdatedTripEntity &&
              (current.dataState == DataState.create ||
                  current.dataState == DataState.update ||
                  current.dataState == DataState.delete)) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {},
      builder: (context, state) {
        var areThereTripEntities = widget.tripEntitiesGetter().isNotEmpty;
        if (areThereTripEntities) {
          return _createActionButton(context);
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _createActionButton(BuildContext context) {
    return FloatingActionButton(
      elevation: 0,
      onPressed: () {
        var datesToDisplay = _retrieveDatesToConsider(context).toList()
          ..sort((a, b) => a.compareTo(b));
        widget.showDatePickerDialog(
          context,
          (selectedDate) {
            context.addTripManagementEvent(
              NavigateToSection(
                section: widget.section,
                dateTime: selectedDate,
              ),
            );
          },
          calendarConfigCreator: (dialogContext) =>
              widget.createDatePickerConfig(dialogContext, context).copyWith(
                    firstDate: datesToDisplay.first,
                    lastDate: datesToDisplay.last,
                    selectableDayPredicate: (day) =>
                        datesToDisplay.any((x) => x.isOnSameDayAs(day)),
                  ),
        );
      },
      child: Icon(Icons.assistant_navigation),
    );
  }

  Iterable<DateTime> _retrieveDatesToConsider(BuildContext context) {
    var itineraries = context.activeTrip.itineraryModelCollection;
    var datesToConsider = HashSet<DateTime>();
    var tripEntities = widget.tripEntitiesGetter();
    if (tripEntities.first is ItineraryFacade) {
      return tripEntities.map((entity) => (entity as ItineraryFacade).day);
    }

    for (var itinerary in itineraries) {
      var day = itinerary.day;
      for (var tripEntity in tripEntities) {
        if (tripEntity is LodgingFacade) {
          if (itinerary.checkinLodging != null &&
              itinerary.checkinLodging!.id == tripEntity.id) {
            datesToConsider.add(day);
            break;
          } else if (itinerary.checkoutLodging != null &&
              itinerary.checkoutLodging!.id == tripEntity.id) {
            datesToConsider.add(day);
            break;
          }
        } else if (tripEntity is TransitFacade) {
          if (itinerary.transits
              .any((transit) => transit.id == tripEntity.id)) {
            datesToConsider.add(day);
            break;
          }
        } else if (tripEntity is ItineraryFacade) {
          if (itinerary.day.isOnSameDayAs(tripEntity.day)) {
            datesToConsider.add(day);
            break;
          }
        }
      }
    }
    return datesToConsider;
  }
}
