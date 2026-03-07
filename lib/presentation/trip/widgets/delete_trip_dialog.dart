import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

class DeleteTripDialog extends StatelessWidget {
  final BuildContext widgetContext;
  final TripMetadataFacade tripMetadataFacade;

  const DeleteTripDialog(
      {required this.widgetContext,
      required this.tripMetadataFacade,
      super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedTripDialog(
      title: widgetContext.localizations.deleteTrip,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
      content: Text(
        widgetContext.localizations.deleteTripConfirmation,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widgetContext.localizations.no),
        ),
        ElevatedButton(
          onPressed: () {
            widgetContext.addTripManagementEvent(
              UpdateTripEntity<TripMetadataFacade>.delete(
                  tripEntity: tripMetadataFacade),
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
          ),
          child: Text(widgetContext.localizations.yes),
        ),
      ],
    );
  }
}
