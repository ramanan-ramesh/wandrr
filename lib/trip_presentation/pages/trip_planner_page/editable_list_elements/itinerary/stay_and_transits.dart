import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/location/airport_location_context.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/transit_option_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

class ItineraryStayAndTransits extends StatelessWidget {
  final DateTime itineraryDay;

  ItineraryStayAndTransits({super.key, required this.itineraryDay});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadatas = context.getActiveTrip().transitOptionMetadatas;
    var appLocalizations = context.withLocale();
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var itinerary = context
            .getActiveTrip()
            .itineraryModelCollection
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
        padding: EdgeInsets.symmetric(vertical: 3.0),
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
          return Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
        },
        itemCount: numberOfItems);
  }

  bool _shouldBuildTransitAndLodgingItinerary(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<LodgingFacade>()) {
      var currentLodgingState = currentState as UpdatedTripEntity;
      var updatedLodging = currentLodgingState
          .tripEntityModificationData.modifiedCollectionItem as LodgingFacade;
      if (currentLodgingState.dataState == DataState.Create ||
          currentLodgingState.dataState == DataState.Delete ||
          currentLodgingState.dataState == DataState.Update) {
        var isLodgingEventOnSameDay =
            updatedLodging.checkinDateTime!.isOnSameDayAs(itineraryDay) ||
                updatedLodging.checkoutDateTime!.isOnSameDayAs(itineraryDay);
        return isLodgingEventOnSameDay;
      }
    }
    if (currentState.isTripEntity<TransitFacade>()) {
      var currentTransitState = currentState as UpdatedTripEntity;
      var updatedTransit = currentTransitState
          .tripEntityModificationData.modifiedCollectionItem as TransitFacade;
      if (currentTransitState.dataState == DataState.Create ||
          currentTransitState.dataState == DataState.Delete ||
          currentTransitState.dataState == DataState.Update) {
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
        IconButton.filledTonal(
          onPressed: null,
          iconSize: 30,
          icon: Icon(icon),
        ),
        Positioned.fill(
          left: 30,
          child: ListTile(
            tileColor: Colors.white12,
            shape: StadiumBorder(
              side: BorderSide(
                width: 2.0,
                color: Colors.green,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PlatformTextElements.createSubHeader(
                      context: context, text: title),
                ),
              ),
            ),
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(trailing),
            ),
          ),
        ),
      ],
    );
  }

  String _getTransitLocationDetail(TransitFacade transitFacade) {
    String departureLocationTitle, arrivalLocationTitle;
    if (transitFacade.transitOption == TransitOption.Flight) {
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
        var numberOfTravelDays =
            arrivalDateTime.calculateDaysInBetween(departureDateTime);
        return '${appLocalizations.arriveAt}${_convertToSuperScript('+$numberOfTravelDays')} ${dateTimeFormat.format(arrivalDateTime)}';
      } else {
        return appLocalizations.allDayTravel;
      }
    }
  }

  String _convertToSuperScript(String numberOfTravelDayDenotation) {
    var superScriptText = '';
    for (var character in numberOfTravelDayDenotation.characters) {
      if (character == ' ') {
        superScriptText += ' ';
      } else {
        superScriptText += _unicodeMap[character]!;
      }
    }
    return superScriptText;
  }

  final _unicodeMap = {
    '0': ('\u2070'),
    '1': ('\u00B9'),
    '2': ('\u00B2'),
    '3': ('\u00B3'),
    '4': ('\u2074'),
    '5': ('\u2075'),
    '6': ('\u2076'),
    '7': ('\u2077'),
    '8': ('\u2078'),
    '9': ('\u2079'),
    '+': '\u207A',
    '(': '\u207D',
    ')': '\u207E',
  };
}
