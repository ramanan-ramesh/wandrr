import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/events.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/services/conflict_detection/trip_entity_update_plan.dart';

import '../../blocs/app/bloc.dart';
import '../../blocs/app/events.dart';

extension BlocProviderExt on BuildContext {
  MasterPageBloc get masterPageBloc => BlocProvider.of<MasterPageBloc>(this);

  TripManagementBloc get tripManagementBloc =>
      BlocProvider.of<TripManagementBloc>(this);

  TripManagementState get tripManagementState => tripManagementBloc.state;

  void addAuthenticationEvent(AuthenticationEvent event) {
    masterPageBloc.add(event);
  }

  void addMasterPageEvent(MasterPageEvent event) {
    masterPageBloc.add(event);
  }

  void addTripManagementEvent(TripManagementEvent event) {
    tripManagementBloc.add(event);
  }
}

extension TripEntityEditorBlocExt on BuildContext {
  TripEntityEditorBloc<T> _getBloc<T extends TripEntity<Enum>>() =>
      BlocProvider.of<TripEntityEditorBloc<T>>(this);

  /// Current conflict plan – always read from the bloc, not from states.
  TripEntityUpdatePlan<T>? tripEntityUpdatePlan<T extends TripEntity<Enum>>() =>
      _getBloc<T>().currentPlan;

  T editableEntity<T extends TripEntity<Enum>>() =>
      _getBloc<T>().editableEntity;

  void addTripEntityEditorEvent<T extends TripEntity<Enum>>(
      TripEntityEditorEvent event) {
    _getBloc<T>().add(event);
  }
}
