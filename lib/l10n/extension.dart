import 'package:flutter/material.dart';

import 'app_localizations.dart';

extension AppLocalizationsExt on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
}
