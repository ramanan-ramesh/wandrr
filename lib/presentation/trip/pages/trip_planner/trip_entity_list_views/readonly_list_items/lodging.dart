import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/base_list_items/lodging_card_base.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ReadonlyLodgingPlan extends StatelessWidget {
  final LodgingFacade lodgingModelFacade;

  const ReadonlyLodgingPlan({required this.lodgingModelFacade, super.key});

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid = lodgingModelFacade.confirmationId != null &&
        lodgingModelFacade.confirmationId!.isNotEmpty;
    var isNotesValid = lodgingModelFacade.notes.isNotEmpty;
    return LodgingCardBase(
        lodgingFacade: lodgingModelFacade,
        location: Column(
          children: [
            PlatformTextElements.createSubHeader(
                context: context,
                text: (lodgingModelFacade.location!.context
                        as GeoLocationApiContext)
                    .name,
                shouldBold: true),
            const SizedBox(height: 4.0),
            Text((lodgingModelFacade.location!.context as GeoLocationApiContext)
                    .address ??
                ''),
          ],
        ),
        dateTime: _buildDateTimeDetails(),
        notes: isNotesValid
            ? _createTitleSubText(
                context.localizations.notes, lodgingModelFacade.notes,
                maxLines: null)
            : const SizedBox.shrink(),
        confirmationId: isConfirmationIdValid
            ? _createTitleSubText('${context.localizations.confirmation} #',
                lodgingModelFacade.confirmationId!)
            : const SizedBox.shrink(),
        expense: ExpenditureEditTile(
            expenseUpdator: lodgingModelFacade.expense, isEditable: false),
        isEditable: false);
  }

  Text _buildDateTimeDetails() {
    var dateTime =
        '${DateFormat.MMMEd().format(lodgingModelFacade.checkinDateTime!)} - ${DateFormat.MMMEd().format(lodgingModelFacade.checkoutDateTime!)}';
    return Text(
      dateTime,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _createTitleSubText(String title, String subtitle,
      {int? maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            subtitle,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }
}
