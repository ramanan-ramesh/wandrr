import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_events.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_states.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

class MasterPageBloc extends Bloc<MasterPageEvent, MasterPageState> {
  final PlatformDataRepository _platformDataRepository;

  MasterPageBloc({required PlatformDataRepository platformDataRepository})
      : _platformDataRepository = platformDataRepository,
        super(Startup(appLevelData: platformDataRepository.appLevelData)) {
    on<ChangeTheme>(_onThemeChange);
    on<ChangeLanguage>(_onLanguageChange);
    on<ChangeUser>(_onUserChange);
    on<Logout>(_onLogout);

    //TODO: Should remove this?
    // add(LoadApp());
  }

  @override
  void onEvent(MasterPageEvent event) {
    super.onEvent(event);
    // if(event is AuthenticationSuccess){
    //   emit(ChangeUser.signIn(
    //       authProviderUser: state.authProviderUser,
    //       authenticationType: state.authenticationType));
    // }
  }

  FutureOr<void> _onThemeChange(
      ChangeTheme event, Emitter<MasterPageState> emit) {
    emit(ActiveThemeModeChanged(themeMode: event.themeModeToChangeTo));
  }

  FutureOr<void> _onLanguageChange(
      ChangeLanguage event, Emitter<MasterPageState> emit) {
    emit(ActiveLanguageChanged(language: event.languageToChangeTo));
  }

  FutureOr<void> _onUserChange(
      ChangeUser event, Emitter<MasterPageState> emit) async {
    if (event.authProviderUser != null && event.authenticationType != null) {
      var didUpdateUser = await _platformDataRepository.tryUpdateActiveUser(
          authProviderUser: event.authProviderUser!,
          authenticationType: event.authenticationType!);
      if (didUpdateUser) {
        emit(ActiveUserChanged(
            user: _platformDataRepository.appLevelData.activeUser));
      }
    }
  }

  FutureOr<void> _onLogout(Logout event, Emitter<MasterPageState> emit) async {
    bool didSignOut = await _platformDataRepository.trySignOut();
    if (didSignOut) {
      emit(ActiveUserChanged(user: null));
    }
  }
}
