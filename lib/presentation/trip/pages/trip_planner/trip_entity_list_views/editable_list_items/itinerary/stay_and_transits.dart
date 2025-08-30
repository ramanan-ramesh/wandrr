import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class ItineraryStayAndTransits extends StatelessWidget {
  final DateTime itineraryDay;

  const ItineraryStayAndTransits({required this.itineraryDay, super.key});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadatas = context.activeTrip.transitOptionMetadatas;
    var appLocalizations = context.localizations;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var itinerary = context.activeTrip.itineraryCollection
            .getItineraryForDay(itineraryDay);
        var transits = itinerary.transits.toList()
          ..sort((transit1, transit2) => transit1.departureDateTime!
              .compareTo(transit2.departureDateTime!));
        var lodgingAndEventDescriptions = <LodgingFacade, String>{};
        if (itinerary.fullDayLodging != null) {
          lodgingAndEventDescriptions[itinerary.fullDayLodging!] =
              appLocalizations.allDayStay;
        } else if (itinerary.checkinLodging != null) {
          if (itinerary.checkoutLodging != null) {
            lodgingAndEventDescriptions[itinerary.checkoutLodging!] =
                appLocalizations.checkOut;
            lodgingAndEventDescriptions[itinerary.checkinLodging!] =
                appLocalizations.checkIn;
          } else {
            lodgingAndEventDescriptions[itinerary.checkinLodging!] =
                appLocalizations.checkIn;
          }
        } else if (itinerary.checkoutLodging != null) {
          lodgingAndEventDescriptions[itinerary.checkoutLodging!] =
              appLocalizations.checkOut;
        }
        return _buildStayAndTransitsListView(
            transits,
            lodgingAndEventDescriptions,
            transitOptionMetadatas,
            appLocalizations);
      },
      buildWhen: _shouldBuildTransitAndLodgingItinerary,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildStayAndTransitsListView(
      List<TransitFacade> transits,
      Map<LodgingFacade, String> lodgingAndEventDescriptions,
      Iterable<TransitOptionMetadata> transitOptionMetadatas,
      AppLocalizations appLocalizations) {
    var numberOfItems = transits.length + lodgingAndEventDescriptions.length;
    return ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        itemBuilder: (BuildContext context, int index) {
          if (lodgingAndEventDescriptions.isNotEmpty) {
            var relativeIndex = numberOfItems - index;
            if (relativeIndex <= lodgingAndEventDescriptions.length) {
              var lodgingEntry = lodgingAndEventDescriptions.entries.elementAt(
                  lodgingAndEventDescriptions.length - relativeIndex);
              return _buildLodging(
                  context, lodgingEntry.key, lodgingEntry.value);
            }
          }
          var transitListElement = transits.elementAt(index);
          var transitOptionMetadata = transitOptionMetadatas.firstWhere(
              (e) => e.transitOption == transitListElement.transitOption);
          return _buildTransit(transitListElement, transitOptionMetadata,
              appLocalizations, context);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
        },
        itemCount: numberOfItems);
  }

  bool _shouldBuildTransitAndLodgingItinerary(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      var currentLodgingState = currentState as UpdatedTripEntity;
      var updatedLodging = currentLodgingState
          .tripEntityModificationData.modifiedCollectionItem as LodgingFacade;
      if (currentLodgingState.dataState == DataState.create ||
          currentLodgingState.dataState == DataState.delete ||
          currentLodgingState.dataState == DataState.update) {
        var isLodgingEventOnSameDay =
            updatedLodging.checkinDateTime!.isOnSameDayAs(itineraryDay) ||
                updatedLodging.checkoutDateTime!.isOnSameDayAs(itineraryDay);
        return isLodgingEventOnSameDay;
      }
    }
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      var currentTransitState = currentState as UpdatedTripEntity;
      var updatedTransit = currentTransitState
          .tripEntityModificationData.modifiedCollectionItem as TransitFacade;
      if (currentTransitState.dataState == DataState.create ||
          currentTransitState.dataState == DataState.delete ||
          currentTransitState.dataState == DataState.update) {
        var isItineraryDayOnOrAfterDeparture =
            itineraryDay.isAtSameMomentAs(updatedTransit.departureDateTime!) ||
                itineraryDay.isAfter(updatedTransit.departureDateTime!);
        var isItineraryDayOnOrBeforeArrival =
            itineraryDay.isAtSameMomentAs(updatedTransit.arrivalDateTime!) ||
                itineraryDay.isBefore(updatedTransit.arrivalDateTime!);
        return isItineraryDayOnOrAfterDeparture &&
            isItineraryDayOnOrBeforeArrival;
      }
    }
    return false;
  }

  Widget _buildLodging(
      BuildContext context, LodgingFacade lodging, String lodgingEvent) {
    var locationDetail = lodging.location!.context.name;
    var lodgingCity = lodging.location!.context.city;
    if (lodgingCity != null) {
      locationDetail += ', $lodgingCity';
    }
    return _buildItineraryItem(
        context, Icons.hotel_rounded, locationDetail, lodgingEvent);
  }

  Widget _buildTransit(
      TransitFacade transitFacade,
      TransitOptionMetadata transitOptionMetadata,
      AppLocalizations appLocalizations,
      BuildContext context) {
    var locationDetail = _getTransitLocationDetail(transitFacade);
    var dateTimeDetail =
        _getTransitDateTimeDetail(transitFacade, appLocalizations);

    return _buildItineraryItem(
        context, transitOptionMetadata.icon, locationDetail, dateTimeDetail);
  }

  Widget _buildItineraryItem(
      BuildContext context, IconData icon, String title, String trailing) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: null,
                    iconSize: 30,
                    icon: Icon(icon),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Wrap(
                        children: [
                          Text(title),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 3.0, left: 3.0, bottom: 3.0, right: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(trailing),
              ),
            )
          ],
        ),
        const Positioned.fill(
          left: 30,
          child: ListTile(
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.green,
                width: 2.0,
              ),
            ),
          ),
        )
      ],
    );
  }

  String _getTransitLocationDetail(TransitFacade transitFacade) {
    String departureLocationTitle, arrivalLocationTitle;
    if (transitFacade.transitOption == TransitOption.flight) {
      departureLocationTitle =
          (transitFacade.departureLocation!.context as AirportLocationContext)
              .city;
      arrivalLocationTitle =
          (transitFacade.arrivalLocation!.context as AirportLocationContext)
              .city;
    } else {
      departureLocationTitle = transitFacade.departureLocation.toString();
      arrivalLocationTitle = transitFacade.arrivalLocation.toString();
    }
    return '$departureLocationTitle to $arrivalLocationTitle';
  }

  String _getTransitDateTimeDetail(
      TransitFacade transitFacade, AppLocalizations appLocalizations) {
    var dateTimeFormat = DateFormat('h:mm a');
    var departureDateTime = transitFacade.departureDateTime!;
    var arrivalDateTime = transitFacade.arrivalDateTime!;
    if (departureDateTime.isOnSameDayAs(arrivalDateTime)) {
      return '${dateTimeFormat.format(departureDateTime)} - ${dateTimeFormat.format(arrivalDateTime)}';
    } else {
      if (departureDateTime.isOnSameDayAs(itineraryDay) &&
          !arrivalDateTime.isOnSameDayAs(itineraryDay)) {
        return '${appLocalizations.departAt} ${dateTimeFormat.format(departureDateTime)}';
      } else if (!departureDateTime.isOnSameDayAs(itineraryDay) &&
          arrivalDateTime.isOnSameDayAs(itineraryDay)) {
        return '${appLocalizations.arriveAt} ${dateTimeFormat.format(arrivalDateTime)}';
      } else {
        return appLocalizations.allDayTravel;
      }
    }
  }
}
