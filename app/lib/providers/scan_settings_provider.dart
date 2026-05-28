import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

/// Settings that control the sticker-scan flow. Currently a single
/// toggle for auto-advance, but isolated in its own provider so adding
/// further scan settings later (sound feedback, vibration, etc.) is
/// just one more field.
class ScanSettings {
  const ScanSettings({required this.autoAdvance});

  /// When true, the scan screen automatically resumes scanning after
  /// the user adds/duplicates a sticker (a short toast confirms the
  /// action). When false (default), the screen waits for the user to
  /// tap the explicit "Scan next sticker" button.
  ///
  /// Off by default because the explicit flow is more in-control for
  /// first-time users; power users doing bulk scans flip it on.
  final bool autoAdvance;

  ScanSettings copyWith({bool? autoAdvance}) =>
      ScanSettings(autoAdvance: autoAdvance ?? this.autoAdvance);
}

const _autoAdvanceKey = 'scan.auto_advance';

class ScanSettingsNotifier extends StateNotifier<ScanSettings> {
  ScanSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ScanSettings _load(SharedPreferences prefs) {
    return ScanSettings(autoAdvance: prefs.getBool(_autoAdvanceKey) ?? false);
  }

  Future<void> setAutoAdvance(bool v) async {
    state = state.copyWith(autoAdvance: v);
    await _prefs.setBool(_autoAdvanceKey, v);
  }
}

final scanSettingsProvider =
    StateNotifierProvider<ScanSettingsNotifier, ScanSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScanSettingsNotifier(prefs);
});
