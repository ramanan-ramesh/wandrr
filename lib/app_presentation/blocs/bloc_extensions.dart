import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'authentication/auth_bloc.dart';
import 'authentication/auth_events.dart';
import 'master_page/master_page_bloc.dart';
import 'master_page/master_page_events.dart';
import 'trip_management/bloc.dart';
import 'trip_management/events.dart';

extension BlocProviderExt on BuildContext {
  void addAuthenticationEvent(AuthenticationEvent event) {
    BlocProvider.of<AuthenticationBloc>(this).add(event);
  }

  void addMasterPageEvent(MasterPageEvent event) {
    BlocProvider.of<MasterPageBloc>(this).add(event);
  }

  void addTripManagementEvent(TripManagementEvent event) {
    BlocProvider.of<TripManagementBloc>(this).add(event);
  }
}
