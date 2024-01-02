import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/platform_elements/text.dart';

class ClosedLodgingListItem extends StatelessWidget {
  LodgingUpdator lodgingUpdator;

  ClosedLodgingListItem({super.key, required this.lodgingUpdator});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid = lodgingUpdator.confirmationId != null &&
        lodgingUpdator.confirmationId!.isNotEmpty;
    var isNotesValid =
        lodgingUpdator.notes != null && lodgingUpdator.notes!.isNotEmpty;
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
                      child: PlatformTextElements.createSubHeader(
                          context: context,
                          text: (lodgingUpdator.location!.context
                                  as GeoLocationApiContext)
                              .name),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text((lodgingUpdator.location!.context
                                  as GeoLocationApiContext)
                              .address ??
                          ''),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildDateTimeDetails(),
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
                            lodgingUpdator.confirmationId!),
                      ),
                    if (isConfirmationIdValid) Divider(),
                    if (isNotesValid)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _createTitleSubText(
                            AppLocalizations.of(context)!.notes,
                            lodgingUpdator.notes!),
                      ),
                    if (isNotesValid) Divider(),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ExpenditureEditTile(
                            expenseUpdator: lodgingUpdator.expenseUpdator!,
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

  Text _buildDateTimeDetails() {
    var dateTime = DateFormat.MMMEd().format(lodgingUpdator.checkinDateTime!) +
        ' - ' +
        DateFormat.MMMEd().format(lodgingUpdator.checkoutDateTime!);
    return Text(
      dateTime,
      style: TextStyle(color: Colors.white),
    );
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
}
