import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';

abstract class MasterPageState {}

class Loading extends MasterPageState {}

class LoadedRepository extends MasterPageState {
  final AppDataFacade appData;
  final UpdateInfo? updateInfo;

  LoadedRepository({required this.appData, required this.updateInfo});
}

class ActiveLanguageChanged extends MasterPageState {}

class ActiveThemeModeChanged extends MasterPageState {}

class AuthStateChanged extends MasterPageState {
  final AuthStatus authStatus;

  AuthStateChanged({required this.authStatus});
}

class UpdateAvailable extends MasterPageState {
  final UpdateInfo updateInfo;

  UpdateAvailable({required this.updateInfo});
}

class UpdateInfo {
  final String latestVersion;
  final bool isForceUpdate;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.isForceUpdate,
    required this.releaseNotes,
  });
}
