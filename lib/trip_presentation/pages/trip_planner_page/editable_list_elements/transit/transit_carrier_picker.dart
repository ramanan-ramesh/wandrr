import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/auto_complete.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/transit_option_metadata.dart';

import 'airline_data.dart';

class TransitCarrierPicker extends StatefulWidget {
  TransitOption transitOption;
  String? operator;
  Function(String?) onOperatorChanged;
  Function(TransitOption) onTransitOptionChanged;
  Iterable<TransitOptionMetadata> transitOptionMetadatas;

  TransitCarrierPicker(
      {super.key,
      required this.transitOption,
      required this.operator,
      required this.onOperatorChanged,
      required this.onTransitOptionChanged,
      required this.transitOptionMetadatas});

  @override
  State<TransitCarrierPicker> createState() => _TransitCarrierPickerState();
}

class _TransitCarrierPickerState extends State<TransitCarrierPicker> {
  final TextEditingController _transitCarrierTextEditingController =
      TextEditingController();
  final TextEditingController _flightNumberEditingController =
      TextEditingController();
  AirlineData? _airlineData;

  @override
  void initState() {
    super.initState();
    if (widget.transitOption == TransitOption.Flight) {
      if (widget.operator == null) {
        _airlineData = AirlineData.empty();
      } else {
        _airlineData = AirlineData(widget.operator!);
        _flightNumberEditingController.text = _airlineData!.airLineNumber!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildTransitCarrierField(),
        ),
        if (widget.transitOption == TransitOption.Flight)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _buildAirlineNumberField(context),
          )
      ],
    );
  }

  TextField _buildAirlineNumberField(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      maxLines: 1,
      minLines: 1,
      decoration: InputDecoration(
        hintText: context.withLocale().flightNumber,
        prefixText: _airlineData!.airLineCode ?? '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: EdgeInsets.symmetric(horizontal: 3.0),
      ),
      controller: _flightNumberEditingController,
      onChanged: (newFlightNumber) {
        _airlineData!.airLineNumber = newFlightNumber;
        if (_airlineData!.airLineNumber != null &&
            _airlineData!.airLineName != null &&
            _airlineData!.airLineCode != null) {
          widget.onOperatorChanged(_airlineData.toString());
        }
      },
    );
  }

  Widget _buildTransitCarrierField() {
    if (widget.transitOption == TransitOption.Flight) {
      return PlatformAutoComplete<(String airLineName, String airLineCode)>(
        customPrefix: _buildTransitOptionPicker(),
        hintText: context.withLocale().flightCarrierName,
        text: _airlineData?.airLineName,
        optionsBuilder: context
            .getPlatformDataRepository()
            .flightOperationsService
            .queryAirlinesData,
        onSelected: (airlineData) {
          _airlineData?.airLineName = airlineData.$1;
          _airlineData?.airLineCode = airlineData.$2;
          widget.operator = _airlineData?.toString();
          if (_airlineData?.airLineNumber != null &&
              _airlineData?.airLineName != null &&
              _airlineData?.airLineCode != null) {
            widget.onOperatorChanged(_airlineData.toString());
          }
          setState(() {});
        },
        listItem: (airlineData) {
          return ListTile(
            leading: Text(
              airlineData.$2,
              style: TextStyle(color: Colors.white),
            ),
            title: Text(
              airlineData.$1,
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    } else if (widget.transitOption == TransitOption.Walk ||
        widget.transitOption == TransitOption.Vehicle) {
      return _buildTransitOptionPicker();
    } else {
      return TextField(
        minLines: 1,
        maxLines: 1,
        controller: _transitCarrierTextEditingController,
        decoration: InputDecoration(
          prefixIcon: _buildTransitOptionPicker(),
          hintText: context.withLocale().carrierName,
        ),
        onChanged: (newCarrier) {
          widget.operator = newCarrier;
          widget.onOperatorChanged(newCarrier);
        },
      );
    }
  }

  DropdownButton<TransitOption> _buildTransitOptionPicker() {
    return DropdownButton<TransitOption>(
        value: widget.transitOption,
        selectedItemBuilder: (context) => widget.transitOptionMetadatas
            .map(
              (e) => DropdownMenuItem<TransitOption>(
                value: e.transitOption,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(e.icon),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(e.name),
                      )
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        items: widget.transitOptionMetadatas
            .map(
              (e) => DropdownMenuItem<TransitOption>(
                value: e.transitOption,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(e.icon),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(e.name),
                      )
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (selectedTransitOption) {
          widget.transitOption = selectedTransitOption!;
          widget.onTransitOptionChanged(selectedTransitOption);
          if (selectedTransitOption == TransitOption.Flight) {
            _airlineData = AirlineData.empty();
          }
          setState(() {});
        });
  }
}
