import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_events.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';

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
  TripEntityUpdatePlan? get tripEntityUpdatePlan =>
      BlocProvider.of<TripEntityEditorBloc>(this).currentPlan;

  void addTripEntityEditorEvent(TripEntityEditorEvent event) {
    BlocProvider.of<TripEntityEditorBloc>(this).add(event);
  }
}
