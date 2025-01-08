import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/implementations/app_data.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_events.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_states.dart';

class _LoadRepository extends MasterPageEvent {}

class MasterPageBloc extends Bloc<MasterPageEvent, MasterPageState> {
  static AppDataModifier? _appDataRepository;

  MasterPageBloc() : super(Loading()) {
    on<ChangeTheme>(_onThemeChange);
    on<ChangeLanguage>(_onLanguageChange);
    on<ChangeUser>(_onUserChange);
    on<Logout>(_onLogout);
    on<_LoadRepository>(_onLoadRepository);
    add(_LoadRepository());
  }

  FutureOr<void> _onLoadRepository(
      _LoadRepository event, Emitter<MasterPageState> emit) async {
    _appDataRepository ??= await AppDataRepository.create();
    emit(LoadedRepository(appData: _appDataRepository!));
  }

  FutureOr<void> _onThemeChange(
      ChangeTheme event, Emitter<MasterPageState> emit) async {
    await _appDataRepository!.setActiveThemeMode(event.themeModeToChangeTo);
    emit(ActiveThemeModeChanged(themeMode: event.themeModeToChangeTo));
  }

  FutureOr<void> _onLanguageChange(
      ChangeLanguage event, Emitter<MasterPageState> emit) async {
    if (_appDataRepository!.activeLanguage == event.languageToChangeTo) {
      return;
    }
    await _appDataRepository!.setActiveLanguage(event.languageToChangeTo);
    emit(ActiveLanguageChanged(language: event.languageToChangeTo));
  }

  FutureOr<void> _onUserChange(
      ChangeUser event, Emitter<MasterPageState> emit) async {
    if (event.authProviderUser != null && event.authenticationType != null) {
      var didUpdateUser = await _appDataRepository!.trySignIn(
          authProviderUser: event.authProviderUser!,
          authenticationType: event.authenticationType!);
      if (didUpdateUser) {
        emit(ActiveUserChanged(user: _appDataRepository!.activeUser));
      }
    }
  }

  FutureOr<void> _onLogout(Logout event, Emitter<MasterPageState> emit) async {
    bool didSignOut = await _appDataRepository!.trySignOut();
    if (didSignOut) {
      emit(ActiveUserChanged(user: null));
    }
  }
}
