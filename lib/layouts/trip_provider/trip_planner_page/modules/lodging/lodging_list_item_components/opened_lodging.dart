import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';

class OpenedLodgingListItem extends StatefulWidget {
  LodgingUpdator initialLodgingUpdator;

  OpenedLodgingListItem({super.key, required this.initialLodgingUpdator});

  @override
  State<OpenedLodgingListItem> createState() => _OpenedLodgingListItemState();
}

class _OpenedLodgingListItemState extends State<OpenedLodgingListItem> {
  final ValueNotifier<bool> _lodgingValidityNotifier =
      ValueNotifier<bool>(false);
  late LodgingUpdator _lodgingUpdator;

  @override
  void initState() {
    super.initState();
    _lodgingUpdator = widget.initialLodgingUpdator.clone();
    _calculateLodgingValidity();
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: PlatformGeoLocationAutoComplete(
                          initialText: _lodgingUpdator.location?.context.name,
                          onLocationSelected: (newLocation) {
                            _lodgingUpdator.location = newLocation;
                            _calculateLodgingValidity();
                          },
                        ),
                      ),
                      Row(
                        children: [
                          _createTitleSubText(
                              AppLocalizations.of(context)!.checkIn,
                              PlatformDatePicker(
                                callBack: (newDate) {
                                  _lodgingUpdator.checkinDateTime = newDate;
                                  _calculateLodgingValidity();
                                },
                                initialDateTime:
                                    _lodgingUpdator.checkinDateTime,
                              )),
                          _createTitleSubText(
                              AppLocalizations.of(context)!.checkOut,
                              PlatformDatePicker(
                                callBack: (newDate) {
                                  _lodgingUpdator.checkoutDateTime = newDate;
                                  _calculateLodgingValidity();
                                },
                                initialDateTime:
                                    _lodgingUpdator.checkoutDateTime,
                              )),
                        ],
                      ),
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
                          initialText: _lodgingUpdator.confirmationId,
                          labelText:
                              '${AppLocalizations.of(context)!.confirmation} #',
                          maxLines: 1,
                          onTextChanged: (newConfirmationId) {
                            _lodgingUpdator.confirmationId = newConfirmationId;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: PlatformTextField(
                          initialText: _lodgingUpdator.notes,
                          labelText: AppLocalizations.of(context)!.notes,
                          onTextChanged: (newNotes) {
                            _lodgingUpdator.notes = newNotes;
                          },
                        ),
                      ),
                      _createTitleSubText(
                        AppLocalizations.of(context)!.cost,
                        ExpenditureEditTile(
                          expenseUpdator: _lodgingUpdator.expenseUpdator!,
                          isEditable: true,
                          callback: (paidBy, splitBy, totalExpense) {
                            if (paidBy != null) {
                              _lodgingUpdator.expenseUpdator!.paidBy =
                                  Map.from(paidBy);
                            }
                            if (splitBy != null) {
                              _lodgingUpdator.expenseUpdator!.splitBy =
                                  List.from(splitBy);
                            }
                            if (totalExpense != null) {
                              _lodgingUpdator.expenseUpdator!.totalExpense =
                                  CurrencyWithValue(
                                      currency: totalExpense.currency,
                                      amount: totalExpense.amount);
                            }
                            _calculateLodgingValidity();
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
              child: _buildUpdateLodgingButton(),
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: _buildDeleteLodgingButton(context),
            )
          ],
        )
      ],
    );
  }

  Widget _buildDeleteLodgingButton(BuildContext context) {
    return PlatformSubmitterFAB(
      icon: Icons.delete_rounded,
      backgroundColor: Colors.black,
      context: context,
      callback: () {
        var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
        tripManagementBloc
            .add(UpdateLodging.delete(lodgingUpdator: _lodgingUpdator));
      },
    );
  }

  Widget _buildUpdateLodgingButton() {
    return ValueListenableBuilder(
        valueListenable: _lodgingValidityNotifier,
        builder: (context, canUpdateExpense, oldWidget) {
          return PlatformSubmitterFAB(
              icon: Icons.check_rounded,
              context: context,
              backgroundColor: canUpdateExpense ? Colors.black : Colors.white12,
              callback: canUpdateExpense
                  ? () {
                      var tripManagementBloc =
                          BlocProvider.of<TripManagementBloc>(context);
                      if (_lodgingUpdator.dataState ==
                          DataState.CreateNewUIEntry) {
                        tripManagementBloc.add(UpdateLodging.create(
                            lodgingUpdator: _lodgingUpdator));
                      } else {
                        tripManagementBloc.add(UpdateLodging.update(
                            lodgingUpdator: _lodgingUpdator));
                      }
                    }
                  : null);
        });
  }

  void _calculateLodgingValidity() {
    var isLocationValid = _lodgingUpdator.location != null;
    var areDateTimesValid = _lodgingUpdator.checkinDateTime != null &&
        _lodgingUpdator.checkoutDateTime != null &&
        _lodgingUpdator.checkinDateTime!
                .compareTo(_lodgingUpdator.checkoutDateTime!) <
            0;
    var isExpenseValid = _lodgingUpdator.expenseUpdator != null;
    _lodgingValidityNotifier.value =
        isLocationValid && areDateTimesValid && isExpenseValid;
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
