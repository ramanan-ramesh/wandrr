import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'constants.dart';

class TripNavigator {
  final ScrollController _scrollController;

  TripNavigator({required ScrollController scrollController})
      : _scrollController = scrollController;

  Future jumpToList(BuildContext context, {double alignment = 0.0}) async {
    await Scrollable.ensureVisible(
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

  bool isSliverAppBarPinned(GlobalKey headerKey) {
    if (headerKey.currentContext == null) {
      return false;
    }
    final renderObject =
        headerKey.currentContext!.findRenderObject() as RenderSliver;
    final geometry = renderObject.geometry;
    if (geometry != null) {
      return geometry.layoutExtent == 0.0;
    }
    return false;
  }
}

extension TripNavigatorExt on BuildContext {
  TripNavigator get tripNavigator => RepositoryProvider.of<TripNavigator>(this);
}
