import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'constants.dart';

class TripNavigator {
  final ScrollController _scrollController;

  TripNavigator({required ScrollController scrollController})
      : _scrollController = scrollController;

  void jumpToList(BuildContext context) {
    Scrollable.ensureVisible(
      context,
      curve: Curves.easeInOutBack,
      alignment: 0.0,
    );
  }

  void animateToListItem(
      BuildContext context, ListController listController, int index) {
    listController.animateToItem(
        index: index,
        scrollController: _scrollController,
        alignment: 0.5,
        duration: (val) => NavAnimationDurations.navigateToSection,
        curve: (val) => Curves.easeInOutBack);
  }
}
