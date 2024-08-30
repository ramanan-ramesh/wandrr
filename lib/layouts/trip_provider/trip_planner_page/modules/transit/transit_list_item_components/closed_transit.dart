import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/platform_elements/text.dart';

class ClosedTransitListItem extends StatelessWidget {
  TransitModelFacade transitModelFacade;
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
                        AppLocalizations.of(context)!.notes,
                        transitModelFacade.notes,
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
                        '${AppLocalizations.of(context)!.confirmation} #',
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
            ? AppLocalizations.of(context)!.arrive
            : AppLocalizations.of(context)!.depart),
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
      superScriptText += _unicodeMap[character]!.$1;
    }
  }
  return superScriptText;
}

final _unicodeMap = {
// #           superscript     subscript
  '0': ('\u2070', '\u2080'),
  '1': ('\u00B9', '\u2081'),
  '2': ('\u00B2', '\u2082'),
  '3': ('\u00B3', '\u2083'),
  '4': ('\u2074', '\u2084'),
  '5': ('\u2075', '\u2085'),
  '6': ('\u2076', '\u2086'),
  '7': ('\u2077', '\u2087'),
  '8': ('\u2078', '\u2088'),
  '9': ('\u2079', '\u2089'),
  'a': ('\u1d43', '\u2090'),
  'b': ('\u1d47', '?'),
  'c': ('\u1d9c', '?'),
  'd': ('\u1d48', '?'),
  'e': ('\u1d49', '\u2091'),
  'f': ('\u1da0', '?'),
  'g': ('\u1d4d', '?'),
  'h': ('\u02b0', '\u2095'),
  'i': ('\u2071', '\u1d62'),
  'j': ('\u02b2', '\u2c7c'),
  'k': ('\u1d4f', '\u2096'),
  'l': ('\u02e1', '\u2097'),
  'm': ('\u1d50', '\u2098'),
  'n': ('\u207f', '\u2099'),
  'o': ('\u1d52', '\u2092'),
  'p': ('\u1d56', '\u209a'),
  'q': ('?', '?'),
  'r': ('\u02b3', '\u1d63'),
  's': ('\u02e2', '\u209b'),
  't': ('\u1d57', '\u209c'),
  'u': ('\u1d58', '\u1d64'),
  'v': ('\u1d5b', '\u1d65'),
  'w': ('\u02b7', '?'),
  'x': ('\u02e3', '\u2093'),
  'y': ('\u02b8', '?'),
  'z': ('?', '?'),
  'A': ('\u1d2c', '?'),
  'B': ('\u1d2e', '?'),
  'C': ('?', '?'),
  'D': ('\u1d30', '?'),
  'E': ('\u1d31', '?'),
  'F': ('?', '?'),
  'G': ('\u1d33', '?'),
  'H': ('\u1d34', '?'),
  'I': ('\u1d35', '?'),
  'J': ('\u1d36', '?'),
  'K': ('\u1d37', '?'),
  'L': ('\u1d38', '?'),
  'M': ('\u1d39', '?'),
  'N': ('\u1d3a', '?'),
  'O': ('\u1d3c', '?'),
  'P': ('\u1d3e', '?'),
  'Q': ('?', '?'),
  'R': ('\u1d3f', '?'),
  'S': ('?', '?'),
  'T': ('\u1d40', '?'),
  'U': ('\u1d41', '?'),
  'V': ('\u2c7d', '?'),
  'W': ('\u1d42', '?'),
  'X': ('?', '?'),
  'Y': ('?', '?'),
  'Z': ('?', '?'),
  '+': ('\u207A', '\u208A'),
  '-': ('\u207B', '\u208B'),
  '=': ('\u207C', '\u208C'),
  '(': ('\u207D', '\u208D'),
  ')': ('\u207E', '\u208E')
};
