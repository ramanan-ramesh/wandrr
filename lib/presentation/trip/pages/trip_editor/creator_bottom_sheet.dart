import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEntityCreatorBottomSheet extends StatefulWidget {
  final Iterable<TripEditorAction> supportedActions;
  final DateTime? tripDay;

  TripEntityCreatorBottomSheet(
      {super.key, required this.supportedActions, this.tripDay});

  @override
  State<TripEntityCreatorBottomSheet> createState() =>
      _TripEntityCreatorBottomSheetState();
}

class _TripEntityCreatorBottomSheetState
    extends State<TripEntityCreatorBottomSheet> {
  TripEditorAction? selectedAction;
  TripEntity? tripEntityToUpdate;

  @override
  Widget build(BuildContext context) {
    // Constants for FAB sizing and margin
    const double _fabBottomMargin = 25.0;
    final double _bottomPadding =
        TripEditorPageConstants.fabSize + _fabBottomMargin + 16.0;

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        if (selectedAction == null) {
          return _createSupportedActionsListView(
              scrollController, _bottomPadding);
        }
        tripEntityToUpdate ??= selectedAction!.createTripEntity(context);
        return selectedAction!.createActionPage(
            tripEntity: tripEntityToUpdate!,
            tripDay: widget.tripDay,
            isEditing: false,
            onClosePressed: (context) => setState(() {
                  selectedAction = null;
                  tripEntityToUpdate = null;
                }),
            scrollController: scrollController,
            title:
                selectedAction!.createSubtitle(context.localizations, false))!;
      },
    );
  }

  Widget _createSupportedActionsListView(
      ScrollController scrollController, double bottomPadding) {
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: bottomPadding),
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      itemBuilder: (BuildContext context, int index) {
        var supportedAction = widget.supportedActions.elementAt(index);
        return _buildSupportedActionTile(supportedAction, context);
      },
      itemCount: widget.supportedActions.length,
    );
  }

  Widget _buildSupportedActionTile(
      TripEditorAction action, BuildContext context) {
    final icon = action.icon;
    final title = action.createTitle(context.localizations);
    final subtitle = action.createSubtitle(context.localizations, false);
    return ListTile(
      contentPadding: const EdgeInsets.all(20.0),
      onTap: () {
        if (selectedAction == action) {
          return;
        }

        setState(() {
          selectedAction = action;
          tripEntityToUpdate = null;
        });
      },
      leading: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color!.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28.0,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    );
  }
}
