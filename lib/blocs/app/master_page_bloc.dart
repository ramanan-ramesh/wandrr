import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wandrr/blocs/app/master_page_events.dart';
import 'package:wandrr/blocs/app/master_page_states.dart';
import 'package:wandrr/data/app/implementations/app_data.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';

class _LoadRepository extends MasterPageEvent {}

class _UpdateAvailableInternal extends MasterPageEvent {
  final UpdateInfo updateInfo;

  _UpdateAvailableInternal({required this.updateInfo});
}

class MasterPageBloc extends Bloc<MasterPageEvent, MasterPageState> {
  static AppDataModifier? _appDataRepository;
  late final StreamSubscription _updateRemoteConfigSubscription;

  MasterPageBloc() : super(Loading()) {
    on<ChangeTheme>(_onThemeChange);
    on<ChangeLanguage>(_onLanguageChange);
    on<AuthenticateWithUsernamePassword>(_onAuthenticateWithUsernamePassword);
    on<AuthenticateWithThirdParty>(_onAuthenticateWithThirdParty);
    on<ResendEmailVerification>((event, emit) async {
      var didResendVerificationEmail = await _appDataRepository!.userManagement
          .resendVerificationEmail(event.userName, event.password);
      if (didResendVerificationEmail) {
        emit(AuthStateChanged(authStatus: AuthStatus.verificationResent));
      }
    });
    on<Logout>(_onLogout);
    on<_LoadRepository>(_onLoadRepository);
    on<_UpdateAvailableInternal>((event, emit) {
      emit(UpdateAvailable(updateInfo: event.updateInfo));
    });

    add(_LoadRepository());
  }

  @override
  Future<void> close() {
    _updateRemoteConfigSubscription.cancel();
    return super.close();
  }

  FutureOr<void> _onLoadRepository(
      _LoadRepository event, Emitter<MasterPageState> emit) async {
    _appDataRepository ??= await AppDataRepository.createInstance();
    var updateInfo = await _checkForUpdate();
    emit(
        LoadedRepository(appData: _appDataRepository!, updateInfo: updateInfo));
    await _initUpdateListener();
  }

  FutureOr<void> _onThemeChange(
      ChangeTheme event, Emitter<MasterPageState> emit) async {
    await _appDataRepository!.setActiveThemeMode(event.themeModeToChangeTo);
    emit(ActiveThemeModeChanged());
  }

  FutureOr<void> _onLanguageChange(
      ChangeLanguage event, Emitter<MasterPageState> emit) async {
    if (_appDataRepository!.activeLanguage == event.languageToChangeTo) {
      return;
    }
    await _appDataRepository!.setActiveLanguage(event.languageToChangeTo);
    emit(ActiveLanguageChanged());
  }

  FutureOr<void> _onLogout(Logout event, Emitter<MasterPageState> emit) async {
    var didSignOut = await _appDataRepository!.userManagement.trySignOut();
    if (didSignOut) {
      emit(AuthStateChanged(authStatus: AuthStatus.loggedOut));
    }
  }

  FutureOr<void> _onAuthenticateWithUsernamePassword(
      AuthenticateWithUsernamePassword event,
      Emitter<MasterPageState> emit) async {
    emit(AuthStateChanged(authStatus: AuthStatus.authenticating));
    var authStatus = AuthStatus.undefined;
    if (event.shouldRegister) {
      authStatus = await _appDataRepository!.userManagement
          .trySignUpWithUsernamePassword(
              userName: event.userName, password: event.password);
    } else {
      authStatus = await _appDataRepository!.userManagement
          .trySignInWithUsernamePassword(
              userName: event.userName, password: event.password);
    }
    if (authStatus == AuthStatus.loggedIn) {
      emit(AuthStateChanged(authStatus: AuthStatus.loggedIn));
    } else {
      emit(AuthStateChanged(authStatus: authStatus));
    }
  }

  FutureOr<void> _onAuthenticateWithThirdParty(
      AuthenticateWithThirdParty event, Emitter<MasterPageState> emit) async {
    emit(AuthStateChanged(authStatus: AuthStatus.authenticating));
    var authStatus = await _appDataRepository!.userManagement
        .trySignInWithThirdParty(event.authenticationType);
    if (authStatus == AuthStatus.loggedIn) {
      emit(AuthStateChanged(authStatus: AuthStatus.loggedIn));
    } else {
      emit(AuthStateChanged(authStatus: authStatus));
    }
  }

  Future<void> _initUpdateListener() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(minutes: 5)));
    await remoteConfig.fetchAndActivate();

    _updateRemoteConfigSubscription =
        remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.activate();
      var updateInfo = await _checkForUpdate();
      if (updateInfo != null) {
        add(_UpdateAvailableInternal(updateInfo: updateInfo));
      }
    });
  }

  Future<UpdateInfo?> _checkForUpdate() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    final latestVersion = remoteConfig.getString('latest_version');
    final minVersion = remoteConfig.getString('min_version');
    final releaseNotes = remoteConfig.getString('release_notes');

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final latestBuildNumber = int.tryParse(latestVersion.split('+').last) ?? 0;
    final minBuildNumber = int.tryParse(minVersion.split('+').last) ?? 0;

    final updateRequired = latestBuildNumber > currentBuildNumber;
    final isForceUpdate = minBuildNumber >= currentBuildNumber;

    final versionName = latestVersion.split('+').first;

    return updateRequired
        ? UpdateInfo(
            latestVersion: versionName,
            isForceUpdate: isForceUpdate,
            releaseNotes: releaseNotes,
          )
        : null;
  }
}
