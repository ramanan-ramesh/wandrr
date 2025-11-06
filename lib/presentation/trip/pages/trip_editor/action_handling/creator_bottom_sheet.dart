import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEntityCreatorBottomSheet extends StatefulWidget {
  final Iterable<TripEditorAction> supportedActions;

  TripEntityCreatorBottomSheet({super.key, required this.supportedActions});

  @override
  State<TripEntityCreatorBottomSheet> createState() =>
      _TripEntityCreatorBottomSheetState();
}

class _TripEntityCreatorBottomSheetState
    extends State<TripEntityCreatorBottomSheet> {
  TripEditorAction? selectedAction;

  @override
  Widget build(BuildContext context) {
    const double _fabBottomMargin = 25.0;
    final double _bottomPadding =
        TripEditorPageConstants.fabSize + _fabBottomMargin + 16.0;

    return DraggableScrollableSheet(
      expand: false,
      shouldCloseOnMinExtent: false,
      initialChildSize: selectedAction != null ? 0.8 : 0.5,
      maxChildSize: 0.85,
      minChildSize: selectedAction != null ? 0.8 : 0.5,
      builder: (context, scrollController) {
        if (selectedAction == null) {
          return _createSupportedActionsListView(
              scrollController, _bottomPadding);
        }
        var tripEntityToAdd = selectedAction!.createTripEntity(context);
        return selectedAction!.createActionPage(
            tripEntity: tripEntityToAdd,
            isEditing: false,
            onClosePressed: (context) => setState(() {
                  selectedAction = null;
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
    final title = action.getTripEntityCreatorTitle(context.localizations);
    final subtitle = action.createSubtitle(context.localizations, false);
    return ListTile(
      contentPadding: const EdgeInsets.all(20.0),
      onTap: () {
        if (selectedAction == action) {
          return;
        }

        setState(() {
          selectedAction = action;
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
      title: title == null
          ? null
          : Text(
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
