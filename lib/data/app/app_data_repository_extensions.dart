import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/app_data.dart';

import 'models/platform_user.dart';

extension RepositoryExt on BuildContext {
  AppDataFacade get appDataRepository =>
      RepositoryProvider.of<AppDataFacade>(this);

  AppDataModifier get appDataModifier => appDataRepository as AppDataModifier;

  bool get isBigLayout => appDataRepository.isBigLayout;

  PlatformUser? get activeUser => appDataRepository.activeUser;
}
