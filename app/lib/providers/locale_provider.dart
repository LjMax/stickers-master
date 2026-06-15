import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

const _localeKey = 'app.locale';

/// Device languages that should default to the Serbian Latin
/// localisation on first install. Picked from the languages whose
/// readers can reliably parse Serbian Latin (the in-app Serbian
/// strings are written in standard Štokavian, the shared base of
/// SR/HR/BS/CNR; Macedonian readers can also follow it).
///
/// Anything outside this set falls through to English on first
/// install, which is what makes the app usable for international
/// users without forcing them to find the Settings tab in Serbian.
const Set<String> _balkanLatinLanguages = {'sr', 'hr', 'bs', 'cnr', 'mk'};

/// Locale state for the app.
///
/// First-install behaviour: device-aware — Balkan-language phones
/// open in Serbian Latin, everything else opens in English. Once the
/// user explicitly picks a language in Settings, that choice is
/// persisted and the device locale stops mattering.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final tag = prefs.getString(_localeKey);
    if (tag != null) {
      // User has explicitly chosen — honour it, regardless of device locale.
      if (tag.startsWith('en')) return const Locale('en');
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    // First run — pick based on the device's system language.
    final deviceLang = PlatformDispatcher.instance.locale.languageCode;
    if (_balkanLatinLanguages.contains(deviceLang)) {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    return const Locale('en');
  }

  Future<void> setEnglish() async {
    state = const Locale('en');
    await _prefs.setString(_localeKey, 'en');
  }

  Future<void> setSerbianLatin() async {
    state = const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    await _prefs.setString(_localeKey, 'sr-Latn');
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

/// Convenience: pick the right localized field on a model based on current locale.
String pickLocalized(Locale locale, String srLatn, String en) {
  return locale.languageCode == 'en' ? en : srLatn;
}
