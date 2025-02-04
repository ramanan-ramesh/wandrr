import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ReadonlyTransitListItem extends StatelessWidget {
  TransitFacade transitModelFacade;

  ReadonlyTransitListItem({super.key, required this.transitModelFacade});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid =
        transitModelFacade.confirmationId?.isNotEmpty ?? false;
    var isNotesValid = transitModelFacade.notes?.isNotEmpty ?? false;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _TransitEvent(
                      isArrival: false, transitFacade: transitModelFacade),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _createTransitOption(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _TransitEvent(
                      isArrival: true, transitFacade: transitModelFacade),
                ),
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isNotesValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTitleSubText(context.localizations.notes,
                          transitModelFacade.notes!,
                          maxLines: null),
                    ),
                  if (isConfirmationIdValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTitleSubText(
                          '${context.localizations.confirmation} #',
                          transitModelFacade.confirmationId!),
                    ),
                  if (isConfirmationIdValid) Divider(),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ExpenditureEditTile(
                          expenseUpdator: transitModelFacade.expense,
                          isEditable: false),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String? _getTransitOperator() {
    if (transitModelFacade.transitOption == TransitOption.Flight) {
      return transitModelFacade.operator!;
    } else {
      return transitModelFacade.operator;
    }
  }

  Widget _createTitleSubText(String title, String subtitle,
      {int? maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(2.0),
          child: FittedBox(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(2.0),
          child: Text(
            subtitle,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }

  Widget _createTransitOption(BuildContext context) {
    var transitOptionMetadata = context.activeTrip.transitOptionMetadatas
        .firstWhere((element) =>
            element.transitOption == transitModelFacade.transitOption);
    var transitOperator = _getTransitOperator();
    if (transitOperator != null) {
      var isBigLayout = context.isBigLayout;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isBigLayout) Expanded(child: Container()),
          Flexible(
            child: Column(
              children: [
                IgnorePointer(
                    child: IconButton(
                        onPressed: null,
                        icon: Icon(transitOptionMetadata.icon))),
                Text(
                  transitOptionMetadata.name,
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Divider(),
          ),
          Flexible(
            child: Wrap(
              children: [
                Text(transitOperator),
              ],
            ),
          ),
          if (isBigLayout) Expanded(child: Container()),
        ],
      );
    }
    return Column(
      children: [
        IgnorePointer(
            child: IconButton(
                onPressed: null, icon: Icon(transitOptionMetadata.icon))),
        Text(transitOptionMetadata.name)
      ],
    );
  }
}

class _TransitEvent extends StatelessWidget {
  final bool isArrival;
  final TransitFacade transitFacade;

  _TransitEvent(
      {super.key, required this.isArrival, required this.transitFacade});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Text(
            isArrival
                ? context.localizations.arrive
                : context.localizations.depart,
            style: Theme.of(context).textTheme.titleLarge!,
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createLocationDetailTitle(context),
          ),
        ),
      ],
    );
  }

  String _createLocationTitle() {
    var locationToConsider = isArrival
        ? transitFacade.arrivalLocation!
        : transitFacade.departureLocation!;
    if (transitFacade.transitOption == TransitOption.Flight) {
      return (locationToConsider.context as AirportLocationContext).airportCode;
    } else {
      return locationToConsider.toString();
    }
  }

  Widget _createLocationDetailTitle(BuildContext context) {
    var subTitle = _createLocationSubtitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Wrap(
            children: [
              PlatformTextElements.createSubHeader(
                  context: context,
                  text: _createLocationTitle(),
                  shouldBold: true),
            ],
          ),
        ),
        if (subTitle != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(subTitle),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            _createDateTimeDetail(),
          ),
        ),
      ],
    );
  }

  String _createDateTimeDetail() {
    var dateTimeToConsider = isArrival
        ? transitFacade.arrivalDateTime!
        : transitFacade.departureDateTime!;

    var dayText = DateFormat('dd MMMM').format(dateTimeToConsider);
    var timeText =
        "${dateTimeToConsider.hour.toString().padLeft(2, '0')} : ${dateTimeToConsider.minute.toString().padLeft(2, '0')}";
    var dateTimeText = 'on $dayText @ $timeText';
    if (isArrival) {
      var numberOfDays = transitFacade.departureDateTime!
          .calculateDaysInBetween(transitFacade.arrivalDateTime!,
              includeExtraDay: false);
      if (numberOfDays > 0) {
        dateTimeText += _convertToSuperScript('+$numberOfDays');
      }
    }
    return dateTimeText;
  }

  String? _createLocationSubtitle() {
    String? subTitle;
    var locationToConsider = isArrival
        ? transitFacade.arrivalLocation!
        : transitFacade.departureLocation!;
    if (transitFacade.transitOption == TransitOption.Flight) {
      subTitle = locationToConsider.context.name;
    } else if (locationToConsider.context.locationType != LocationType.City) {
      subTitle = locationToConsider.context.city;
    }
    return subTitle;
  }
}

String _convertToSuperScript(String numberOfTravelDaysDenotation) {
  var superScriptText = '';
  for (var character in numberOfTravelDaysDenotation.characters) {
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
