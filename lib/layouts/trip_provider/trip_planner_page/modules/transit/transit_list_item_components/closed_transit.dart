import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_entity_facades/location.dart';
import 'package:wandrr/contracts/trip_entity_facades/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_option_metadata.dart';
import 'package:wandrr/platform_elements/text.dart';

class ClosedTransitListItem extends StatelessWidget {
  TransitFacade transitModelFacade;
  List<TransitOptionMetadata> transitOptionMetadatas;

  ClosedTransitListItem(
      {super.key,
      required this.transitModelFacade,
      required this.transitOptionMetadatas});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid =
        transitModelFacade.confirmationId?.isNotEmpty ?? false;
    var isNotesValid = transitModelFacade.notes.isNotEmpty;
    return Row(
      // TODO: Is IntrinsicHeight needed here?
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: _createTransitOption(context),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: _createLocationDetailTitle(context, false),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: _createLocationDetailTitle(context, true),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      _getTransitCarrier(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                if (isNotesValid)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _createTitleSubText(
                        context.withLocale().notes, transitModelFacade.notes,
                        maxLines: null),
                  )
              ],
            ),
          ),
        ),
        VerticalDivider(
          color: Colors.white,
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
    );
  }

  String _getTransitCarrier() {
    if (transitModelFacade.transitOption == TransitOption.Flight) {
      return transitModelFacade.operator!;
    } else {
      var pascalWordsPattern = RegExp(r"(?:[A-Z]+|^)[a-z]*");
      List<String> getPascalWords(String input) =>
          pascalWordsPattern.allMatches(input).map((m) => m[0]!).toList();
      var pascalWords = getPascalWords(transitModelFacade.transitOption.name);
      var transitOption = pascalWords.fold(
          '', (previousValue, element) => '$previousValue $element');
      return transitModelFacade.operator ?? transitOption;
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
        dateTimeText += ' (+${_convertToSuperScript(numberOfDays.toString())})';
      }
    }

    return IgnorePointer(
      child: ListTile(
        leading: Text(isArrival
            ? context.withLocale().arrive
            : context.withLocale().depart),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: PlatformTextElements.createSubHeader(
                  context: context, text: locationTitle, shouldBold: true),
            ),
            if (transitModelFacade.transitOption == TransitOption.Flight)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0),
                child: Text(locationToConsider.context.name),
              ),
          ],
        ),
        trailing: PlatformTextElements.createSubHeader(
            context: context, text: dateTimeText, shouldBold: true),
      ),
    );
  }

  Widget _createTransitOption(BuildContext context) {
    var transitOptionMetadata = transitOptionMetadatas.firstWhere(
        (element) => element.transitOption == transitModelFacade.transitOption);
    return ElevatedButton(
        onPressed: null,
        child: Column(
          children: [
            IconButton(onPressed: null, icon: Icon(transitOptionMetadata.icon)),
            Text(transitOptionMetadata.name)
          ],
        ));
  }
}

String _convertToSuperScript(String word) {
  var superScriptText = '';
  for (var character in word.characters) {
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
};
