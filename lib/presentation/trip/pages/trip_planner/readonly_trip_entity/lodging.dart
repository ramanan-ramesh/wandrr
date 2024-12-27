import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ReadonlyLodgingListItem extends StatelessWidget {
  LodgingFacade lodgingModelFacade;

  ReadonlyLodgingListItem({super.key, required this.lodgingModelFacade});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid = lodgingModelFacade.confirmationId != null &&
        lodgingModelFacade.confirmationId!.isNotEmpty;
    var isNotesValid = lodgingModelFacade.notes.isNotEmpty;
    return IntrinsicHeight(
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
                    child: PlatformTextElements.createHeader(
                        context: context,
                        color: Colors.green,
                        text: (lodgingModelFacade.location!.context
                                as GeoLocationApiContext)
                            .name),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text((lodgingModelFacade.location!.context
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
          VerticalDivider(),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isNotesValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTitleSubText(
                          context.localizations.notes, lodgingModelFacade.notes,
                          maxLines: null),
                    ),
                  if (isConfirmationIdValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _createTitleSubText(
                          '${context.localizations.confirmation} #',
                          lodgingModelFacade.confirmationId!),
                    ),
                  if (isConfirmationIdValid) Divider(),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ExpenditureEditTile(
                          expenseUpdator: lodgingModelFacade.expense,
                          isEditable: false),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Text _buildDateTimeDetails() {
    var dateTime =
        '${DateFormat.MMMEd().format(lodgingModelFacade.checkinDateTime!)} - ${DateFormat.MMMEd().format(lodgingModelFacade.checkoutDateTime!)}';
    return Text(
      dateTime,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
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
}
