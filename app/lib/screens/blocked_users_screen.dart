import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/moderation_provider.dart';
import '../repositories/moderation_repository.dart';
import '../widgets/user_avatar.dart';

/// Lists the users the signed-in account has blocked, with an Unblock
/// action on each. Reached from Settings.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entries = ref.watch(myBlockEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.modBlockedUsersTitle)),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Never surface raw Firestore errors; show the neutral empty state.
        error: (e, st) {
          debugPrint('blocked users: $e');
          return _EmptyState(message: l.modBlockedUsersEmpty);
        },
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState(message: l.modBlockedUsersEmpty);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _BlockedTile(entry: list[i]),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          Icon(
            Icons.block,
            size: 56,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BlockedTile extends ConsumerStatefulWidget {
  const _BlockedTile({required this.entry});
  final BlockEntry entry;

  @override
  ConsumerState<_BlockedTile> createState() => _BlockedTileState();
}

class _BlockedTileState extends ConsumerState<_BlockedTile> {
  bool _busy = false;

  Future<void> _unblock(String displayName) async {
    final myUid = ref.read(currentUserProvider)?.uid;
    if (myUid == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(moderationRepositoryProvider).unblockUser(
            blockerUid: myUid,
            blockedUid: widget.entry.blockedUid,
          );
      // The list re-streams and this tile disappears on its own.
      messenger.showSnackBar(
        SnackBar(content: Text(l.modUnblockedSnack(displayName))),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = widget.entry.blockedName.isEmpty
        ? l.swapAnonymous
        : widget.entry.blockedName;

    return ListTile(
      leading: UserAvatar(
        name: name,
        photoUrl: widget.entry.blockedPhotoUrl,
        radius: 20,
      ),
      title: Text(name),
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () => _unblock(name),
              child: Text(l.modUnblock),
            ),
    );
  }
}
