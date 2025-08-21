import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';

class DeleteTripDialog extends StatelessWidget {
  final BuildContext widgetContext;
  final TripMetadataFacade tripMetadataFacade;

  const DeleteTripDialog(
      {required this.widgetContext,
      required this.tripMetadataFacade,
      super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(widgetContext.localizations.deleteTripConfirmation),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(widgetContext.localizations.no),
        ),
        TextButton(
          onPressed: () {
            widgetContext.addTripManagementEvent(
                UpdateTripEntity<TripMetadataFacade>.delete(
                    tripEntity: tripMetadataFacade));
            Navigator.of(context).pop();
          },
          child: Text(widgetContext.localizations.yes),
        ),
      ],
    );
  }
}
