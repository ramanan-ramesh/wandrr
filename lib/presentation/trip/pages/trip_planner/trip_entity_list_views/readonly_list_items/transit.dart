import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/airline_data.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/base_list_items/transit_card_base.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ReadonlyTransitPlan extends StatelessWidget {
  final TransitFacade transitFacade;
  final AirlineData? airlineData;

  ReadonlyTransitPlan({super.key, required this.transitFacade})
      : airlineData = (transitFacade.transitOption == TransitOption.flight &&
                transitFacade.operator != null)
            ? (AirlineData(transitFacade.operator!))
            : null;

  @override
  Widget build(BuildContext context) {
    var isConfirmationIdValid =
        transitFacade.confirmationId?.isNotEmpty ?? false;
    var isNotesValid = transitFacade.notes?.isNotEmpty ?? false;
    var transitOptionMetadata = context.activeTrip.transitOptionMetadatas
        .firstWhere((metadata) =>
            metadata.transitOption == transitFacade.transitOption);
    return TransitCardBase(
      transitOption: _createTransitOption(transitOptionMetadata, context),
      transitOperator:
          _createTransitOperatorHeader(transitOptionMetadata, context),
      arrivalLocation: _createLocation(context, true),
      arrivalDateTime: _createDateTime(context, true),
      departureLocation: _createLocation(context, false),
      departureDateTime: _createDateTime(context, false),
      expenseTile: ExpenditureEditTile(
          expenseUpdator: transitFacade.expense, isEditable: false),
      confirmationId: isConfirmationIdValid
          ? _createConfirmationId(context)
          : const SizedBox(),
      transitFacade: transitFacade,
      notes: isNotesValid ? _createNotes(context) : const SizedBox(),
      isEditable: false,
    );
  }

  Widget _createTransitOperatorHeader(
      TransitOptionMetadata transitOptionMetadata, BuildContext context) {
    if (transitFacade.operator != null) {
      if (airlineData != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              airlineData!.airLineName!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${airlineData!.airLineCode} ${airlineData!.airLineNumber}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      } else {
        return Text(
          transitFacade.operator!,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    }
    return const SizedBox();
  }

  Widget _createTransitOption(
      TransitOptionMetadata transitOptionMetadata, BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(transitOptionMetadata.icon),
          onPressed: null,
        ),
        const SizedBox(width: 8.0),
        Text(
          transitOptionMetadata.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _createConfirmationId(BuildContext context) {
    if (transitFacade.confirmationId == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: FittedBox(
            child: Text(
              '${context.localizations.confirmation} #',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            transitFacade.confirmationId!,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _createNotes(BuildContext context) {
    if (transitFacade.notes == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: FittedBox(
            child: Text(
              context.localizations.notes,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            transitFacade.notes!,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _createLocation(BuildContext context, bool isArrival) {
    var location = isArrival
        ? transitFacade.arrivalLocation!
        : transitFacade.departureLocation!;
    var locationTitle = airlineData != null
        ? (location.context as AirportLocationContext).airportCode
        : location.toString();
    var locationSubtitle = airlineData != null
        ? location.context.name
        : (location.context.locationType != LocationType.city
            ? location.context.city
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locationTitle,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (locationSubtitle != null)
          Text(
            locationSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _createDateTime(BuildContext context, bool isArrival) {
    var dateTime = isArrival
        ? transitFacade.arrivalDateTime!
        : transitFacade.departureDateTime!;
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: context.isLightTheme ? Colors.teal : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@ ${DateFormat('hh:mm a').format(dateTime)}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            DateFormat('dd MMM').format(dateTime),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
