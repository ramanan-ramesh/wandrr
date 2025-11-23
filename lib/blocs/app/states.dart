import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';

abstract class MasterPageState {
  const MasterPageState();
}

class Loading extends MasterPageState {
  const Loading();
}

class LoadedRepository extends MasterPageState {
  final AppDataFacade appData;
  final UpdateInfo? updateInfo;

  const LoadedRepository({required this.appData, required this.updateInfo});
}

class ActiveLanguageChanged extends MasterPageState {
  const ActiveLanguageChanged();
}

class ActiveThemeModeChanged extends MasterPageState {
  const ActiveThemeModeChanged();
}

class AuthStateChanged extends MasterPageState {
  final AuthStatus authStatus;

  const AuthStateChanged({required this.authStatus});
}

class UpdateAvailable extends MasterPageState {
  final UpdateInfo updateInfo;

  const UpdateAvailable({required this.updateInfo});
}

class UpdateInfo {
  final String latestVersion;
  final bool isForceUpdate;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.isForceUpdate,
    required this.releaseNotes,
  });
}
