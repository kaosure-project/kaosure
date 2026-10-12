import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

const appLocaleStorageKey = 'kaosure.app.locale';

final initialLocaleProvider = Provider<Locale?>((ref) => null);

final localePreferencesProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

Locale? findSupportedLocale(String? languageTag) {
  if (languageTag == null) {
    return null;
  }

  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.toLanguageTag() == languageTag) {
      return locale;
    }
  }

  return null;
}

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    return ref.watch(initialLocaleProvider);
  }

  Future<void> setLocale(Locale? locale) async {
    final preferences = ref.read(localePreferencesProvider);

    // null means following the device language.
    if (locale == null) {
      await preferences.remove(appLocaleStorageKey);
      state = null;
      return;
    }

    final supportedLocale = findSupportedLocale(
      locale.toLanguageTag(),
    );

    if (supportedLocale == null) {
      throw ArgumentError.value(
        locale,
        'locale',
        'Unsupported application locale',
      );
    }

    // Update the app only after saving succeeds.
    await preferences.setString(
      appLocaleStorageKey,
      supportedLocale.toLanguageTag(),
    );

    state = supportedLocale;
  }
}