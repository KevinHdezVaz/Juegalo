import 'package:flutter/widgets.dart';
import 'package:juegalo_gana_dinero/l10n/app_localizations.dart';

export 'package:juegalo_gana_dinero/l10n/app_localizations.dart';

extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
