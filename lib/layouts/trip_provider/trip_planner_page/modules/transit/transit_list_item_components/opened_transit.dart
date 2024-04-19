import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/dialog.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/location.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

class OpenedTransitListItem extends StatefulWidget {
  TransitUpdator initialTransitUpdator;
  List<TransitOptionMetadata> transitOptionMetadatas;

  OpenedTransitListItem(
      {super.key,
      required TransitUpdator initialTransitUpdator,
      required this.transitOptionMetadatas})
      : initialTransitUpdator = initialTransitUpdator.clone();

  @override
  State<OpenedTransitListItem> createState() => _OpenedTransitListItemState();
}

class _OpenedTransitListItemState extends State<OpenedTransitListItem> {
  final ValueNotifier<bool> _transitValidityNotifier =
      ValueNotifier<bool>(false);
  late TransitUpdator _transitUpdator;

  @override
  void initState() {
    super.initState();
    _transitUpdator = widget.initialTransitUpdator.clone();
    _calculateTransitValidity();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.white24,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: _buildTransitOptionPicker(),
                        ),
                      ),
                      _buildDepartureDetails(context),
                      _buildArrivalDetails(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _createTransitCarrier(context),
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
                        child: PlatformTextField(
                          initialText: _transitUpdator.confirmationId,
                          labelText:
                              '${AppLocalizations.of(context)!.confirmation} #',
                          maxLines: 1,
                          onTextChanged: (newConfirmationId) {
                            _transitUpdator.confirmationId = newConfirmationId;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: PlatformTextField(
                          initialText: _transitUpdator.notes,
                          labelText: AppLocalizations.of(context)!.notes,
                          onTextChanged: (newNotes) {
                            _transitUpdator.notes = newNotes;
                          },
                        ),
                      ),
                      _createTitleSubText(
                        AppLocalizations.of(context)!.cost,
                        ExpenditureEditTile(
                          expenseUpdator: _transitUpdator.expenseUpdator!,
                          isEditable: true,
                          callback: (paidBy, splitBy, totalExpense) {
                            if (paidBy != null) {
                              _transitUpdator.expenseUpdator!.paidBy =
                                  Map.from(paidBy);
                            }
                            if (splitBy != null) {
                              _transitUpdator.expenseUpdator!.splitBy =
                                  List.from(splitBy);
                            }
                            if (totalExpense != null) {
                              _transitUpdator.expenseUpdator!.totalExpense =
                                  CurrencyWithValue(
                                      currency: totalExpense.currency,
                                      amount: totalExpense.amount);
                            }
                            _calculateTransitValidity();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: _buildUpdateTransitOptionButton(),
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: _buildDeleteTransitButton(context),
            )
          ],
        )
      ],
    );
  }

  Widget _buildArrivalDetails(BuildContext context) {
    return _createTitleSubText(
      AppLocalizations.of(context)!.arrive,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _transitUpdator.transitOption == TransitOptions.Flight
                ? _AirportsData(
                    initialLocation: _transitUpdator.arrivalLocation?.context
                            is AirportLocationContext
                        ? _transitUpdator.arrivalLocation
                        : null,
                    onLocationSelected: (newLocation) {
                      _transitUpdator.arrivalLocation = newLocation;
                      _calculateTransitValidity();
                    },
                  )
                : PlatformGeoLocationAutoComplete(
                    onLocationSelected: (newLocation) {
                      _transitUpdator.arrivalLocation = newLocation;
                      _calculateTransitValidity();
                    },
                    initialText: _transitUpdator.arrivalLocation?.toString(),
                  ),
          ),
          PlatformDateTimePicker(
            initialDateTime: _transitUpdator.arrivalDateTime,
            dateTimeUpdated: (updatedDateTime) {
              _transitUpdator.arrivalDateTime = updatedDateTime;
              _calculateTransitValidity();
            },
          )
        ],
      ),
    );
  }

  Widget _buildDepartureDetails(BuildContext context) {
    return _createTitleSubText(
      AppLocalizations.of(context)!.depart,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _transitUpdator.transitOption == TransitOptions.Flight
                ? _AirportsData(
                    initialLocation: _transitUpdator.departureLocation?.context
                            is AirportLocationContext
                        ? _transitUpdator.departureLocation
                        : null,
                    onLocationSelected: (newLocation) {
                      _transitUpdator.departureLocation = newLocation;
                      _calculateTransitValidity();
                    },
                  )
                : PlatformGeoLocationAutoComplete(
                    onLocationSelected: (newLocation) {
                      _transitUpdator.departureLocation = newLocation;
                      _calculateTransitValidity();
                    },
                    initialText: _transitUpdator.departureLocation?.toString(),
                  ),
          ),
          PlatformDateTimePicker(
            initialDateTime: _transitUpdator.departureDateTime,
            dateTimeUpdated: (updatedDateTime) {
              _transitUpdator.departureDateTime = updatedDateTime;
              _calculateTransitValidity();
            },
          )
        ],
      ),
    );
  }

  _TransitOptionPicker _buildTransitOptionPicker() {
    return _TransitOptionPicker(
        callback: (transitOption) {
          if ((_transitUpdator.transitOption != TransitOptions.Flight &&
                  transitOption == TransitOptions.Flight) ||
              ((transitOption != TransitOptions.Flight &&
                  _transitUpdator.transitOption == TransitOptions.Flight))) {
            _transitUpdator.transitOption = transitOption;
            _transitUpdator.operator = null;
            _transitUpdator.departureLocation = null;
            _transitUpdator.arrivalLocation = null;
            _calculateTransitValidity();
            setState(() {});
            return;
          }
          _transitUpdator.transitOption = transitOption;
        },
        initialTransitOption: _transitUpdator.transitOption!,
        transitOptionMetadatas: widget.transitOptionMetadatas);
  }

  Widget _buildDeleteTransitButton(BuildContext context) {
    return PlatformSubmitterFAB(
      icon: Icons.delete_rounded,
      backgroundColor: Colors.black,
      context: context,
      callback: () {
        var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
        tripManagementBloc
            .add(UpdateTransit.delete(transitUpdator: _transitUpdator));
      },
    );
  }

  Widget _buildUpdateTransitOptionButton() {
    return ValueListenableBuilder(
        valueListenable: _transitValidityNotifier,
        builder: (context, canUpdateExpense, oldWidget) {
          return PlatformSubmitterFAB(
              icon: Icons.check_rounded,
              context: context,
              backgroundColor: canUpdateExpense ? Colors.black : Colors.white12,
              callback: canUpdateExpense
                  ? () {
                      var tripManagementBloc =
                          BlocProvider.of<TripManagementBloc>(context);
                      if (_transitUpdator.dataState ==
                          DataState.CreateNewUIEntry) {
                        tripManagementBloc.add(UpdateTransit.create(
                            transitUpdator: _transitUpdator));
                      } else {
                        tripManagementBloc.add(UpdateTransit.update(
                            transitUpdator: _transitUpdator));
                      }
                    }
                  : null);
        });
  }

  void _calculateTransitValidity() {
    var areLocationsValid = _transitUpdator.departureLocation != null &&
        _transitUpdator.arrivalLocation != null;
    var areDateTimesValid = _transitUpdator.departureDateTime != null &&
        _transitUpdator.arrivalDateTime != null &&
        _transitUpdator.departureDateTime!
                .compareTo(_transitUpdator.arrivalDateTime!) <
            0;
    var isExpenseValid = _transitUpdator.expenseUpdator != null;
    _transitValidityNotifier.value =
        areLocationsValid && areDateTimesValid && isExpenseValid;
  }

  Widget _createTransitCarrier(BuildContext context) {
    String transitCarrier = '';
    if (_transitUpdator.transitOption == TransitOptions.Flight) {
      if (_transitUpdator.operator != null) {
        transitCarrier = _transitUpdator.operator!;
      }
    } else {
      var pascalWordsPattern = RegExp(r"(?:[A-Z]+|^)[a-z]*");
      List<String> getPascalWords(String input) =>
          pascalWordsPattern.allMatches(input).map((m) => m[0]!).toList();
      var pascalWords = getPascalWords(_transitUpdator.transitOption!.name);
      var transitOption = pascalWords.fold(
          '', (previousValue, element) => '${previousValue} ${element}');
      transitCarrier = _transitUpdator.operator ?? transitOption;
    }
    if (_transitUpdator.transitOption != TransitOptions.Flight) {
      return PlatformTextField(
        labelText: AppLocalizations.of(context)!.transitCarrier,
        initialText: transitCarrier,
        onTextChanged: (newCarrier) {
          _transitUpdator.operator = newCarrier;
        },
      );
    }
    return _FlightDetails(
      initialOperator: _transitUpdator.operator,
      onNewOperatorProvided: (newOperator) {
        _transitUpdator.operator = newOperator;
        _calculateTransitValidity();
      },
    );
  }

  Widget _createTitleSubText(String title, Widget subtitle) {
    return Container(
      color: Colors.white10,
      child: Column(
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
      ),
    );
  }
}

