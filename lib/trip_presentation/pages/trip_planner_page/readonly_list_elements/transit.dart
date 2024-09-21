import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/location/airport_location_context.dart';
import 'package:wandrr/trip_data/models/location/location.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/transit_option_metadata.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expenditure_edit_tile/expenditure_edit_tile.dart';

class ReadonlyTransitListItem extends StatelessWidget {
  TransitFacade transitModelFacade;
  Iterable<TransitOptionMetadata> transitOptionMetadatas;

  ReadonlyTransitListItem(
      {super.key,
      required this.transitModelFacade,
      required this.transitOptionMetadatas});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid =
        transitModelFacade.confirmationId?.isNotEmpty ?? false;
    var isNotesValid = transitModelFacade.notes.isNotEmpty;
    return IntrinsicHeight(
      child: Row(
        // TODO: Is IntrinsicHeight needed here?
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.withLocale().depart,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.green),
                ),
                Text(
                  context.withLocale().arrive,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: _createLocationDetailTitle(context, false),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTransitOption(context),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: _createLocationDetailTitle(context, true),
                  ),
                ],
              ),
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
                      child: _createTitleSubText(
                          context.withLocale().notes, transitModelFacade.notes,
                          maxLines: null),
                    ),
                  if (isConfirmationIdValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTitleSubText(
                          '${context.withLocale().confirmation} #',
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
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _createLocationDetailTitle(BuildContext context, bool isArrival) {
    String locationTitle;
    var locationToConsider = isArrival
        ? transitModelFacade.arrivalLocation!
        : transitModelFacade.departureLocation!;
    var dateTimeToConsider = isArrival
        ? transitModelFacade.arrivalDateTime!
        : transitModelFacade.departureDateTime!;
    if (transitModelFacade.transitOption == TransitOption.Flight) {
      locationTitle =
          (locationToConsider.context as AirportLocationContext).airportCode;
    } else {
      locationTitle = locationToConsider.toString();
    }

    var dayText = DateFormat('dd MMMM').format(dateTimeToConsider);
    var timeText =
        "${dateTimeToConsider.hour.toString().padLeft(2, '0')} : ${dateTimeToConsider.minute.toString().padLeft(2, '0')}";
    var dateTimeText = 'on $dayText @ $timeText';
    if (isArrival) {
      var numberOfDays = transitModelFacade.departureDateTime!
          .calculateDaysInBetween(transitModelFacade.arrivalDateTime!,
              includeExtraDay: false);
      if (numberOfDays > 0) {
        dateTimeText += _convertToSuperScript('+$numberOfDays');
      }
    }

    String? subTitle;
    if (transitModelFacade.transitOption == TransitOption.Flight) {
      subTitle = locationToConsider.context.name;
    } else if (locationToConsider.context.locationType != LocationType.City) {
      subTitle = locationToConsider.context.city;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: PlatformTextElements.createSubHeader(
                color: Colors.green,
                context: context,
                text: locationTitle,
                shouldBold: true),
          ),
        ),
        if (subTitle != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(subTitle)),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            dateTimeText,
          ),
        ),
      ],
    );
  }

  Widget _createTransitOption(BuildContext context) {
    var transitOptionMetadata = transitOptionMetadatas.firstWhere(
        (element) => element.transitOption == transitModelFacade.transitOption);
    var transitOperator = _getTransitOperator();
    if (transitOperator != null) {
      var isBigLayout = context.isBigLayout();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isBigLayout) Expanded(child: Container()),
          Column(
            children: [
              IgnorePointer(
                  child: IconButton(
                      onPressed: null, icon: Icon(transitOptionMetadata.icon))),
              Text(transitOptionMetadata.name)
            ],
          ),
          Expanded(
            flex: 2,
            child: Divider(),
          ),
          Text(transitOperator),
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
