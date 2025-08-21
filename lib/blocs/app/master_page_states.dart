import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';

abstract class MasterPageState {}

class Loading extends MasterPageState {}

class LoadedRepository extends MasterPageState {
  final AppDataFacade appData;

  LoadedRepository({required this.appData});
}

class ActiveLanguageChanged extends MasterPageState {}

class ActiveThemeModeChanged extends MasterPageState {}

class AuthStateChanged extends MasterPageState {
  final AuthStatus authStatus;

  AuthStateChanged({required this.authStatus});
}
