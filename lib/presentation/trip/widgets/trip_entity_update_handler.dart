import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

class TripEntityUpdateHandler<T extends TripEntity> extends StatelessWidget {
  final WidgetBuilder widgetBuilder;
  final bool Function(T beforeUpdate, T afterUpdate) shouldRebuild;

  const TripEntityUpdateHandler(
      {super.key, required this.widgetBuilder, required this.shouldRebuild});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listener: (context, state) {},
      builder: (context, state) {
        return widgetBuilder(context);
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<T>()) {
          var updatedTripEntity = currentState as UpdatedTripEntity;
          if (updatedTripEntity.dataState == DataState.update) {
            var collectionChangeset = updatedTripEntity
                .tripEntityModificationData
                .modifiedCollectionItem as CollectionItemChangeSet<T>;
            return shouldRebuild(collectionChangeset.beforeUpdate,
                collectionChangeset.afterUpdate);
          }
        }
        return false;
      },
    );
  }
}
