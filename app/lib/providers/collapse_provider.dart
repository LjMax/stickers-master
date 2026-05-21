import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which sections in the album view are currently collapsed.
///
/// Section keys (free-form strings, scoped per album):
///   * `specials` — the FWC specials section
///   * `wc:A`, `wc:B`, …, `wc:L` — WC group sections
///
/// Collapsed = hidden body, header still visible. Default = all expanded.
class CollapsedSectionsNotifier extends StateNotifier<Set<String>> {
  CollapsedSectionsNotifier() : super(const {});

  bool isCollapsed(String key) => state.contains(key);

  void toggle(String key) {
    final next = Set<String>.from(state);
    if (!next.add(key)) next.remove(key);
    state = next;
  }

  void collapseAll(Iterable<String> keys) {
    state = {...state, ...keys};
  }

  void expandAll() {
    state = const {};
  }
}

/// Per-album collapsed section state. Family on albumId so multi-album future
/// doesn't share state across albums.
final collapsedSectionsProvider =
    StateNotifierProvider.family<CollapsedSectionsNotifier, Set<String>, String>(
        (ref, albumId) {
  return CollapsedSectionsNotifier();
});
