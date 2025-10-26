import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEditorActionPage<T extends TripEntity> extends StatelessWidget {
  final void Function(BuildContext context) onClosePressed;
  final void Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final ScrollController scrollController;
  final Widget Function(ValueNotifier<bool> validityNotifier)
      pageContentCreator;
  final TripEditorAction tripEditorAction;
  final String title;
  final ValueNotifier<bool> validityNotifier = ValueNotifier<bool>(false);
  final T tripEntity;

  TripEditorActionPage(
      {super.key,
      required this.tripEntity,
      required this.title,
      required this.onClosePressed,
      required this.onActionInvoked,
      required this.scrollController,
      required this.tripEditorAction,
      required this.pageContentCreator,
      required this.actionIcon});

  @override
  Widget build(BuildContext context) {
    const double _fabBottomMargin = 25.0;
    final double _bottomPadding =
        TripEditorPageConstants.fabSize + _fabBottomMargin + 16.0;
    return Stack(
      children: [
        Column(
          children: [
            AppBar(
              leading: IconButton(
                  icon: const Icon(Icons.close),
                  style: context.isLightTheme
                      ? ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(AppColors.brandSecondary),
                        )
                      : null,
                  onPressed: () => onClosePressed(context)),
              title: Text(title),
              centerTitle: true,
              elevation: 0,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, _bottomPadding),
                child: pageContentCreator(validityNotifier),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: _fabBottomMargin,
          left: 0,
          right: 0,
          child: Center(
            child: _createActionButton(context),
          ),
        ),
      ],
    );
  }

  Widget _createActionButton(BuildContext context) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: AnimatedOpacity(
        opacity: 1.0,
        child: PlatformSubmitterFAB.conditionallyEnabled(
          child: Icon(actionIcon),
          valueNotifier: validityNotifier,
          callback: () => onActionInvoked(context),
        ),
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}
