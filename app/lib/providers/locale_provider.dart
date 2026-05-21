import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

const _localeKey = 'app.locale';

/// Locale state for the app. Default is Serbian Latin.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final tag = prefs.getString(_localeKey);
    if (tag == null) return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    if (tag.startsWith('en')) return const Locale('en');
    return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
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