class _TransitOptionPicker extends StatefulWidget {
  final Function(TransitOptions expenseCategory)? callback;
  final List<TransitOptionMetadata> transitOptionMetadatas;
  TransitOptions initialTransitOption;

  _TransitOptionPicker(
      {super.key,
      required this.callback,
      required this.initialTransitOption,
      required this.transitOptionMetadatas});

  @override
  State<_TransitOptionPicker> createState() => _TransitOptionPickerState();
}

class _TransitOptionPickerState extends State<_TransitOptionPicker> {
  late TransitOptionMetadata _transitOptionMetadata;
  var _widgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transitOptionMetadata = widget.transitOptionMetadatas.firstWhere(
        (element) => element.transitOptions == widget.initialTransitOption);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        key: _widgetKey,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: BorderSide(width: 1.0, color: Colors.white),
        ),
        onPressed: widget.callback != null
            ? () {
                PlatformDialogElements.showAlignedDialog(
                    context: context,
                    widgetBuilder: (context) => Material(
                          elevation: 5.0,
                          child: Container(
                            width: 200,
                            color: Colors.white24,
                            child: GridView.extent(
                              shrinkWrap: true,
                              maxCrossAxisExtent: 75,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              children: widget.transitOptionMetadatas
                                  .map((e) => _createTransitOption(e, context))
                                  .toList(),
                            ),
                          ),
                        ),
                    widgetKey: _widgetKey);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            children: [
              IconButton(
                  onPressed: null,
                  icon: Icon(
                    _transitOptionMetadata.icon,
                    color: Colors.white,
                  )),
              Text(
                _transitOptionMetadata.name,
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ));
  }

  Widget _createTransitOption(
      TransitOptionMetadata transitOptionMetadata, BuildContext dialogContext) {
    return InkWell(
      splashColor: Colors.white,
      onTap: () {
        setState(() {
          _transitOptionMetadata = widget.transitOptionMetadatas.firstWhere(
              (element) =>
                  element.transitOptions ==
                  transitOptionMetadata.transitOptions);
          if (widget.callback != null) {
            widget.callback!(transitOptionMetadata.transitOptions);
            Navigator.of(dialogContext).pop();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Icon(
                transitOptionMetadata.icon,
                color: Colors.black,
              ),
            ),
            Text(
              transitOptionMetadata.name,
              style: TextStyle(color: Colors.black),
            )
          ],
        ),
      ),
    );
  }
}

