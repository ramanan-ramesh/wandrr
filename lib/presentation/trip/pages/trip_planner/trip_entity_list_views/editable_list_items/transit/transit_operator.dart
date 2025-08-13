import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/airline_data.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TransitOperatorEditor extends StatelessWidget {
  final TransitOption transitOption;
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const TransitOperatorEditor(
      {super.key,
      required this.transitOption,
      this.initialOperator,
      required this.onOperatorChanged});

  @override
  Widget build(BuildContext context) {
    if (transitOption == TransitOption.flight) {
      return _FlightDetailsEditor(
          initialOperator: initialOperator,
          onOperatorChanged: onOperatorChanged);
    } else {
      return _createTransitOperatorEditingField(context);
    }
  }

  Widget _createTransitOperatorEditingField(BuildContext context) {
    var transitOperatorEditingController =
        TextEditingController(text: initialOperator ?? '');
    return TextField(
      minLines: 1,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelLarge,
      controller: transitOperatorEditingController,
      decoration: InputDecoration(
        labelText: context
            .localizations.carrierName, //TODO: This gets cut off for Tamil
      ),
      onChanged: (newCarrier) {
        onOperatorChanged(newCarrier);
      },
    );
  }
}

class _FlightDetailsEditor extends StatefulWidget {
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const _FlightDetailsEditor(
      {super.key,
      required this.initialOperator,
      required this.onOperatorChanged});

  @override
  State<_FlightDetailsEditor> createState() => _FlightDetailsEditorState();
}

class _FlightDetailsEditorState extends State<_FlightDetailsEditor> {
  late AirlineData airlineData;
  late TextEditingController flightNumberEditingController;

  @override
  void initState() {
    super.initState();
    if (widget.initialOperator != null && widget.initialOperator!.isNotEmpty) {
      airlineData = AirlineData(widget.initialOperator!);
    } else {
      airlineData = AirlineData.empty();
    }
    flightNumberEditingController =
        TextEditingController(text: airlineData.airLineNumber ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: context.isLightTheme ? Colors.teal : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _createAirlineEditor(context),
          const SizedBox(height: 12),
          _buildAirlineNumberField(context),
        ],
      ),
    );
  }

  Widget _createAirlineEditor(BuildContext context) {
    return PlatformAutoComplete<(String airLineName, String airLineCode)>(
      labelText: context.localizations.flightCarrierName,
      selectedItem:
          (airlineData.airLineName != null && airlineData.airLineCode != null)
              ? (airlineData.airLineName!, airlineData.airLineCode!)
              : null,
      displayTextCreator: (airlineData) => airlineData.$1,
      optionsBuilder:
          context.apiServicesRepository.airlinesDataService.queryData,
      onSelected: (selectedAirlineData) {
        airlineData.airLineName = selectedAirlineData.$1;
        airlineData.airLineCode = selectedAirlineData.$2;
        if (airlineData.airLineNumber != null &&
            airlineData.airLineName != null &&
            airlineData.airLineCode != null) {
          widget.onOperatorChanged(airlineData.toString());
        }
        setState(() {});
      },
      listItem: (airlineData) {
        return ListTile(
          selected: this.airlineData.airLineName == airlineData.$1,
          leading: Text(
            airlineData.$2,
          ),
          title: Text(
            airlineData.$1,
          ),
        );
      },
    );
  }

  Widget _buildAirlineNumberField(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final textPainter = TextPainter(
      text: TextSpan(text: '0' * 13, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    return Row(
      children: [
        Text(
          ' ${airlineData.airLineCode ?? '  '}  ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: textPainter.width + 10),
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              maxLines: 1,
              minLines: 1,
              decoration: InputDecoration(
                labelText: context.localizations.flightNumber,
                contentPadding: const EdgeInsets.symmetric(horizontal: 3.0),
              ),
              style: Theme.of(context).textTheme.labelLarge,
              controller: flightNumberEditingController,
              onChanged: (newFlightNumber) {
                airlineData.airLineNumber = newFlightNumber;
                if (airlineData.airLineNumber != null &&
                    airlineData.airLineName != null &&
                    airlineData.airLineCode != null) {
                  widget.onOperatorChanged(airlineData.toString());
                } else {
                  widget.onOperatorChanged(null);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
