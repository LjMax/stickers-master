import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../models/album.dart';
import '../models/sticker.dart';
import '../providers/locale_provider.dart';

/// Builds a plain-text swap list ready to paste into WhatsApp / SMS /
/// anywhere else. Two sections: "TRAŽIM" (missing) and "ZA ZAMENU"
/// (duplicates with counts). Stickers are grouped by team, with the WC
/// group letter shown in parentheses for context.
class ShareListBuilder {
  ShareListBuilder({
    required this.album,
    required this.counts,
    required this.locale,
    required this.l10n,
  });

  final Album album;
  final Map<String, int> counts;
  final Locale locale;
  final AppLocalizations l10n;

  String build() {
    final missingByGroup = <String, List<Sticker>>{};
    final duplicatesByGroup = <String, List<Sticker>>{};

    for (final s in album.stickers) {
      final c = counts[s.code] ?? 0;
      if (c == 0) {
        missingByGroup.putIfAbsent(s.groupCode, () => []).add(s);
      } else if (c >= 2) {
        duplicatesByGroup.putIfAbsent(s.groupCode, () => []).add(s);
      }
    }

    final albumName =
        pickLocalized(locale, album.nameSrLatn, album.nameEn);
    final owned = counts.values.where((c) => c >= 1).length;
    final pct = album.totalStickers == 0
        ? '0.0'
        : (owned * 100 / album.totalStickers).toStringAsFixed(1);

    final buf = StringBuffer();
    buf.writeln(l10n.shareHeader(albumName));
    buf.writeln(l10n.shareProgress(owned, album.totalStickers, pct));

    if (missingByGroup.isEmpty && duplicatesByGroup.isEmpty) {
      buf.writeln();
      buf.writeln(l10n.shareEmpty);
      return buf.toString().trim();
    }

    if (missingByGroup.isNotEmpty) {
      buf.writeln();
      buf.writeln(l10n.shareWanted + ':');
      _writeGroupedList(buf, missingByGroup, isMissing: true);
    }

    if (duplicatesByGroup.isNotEmpty) {
      buf.writeln();
      buf.writeln(l10n.shareOffered + ':');
      _writeGroupedList(buf, duplicatesByGroup, isMissing: false);
    }

    return buf.toString().trimRight();
  }

  void _writeGroupedList(
    StringBuffer buf,
    Map<String, List<Sticker>> byGroup, {
    required bool isMissing,
  }) {
    // Maintain album order: iterate album.stickers's first-occurrence order.
    final orderedGroupCodes = <String>[];
    for (final s in album.stickers) {
      if (byGroup.containsKey(s.groupCode) &&
          !orderedGroupCodes.contains(s.groupCode)) {
        orderedGroupCodes.add(s.groupCode);
      }
    }

    for (final groupCode in orderedGroupCodes) {
      final list = byGroup[groupCode]!;
      final first = list.first;
      final groupName =
          pickLocalized(locale, first.groupNameSrLatn, first.groupNameEn);
      final groupSuffix =
          first.wcGroup != null ? ' (${first.wcGroup})' : '';

      final entries = list.map((s) {
        if (isMissing) return s.code;
        // For duplicates show the extras count: 2 owned -> "x1", 3 owned -> "x2"
        final extras = (counts[s.code] ?? 0) - 1;
        return extras > 1 ? '${s.code} x$extras' : s.code;
      }).join(', ');

      buf.writeln('$groupName$groupSuffix: $entries');
    }
  }
}
