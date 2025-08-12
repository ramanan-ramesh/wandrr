import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'constants.dart';

class TripNavigator {
  final ScrollController _scrollController;

  TripNavigator({required ScrollController scrollController})
      : _scrollController = scrollController;

  void jumpToList(BuildContext context, {double alignment = 0.0}) {
    Scrollable.ensureVisible(
      context,
      curve: Curves.easeInOutBack,
      alignment: alignment,
    );
  }

  void animateToListItem(
      BuildContext context, ListController listController, int index,
      {double alignment = 0.5,
      Duration duration = NavAnimationDurations.navigateToSection}) {
    listController.animateToItem(
        index: index,
        scrollController: _scrollController,
        alignment: alignment,
        duration: (val) => duration,
        curve: (val) => Curves.easeInOutBack);
  }
}
