import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

import 'airline_data.dart';

class TransitCarrierPicker extends StatefulWidget {
  final TransitOption initialTransitOption;
  final String? initialOperator;
  final Function(String?) onOperatorChanged;
  final Function(TransitOption) onTransitOptionChanged;

  TransitCarrierPicker(
      {super.key,
      required this.initialTransitOption,
      required this.initialOperator,
      required this.onOperatorChanged,
      required this.onTransitOptionChanged});

  @override
  State<TransitCarrierPicker> createState() => _TransitCarrierPickerState();
}

class _TransitCarrierPickerState extends State<TransitCarrierPicker> {
  final TextEditingController _transitCarrierEditingController =
      TextEditingController();
  final TextEditingController _flightNumberEditingController =
      TextEditingController();
  AirlineData? _airlineData;
  late TransitOption _transitOption;
  late String? _operator;

  @override
  void initState() {
    super.initState();
    _transitOption = widget.initialTransitOption;
    _operator = widget.initialOperator;
    if (_transitOption == TransitOption.Flight) {
      if (_operator == null) {
        _airlineData = AirlineData.empty();
      } else {
        _airlineData = AirlineData(_operator!);
        _flightNumberEditingController.text = _airlineData!.airLineNumber!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadatas =
        context.tripRepository.activeTrip!.transitOptionMetadatas;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildTransitCarrierField(transitOptionMetadatas),
        ),
        if (_transitOption == TransitOption.Flight)
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
        hintText: context.localizations.flightNumber,
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

  Widget _buildTransitCarrierField(
      Iterable<TransitOptionMetadata> transitOptionMetadatas) {
    if (_transitOption == TransitOption.Flight) {
      return PlatformAutoComplete<(String airLineName, String airLineCode)>(
        prefixIcon: _buildTransitOptionPicker(transitOptionMetadatas),
        //TODO: This takes up entire space
        hintText: context.localizations.flightCarrierName,
        selectedItem: (_airlineData?.airLineName != null &&
                _airlineData?.airLineCode != null)
            ? (_airlineData!.airLineName!, _airlineData!.airLineCode!)
            : null,
        displayTextCreator: (airlineData) => airlineData.$1,
        optionsBuilder:
            context.tripRepository.flightOperationsService.queryAirlinesData,
        onSelected: (airlineData) {
          _airlineData?.airLineName = airlineData.$1;
          _airlineData?.airLineCode = airlineData.$2;
          _operator = _airlineData?.toString();
          if (_airlineData?.airLineNumber != null &&
              _airlineData?.airLineName != null &&
              _airlineData?.airLineCode != null) {
            widget.onOperatorChanged(_airlineData.toString());
          }
          setState(() {});
        },
        listItem: (airlineData) {
          return ListTile(
            selected: _airlineData?.airLineName == airlineData.$1,
            leading: Text(
              airlineData.$2,
            ),
            title: Text(
              airlineData.$1,
            ),
          );
        },
      );
    } else if (_transitOption == TransitOption.Walk ||
        _transitOption == TransitOption.Vehicle) {
      return _buildTransitOptionPicker(transitOptionMetadatas);
    } else {
      return TextField(
        minLines: 1,
        maxLines: 1,
        controller: _transitCarrierEditingController..text = _operator ?? '',
        decoration: InputDecoration(
          prefixIcon: _buildTransitOptionPicker(transitOptionMetadatas),
          hintText: context
              .localizations.carrierName, //TODO: This gets cut off for Tamil
        ),
        onChanged: (newCarrier) {
          _operator = newCarrier;
          widget.onOperatorChanged(newCarrier);
        },
      );
    }
  }

  Widget _buildTransitOptionPicker(
      Iterable<TransitOptionMetadata> transitOptionMetadatas) {
    return DropdownButton<TransitOption>(
        value: _transitOption,
        selectedItemBuilder: (context) => transitOptionMetadatas
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
        items: transitOptionMetadatas
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
          _transitOption = selectedTransitOption!;
          widget.onTransitOptionChanged(selectedTransitOption);
          if (selectedTransitOption == TransitOption.Flight) {
            _airlineData = AirlineData.empty();
          }
          setState(() {});
        });
  }
}
