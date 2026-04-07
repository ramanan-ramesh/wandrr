import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/events.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'app/bloc.dart';
import 'app/events.dart';

extension BlocProviderExt on BuildContext {
  void addAuthenticationEvent(AuthenticationEvent event) {
    BlocProvider.of<MasterPageBloc>(this).add(event);
  }

  void addMasterPageEvent(MasterPageEvent event) {
    BlocProvider.of<MasterPageBloc>(this).add(event);
  }

  void addTripManagementEvent(TripManagementEvent event) {
    BlocProvider.of<TripManagementBloc>(this).add(event);
  }
}

extension TripEntityEditorBlocExt on BuildContext {
  TripEntityEditorBloc<T> _getBloc<T extends TripEntity>() =>
      BlocProvider.of<TripEntityEditorBloc<T>>(this);

  /// Current conflict plan – always read from the bloc, not from states.
  TripEntityUpdatePlan<T>? tripEntityUpdatePlan<T extends TripEntity>() =>
      _getBloc<T>().currentPlan;

  T editableEntity<T extends TripEntity>() => _getBloc<T>().editableEntity;

  void addTripEntityEditorEvent<T extends TripEntity>(
      TripEntityEditorEvent event) {
    _getBloc<T>().add(event);
  }
}
