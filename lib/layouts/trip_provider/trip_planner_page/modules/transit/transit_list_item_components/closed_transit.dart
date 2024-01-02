import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/platform_elements/text.dart';

class ClosedTransitListItem extends StatelessWidget {
  TransitUpdator transitUpdator;
  List<TransitOptionMetadata> transitOptionMetadatas;
  ClosedTransitListItem(
      {super.key,
      required this.transitUpdator,
      required this.transitOptionMetadatas});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid = transitUpdator.confirmationId != null &&
        transitUpdator.confirmationId!.isNotEmpty;
    var isNotesValid =
        transitUpdator.notes != null && transitUpdator.notes!.isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.black12,
      child: IntrinsicHeight(
        child: Row(
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
                      child: _createLocationDetailTitle(context),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: _createDateTimeDetail(context),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _getTransitCarrier().toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
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
                            transitUpdator.confirmationId!),
                      ),
                    if (isConfirmationIdValid) Divider(),
                    if (isNotesValid)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _createTitleSubText(
                            AppLocalizations.of(context)!.notes,
                            transitUpdator.notes!),
                      ),
                    if (isNotesValid) Divider(),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ExpenditureEditTile(
                            expenseUpdator: transitUpdator.expenseUpdator!,
                            isEditable: false),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getTransitCarrier() {
    if (transitUpdator.transitOption == TransitOptions.Flight) {
      return '${transitUpdator.name!} ${transitUpdator.operator!}';
    } else {
      var pascalWordsPattern = RegExp(r"(?:[A-Z]+|^)[a-z]*");
      List<String> getPascalWords(String input) =>
          pascalWordsPattern.allMatches(input).map((m) => m[0]!).toList();
      var pascalWords = getPascalWords(transitUpdator.transitOption!.name);
      var transitOption = pascalWords.fold(
          '', (previousValue, element) => '${previousValue} ${element}');
      return transitUpdator.operator ?? transitOption;
    }
  }

  Widget _createTitleSubText(String title, String subtitle) {
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
          ),
        ),
      ],
    );
  }

  Widget _createLocationDetailTitle(BuildContext context) {
    String departureLocationTitle, arrivalLocationTitle;
    if (transitUpdator.transitOption == TransitOptions.Flight) {
      departureLocationTitle =
          (transitUpdator.departureLocation!.context as AirportLocationContext)
              .airportCode;
      arrivalLocationTitle =
          (transitUpdator.arrivalLocation!.context as AirportLocationContext)
              .airportCode;
    } else {
      departureLocationTitle = transitUpdator.departureLocation!.toString();
      arrivalLocationTitle = transitUpdator.arrivalLocation!.toString();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: PlatformTextElements.createSubHeader(
                  context: context,
                  text: departureLocationTitle,
                  shouldBold: true),
            ),
            if (transitUpdator.transitOption == TransitOptions.Flight)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0),
                child: Text(transitUpdator.departureLocation!.context.name),
              ),
          ],
        ),
        Expanded(child: Divider()),
        _createTransitOption(context),
        Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0),
                child: PlatformTextElements.createSubHeader(
                    context: context,
                    text: arrivalLocationTitle,
                    shouldBold: true),
              ),
              if (transitUpdator.transitOption == TransitOptions.Flight)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(transitUpdator.arrivalLocation!.context.city!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createTransitOption(BuildContext context) {
    var transitOptionMetadata = transitOptionMetadatas.firstWhere(
        (element) => element.transitOptions == transitUpdator.transitOption!);
    return ElevatedButton(
        onPressed: null,
        child: Column(
          children: [
            IconButton(onPressed: null, icon: Icon(transitOptionMetadata.icon)),
            Text(transitOptionMetadata.name)
          ],
        ));
  }

  Widget _createDateTimeDetail(BuildContext context) {
    var dateFormat = DateFormat.MMMEd();
    var timeFormat = DateFormat(DateFormat.HOUR24_MINUTE);
    var numberOfTravelDays = transitUpdator.departureDateTime!
        .compareTo(transitUpdator.arrivalDateTime!);
    var arrivalTime = timeFormat.format(transitUpdator.arrivalDateTime!);
    if (numberOfTravelDays >= 1) {
      arrivalTime += convertToSuperScript('+$numberOfTravelDays');
    }
    var timeDetail =
        '${timeFormat.format(transitUpdator.departureDateTime!)} to $arrivalTime';
    var bulletPoint = utf8.decode([0xE2, 0x80, 0xA2]); // or use \u2022
    var dateTimeText =
        '${dateFormat.format(transitUpdator.departureDateTime!)} $bulletPoint $timeDetail';

    return PlatformTextElements.createSubHeader(
        context: context, text: dateTimeText);
  }
}

String convertToSuperScript(String word) {
  var superScriptText = '';
  for (var character in word.characters) {
    if (character == ' ') {
      superScriptText += ' ';
    } else {
      superScriptText += unicodeMap[character]!.$1;
    }
  }
  return superScriptText;
}

final unicodeMap = {
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
