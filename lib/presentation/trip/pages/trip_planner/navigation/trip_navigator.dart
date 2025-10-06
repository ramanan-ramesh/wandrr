import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripNavigator {
  const TripNavigator();
  Future jumpToList(BuildContext context, {double alignment = 0.0}) async {
    await Scrollable.ensureVisible(
      context,
      curve: Curves.easeInOutBack,
      alignment: alignment,
    );
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
