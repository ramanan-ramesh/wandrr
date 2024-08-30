import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/location.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

class OpenedTransitListItem extends StatefulWidget {
  UiElement<TransitModelFacade> transitUiElement;
  List<TransitOptionMetadata> transitOptionMetadatas;
  ValueNotifier<bool> validityNotifier;

  OpenedTransitListItem(
      {super.key,
      required this.transitUiElement,
      required this.transitOptionMetadatas,
      required this.validityNotifier});

  @override
  State<OpenedTransitListItem> createState() => _OpenedTransitListItemState();
}

class _OpenedTransitListItemState extends State<OpenedTransitListItem> {
  late UiElement<TransitModelFacade> _transitUiElement;

  @override
  void initState() {
    super.initState();
    _transitUiElement = widget.transitUiElement.clone();
    _calculateTransitValidity();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationDetails(context, false),
                _buildLocationDetails(context, true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildTransitCarrierPicker(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildNotesField(context),
                )
              ],
            ),
          ),
        ),
        VerticalDivider(
          color: Colors.black,
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _buildConfirmationIdField(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _buildExpenditureEditField(context),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildExpenditureEditField(BuildContext context) {
    return _createTitleSubText(
      AppLocalizations.of(context)!.cost,
      ExpenditureEditTile(
        expenseUpdator: _transitUiElement.element.expense,
        isEditable: true,
        callback: (paidBy, splitBy, totalExpense) {
          if (paidBy != null) {
            _transitUiElement.element.expense.paidBy = Map.from(paidBy);
          }
          if (splitBy != null) {
            _transitUiElement.element.expense.splitBy = List.from(splitBy);
          }
          if (totalExpense != null) {
            _transitUiElement.element.expense.totalExpense = CurrencyWithValue(
                currency: totalExpense.currency, amount: totalExpense.amount);
          }
          _calculateTransitValidity();
        },
      ),
    );
  }

  Widget _buildConfirmationIdField(BuildContext context) {
    return _createTitleSubText(
      '${AppLocalizations.of(context)!.confirmation} #',
      PlatformTextField(
        initialText: _transitUiElement.element.confirmationId,
        maxLines: 1,
        onTextChanged: (newConfirmationId) {
          _transitUiElement.element.confirmationId = newConfirmationId;
        },
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return _createTitleSubText(
      AppLocalizations.of(context)!.notes,
      PlatformTextField(
        initialText: _transitUiElement.element.notes,
        maxLines: null,
        onTextChanged: (newNotes) {
          _transitUiElement.element.notes = newNotes;
        },
      ),
    );
  }

  Widget _buildTransitCarrierPicker(BuildContext context) {
    return _createTitleSubText(
      AppLocalizations.of(context)!.transitCarrier,
      _TransitCarrierPicker(
        transitOption: _transitUiElement.element.transitOption,
        operator: _transitUiElement.element.operator,
        transitOptionMetadatas: widget.transitOptionMetadatas,
        onOperatorChanged: (String? newOperator) {
          _transitUiElement.element.operator = newOperator;
          _calculateTransitValidity();
        },
        onTransitOptionChanged: (newTransitOption) {
          _transitUiElement.element.transitOption = newTransitOption;
          setState(() {});
          _calculateTransitValidity();
        },
      ),
    );
  }

  Widget _buildLocationDetails(BuildContext context, bool isArrival) {
    var transitModelFacade = _transitUiElement.element;
    var locationToConsider = isArrival
        ? transitModelFacade.arrivalLocation
        : transitModelFacade.departureLocation;
    return _createTitleSubText(
      isArrival
          ? AppLocalizations.of(context)!.arrive
          : AppLocalizations.of(context)!.depart,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: transitModelFacade.transitOption == TransitOption.Flight
                ? _AirportsDataEditor(
                    initialLocation: locationToConsider,
                    onLocationSelected: (newLocation) {
                      if (isArrival) {
                        transitModelFacade.arrivalLocation = newLocation;
                      } else {
                        transitModelFacade.departureLocation = newLocation;
                      }
                      _calculateTransitValidity();
                    },
                  )
                : PlatformGeoLocationAutoComplete(
                    onLocationSelected: (newLocation) {
                      if (isArrival) {
                        transitModelFacade.arrivalLocation = newLocation;
                      } else {
                        transitModelFacade.departureLocation = newLocation;
                      }
                      _calculateTransitValidity();
                    },
                    initialText: locationToConsider?.toString(),
                  ),
          ),
          PlatformDateTimePicker(
            initialDateTime: isArrival
                ? transitModelFacade.arrivalDateTime
                : transitModelFacade.departureDateTime,
            dateTimeUpdated: (updatedDateTime) {
              if (isArrival) {
                transitModelFacade.arrivalDateTime = updatedDateTime;
              } else {
                transitModelFacade.departureDateTime = updatedDateTime;
              }
              _calculateTransitValidity();
            },
          )
        ],
      ),
    );
  }

  void _calculateTransitValidity() {
    var transitModelFacade = _transitUiElement.element;
    var areLocationsValid = transitModelFacade.departureLocation != null &&
        transitModelFacade.arrivalLocation != null;
    var areDateTimesValid = transitModelFacade.departureDateTime != null &&
        transitModelFacade.arrivalDateTime != null &&
        transitModelFacade.departureDateTime!
                .compareTo(transitModelFacade.arrivalDateTime!) <
            0;
    var isTransitCarrierValid =
        transitModelFacade.transitOption == TransitOption.Flight
            ? transitModelFacade.operator != null
            : true;
    widget.validityNotifier.value =
        areLocationsValid && areDateTimesValid && isTransitCarrierValid;
  }

  Widget _createTitleSubText(String title, Widget subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: subtitle,
        ),
      ],
    );
  }
}

