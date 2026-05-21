import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'screens/album_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/chat/inbox_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/swap_screen.dart';
import 'services/fcm_service.dart';

/// Bottom-navigation shell with five top-level destinations:
/// Album, Stats, Swap, Inbox, Settings.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  /// Index of the Inbox destination in [_pages] / the NavigationBar.
  static const _inboxTabIndex = 3;

  final _pages = const [
    AlbumScreen(),
    StatsScreen(),
    SwapScreen(),
    InboxScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    NotificationRoute.pending.addListener(_onNotificationRoute);
    // A deep-link may already be buffered if the app was launched from a
    // terminated state by tapping a push. Handle it once the first frame
    // is up so the Navigator is ready.
    if (NotificationRoute.hasPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onNotificationRoute();
      });
    }
  }

  @override
  void dispose() {
    NotificationRoute.pending.removeListener(_onNotificationRoute);
    super.dispose();
  }

  /// Consumes a pending notification deep-link and routes to it.
  ///
  ///  - `chat_message` → Inbox tab + open the specific chat.
  ///  - `chat_request` → Inbox tab (the Accept/Decline tile lives there;
  ///    there is no chat to open until the request is accepted).
  void _onNotificationRoute() {
    if (!NotificationRoute.hasPending) return;
    final data = NotificationRoute.consume();
    if (data == null || !mounted) return;

    final type = data['type'];
    if (type == 'chat_message' || type == 'chat_request') {
      setState(() => _index = _inboxTabIndex);
    }
    if (type == 'chat_message') {
      final chatId = data['chat_id'];
      if (chatId != null && chatId.isNotEmpty) {
        _openChat(chatId);
      }
    }
  }

  Future<void> _openChat(String chatId) async {
    try {
      final chat = await ref.read(chatRepositoryProvider).getChat(chatId);
      if (chat != null && mounted) {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatDetailScreen(chat: chat),
        ));
      }
    } catch (e) {
      // If the chat can't be loaded yet (e.g. auth still restoring on a
      // cold launch), the user still lands on the Inbox tab and can tap
      // through manually — acceptable fallback, no error shown.
      debugPrint('notification deep-link: openChat failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inboxBadge = ref.watch(inboxBadgeCountProvider);

    // With 5 destinations, the default labelMedium (~12sp) can wrap on
    // longer Serbian labels like "Podešavanja" on average phone widths.
    // Override to a smaller, single-weight label so all 5 fit comfortably
    // on one line.
    final navTheme = NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 10.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          height: 1.1,
        );
      }),
      // Slightly tighter destination icon size so the bar feels balanced.
      iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 22)),
    );

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBarTheme(
        data: navTheme,
        child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l.tabAlbum,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l.tabStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz),
            label: l.tabSwap,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: inboxBadge > 0,
              label: Text('$inboxBadge'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: inboxBadge > 0,
              label: Text('$inboxBadge'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: l.tabInbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
        ),
      ),
    );
  }
}