class _AirportsData extends StatefulWidget {
  final LocationFacade? initialLocation;
  final Function(LocationFacade selectedLocation)? onLocationSelected;
  _AirportsData({super.key, this.initialLocation, this.onLocationSelected});

  @override
  State<_AirportsData> createState() => _AirportsDataState();
}

class _AirportsDataState extends State<_AirportsData> {
  LocationFacade? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation?.clone();
  }

  @override
  Widget build(BuildContext context) {
    var airportCode =
        (_location?.context as AirportLocationContext?)?.airportCode ?? '   ';
    return PlatformAutoComplete<LocationFacade>(
      hintText: AppLocalizations.of(context)!.airport,
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
      optionsBuilder: RepositoryProvider.of<TripManagement>(context)
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

class _FlightDetails extends StatefulWidget {
  final String? initialOperator;
  final Function(String)? onNewOperatorProvided;
  const _FlightDetails(
      {super.key, required this.initialOperator, this.onNewOperatorProvided});

  @override
  State<_FlightDetails> createState() => _FlightDetailsState();
}

class _FlightDetailsState extends State<_FlightDetails> {
  String? _flightNumber, _flightOperator, _flightCode;

  @override
  void initState() {
    super.initState();
    if (widget.initialOperator != null) {
      var flightDetails = widget.initialOperator!.split(' ');
      var length = flightDetails.length;
      _flightNumber = flightDetails.last;
      _flightCode = flightDetails.elementAt(length - 2);
      _flightOperator = '';
      for (var flightDetail in flightDetails.take(length - 2)) {
        _flightOperator = _flightOperator! + flightDetail;
      }
    }
  }

  void _updateOperator(
      {String? newFlightNumber,
      String? newFlightOperator,
      String? newFlightCode}) {
    if (newFlightNumber != null) {
      _flightNumber = newFlightNumber;
    }
    if (newFlightOperator != null) {
      _flightOperator = newFlightOperator;
    }
    if (newFlightCode != null) {
      _flightCode = newFlightCode;
    }
    if (_flightCode != null &&
        _flightCode!.isNotEmpty &&
        _flightOperator != null &&
        _flightOperator!.isNotEmpty &&
        _flightNumber != null &&
        _flightNumber!.isNotEmpty) {
      if (widget.onNewOperatorProvided != null) {
        widget.onNewOperatorProvided!(
            '$_flightOperator $_flightCode $_flightNumber');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Text(
            _flightCode ?? '  ',
            style: TextStyle(color: Colors.black),
          ),
        ),
        Expanded(
          child: PlatformTextField(
            onTextChanged: (newFlightNumber) {
              _flightNumber = newFlightNumber;
              _updateOperator(newFlightNumber: _flightNumber);
            },
            initialText: _flightNumber,
            hintText: AppLocalizations.of(context)!.flightNumber,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: PlatformAutoComplete<(String, String)>(
            hintText: AppLocalizations.of(context)!.flightCarrierName,
            text: _flightOperator,
            optionsBuilder: RepositoryProvider.of<TripManagement>(context)
                .flightOperationsService
                .queryAirlinesData,
            onSelected: (airlineData) {
              setState(() {});
              _updateOperator(
                  newFlightCode: airlineData.$2,
                  newFlightOperator: airlineData.$1);
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
          ),
        ),
      ],
    );
  }
}