class _AirportsDataEditor extends StatefulWidget {
  final LocationModelFacade? initialLocation;
  final Function(LocationModelFacade selectedLocation)? onLocationSelected;

  _AirportsDataEditor(
      {super.key, this.initialLocation, this.onLocationSelected});

  @override
  State<_AirportsDataEditor> createState() => _AirportsDataEditorState();
}

class _AirportsDataEditorState extends State<_AirportsDataEditor> {
  LocationModelFacade? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation?.clone();
  }

  @override
  Widget build(BuildContext context) {
    var airportCode =
        (_location?.context as AirportLocationContext?)?.airportCode ?? '   ';
    return PlatformAutoComplete<LocationModelFacade>(
      hintText: AppLocalizations.of(context)!.airport,
      text: _location?.toString(),
      customPrefix: Text(
        airportCode,
        style: TextStyle(color: Colors.black),
      ),
      onSelected: (newAirport) {
        if (newAirport != _location) {
          setState(() {
            _location = newAirport;
          });
          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(newAirport);
          }
        }
      },
      optionsBuilder:
          RepositoryProvider.of<PlatformDataRepositoryFacade>(context)
              .flightOperationsService
              .queryAirportsData,
      listItem: (airportData) {
        var airportLocationContext =
            airportData.context as AirportLocationContext;
        return Material(
          child: Container(
            color: Colors.black12,
            child: ListTile(
              leading: Icon(PlatformLocationElements
                  .locationTypesAndIcons[airportLocationContext.locationType]),
              title: Text(airportLocationContext.name,
                  style: const TextStyle(color: Colors.white)),
              trailing: Text(airportLocationContext.airportCode,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(airportLocationContext.city,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }
}

class _TransitCarrierPicker extends StatefulWidget {
  TransitOption transitOption;
  String? operator;
  Function(String?) onOperatorChanged;
  Function(TransitOption) onTransitOptionChanged;
  List<TransitOptionMetadata> transitOptionMetadatas;

  _TransitCarrierPicker(
      {super.key,
      required this.transitOption,
      required this.operator,
      required this.onOperatorChanged,
      required this.onTransitOptionChanged,
      required this.transitOptionMetadatas});

  @override
  State<_TransitCarrierPicker> createState() => _TransitCarrierPickerState();
}

class _TransitCarrierPickerState extends State<_TransitCarrierPicker> {
  final TextEditingController _transitCarrierTextEditingController =
      TextEditingController();
  final TextEditingController _flightNumberEditingController =
      TextEditingController();
  _AirlineData? _airlineData;

  @override
  void initState() {
    super.initState();
    if (widget.transitOption == TransitOption.Flight) {
      if (widget.operator == null) {
        _airlineData = _AirlineData.empty();
      } else {
        _airlineData = _AirlineData(widget.operator!);
        _flightNumberEditingController.text = _airlineData!.airLineNumber!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        hintText: AppLocalizations.of(context)!.flightNumber,
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
        hintText: AppLocalizations.of(context)!.flightCarrierName,
        text: _airlineData?.airLineName,
        optionsBuilder:
            RepositoryProvider.of<PlatformDataRepositoryFacade>(context)
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
          hintText: AppLocalizations.of(context)!.carrierName,
        ),
        onChanged: (newCarrier) {
          widget.operator = newCarrier;
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
            _airlineData = _AirlineData.empty();
          }
          setState(() {});
        });
  }
}

class _AirlineData {
  String? airLineName, airLineCode, airLineNumber;

  _AirlineData.empty();

  _AirlineData(String transitCarrier) {
    var splitOptions = transitCarrier.split(' ');
    airLineName = splitOptions.first;
    airLineCode = splitOptions[1];
    airLineNumber = splitOptions[2];
  }

  @override
  String toString() {
    return '$airLineName $airLineCode $airLineNumber';
  }
}
