import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/implementations/app_data.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/presentation/app/bloc/master_page_events.dart';
import 'package:wandrr/presentation/app/bloc/master_page_states.dart';

class _LoadRepository extends MasterPageEvent {}

class MasterPageBloc extends Bloc<MasterPageEvent, MasterPageState> {
  static AppDataModifier? _appDataRepository;

  MasterPageBloc() : super(Loading()) {
    on<ChangeTheme>(_onThemeChange);
    on<ChangeLanguage>(_onLanguageChange);
    on<AuthenticateWithUsernamePassword>(_onAuthenticateWithUsernamePassword);
    on<AuthenticateWithThirdParty>(_onAuthenticateWithThirdParty);
    on<Logout>(_onLogout);
    on<_LoadRepository>(_onLoadRepository);

    add(_LoadRepository());
  }

  FutureOr<void> _onLoadRepository(
      _LoadRepository event, Emitter<MasterPageState> emit) async {
    _appDataRepository ??= await AppDataRepository.createInstance();
    emit(LoadedRepository(appData: _appDataRepository!));
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
    bool didSignOut =
        await _appDataRepository!.userManagementModifier.trySignOut();
    if (didSignOut) {
      emit(AuthStateChanged(authStatus: AuthStatus.loggedOut));
    }
  }

  FutureOr<void> _onAuthenticateWithUsernamePassword(
      AuthenticateWithUsernamePassword event,
      Emitter<MasterPageState> emit) async {
    emit(AuthStateChanged(authStatus: AuthStatus.authenticating));
    AuthStatus authStatus = AuthStatus.undefined;
    if (event.shouldRegister) {
      authStatus = await _appDataRepository!.userManagementModifier
          .trySignUpWithUsernamePassword(
              userName: event.userName, password: event.password);
    } else {
      authStatus = await _appDataRepository!.userManagementModifier
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
    AuthStatus authStatus = await _appDataRepository!.userManagementModifier
        .trySignInWithThirdParty(event.authenticationType);
    if (authStatus == AuthStatus.loggedIn) {
      emit(AuthStateChanged(authStatus: AuthStatus.loggedIn));
    } else {
      emit(AuthStateChanged(authStatus: authStatus));
    }
  }
}
