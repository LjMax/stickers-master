import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moderation_provider.dart';
import '../../widgets/user_avatar.dart';
import 'chat_detail_screen.dart';

/// Combined inbox: incoming chat requests (Accept/Decline) and active chats.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.inboxTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(l.inboxEmptyNotSignedIn, textAlign: TextAlign.center)),
        ),
      );
    }

    final pending = ref.watch(incomingRequestsProvider);
    final chats = ref.watch(myChatsProvider);
    // Blocked users are filtered out of both sections.
    final iBlocked =
        ref.watch(iBlockedProvider).valueOrNull ?? const <String>{};
    final blockedAny = ref.watch(blockedUidsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.inboxTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Pending requests section — collapses silently if there are
          // none or if the Firestore query is still spinning up / errored.
          // We never surface raw exception text to the user (it can leak
          // project IDs and isn't actionable for the reader anyway).
          pending.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) {
              debugPrint('inbox: incoming requests error: $e');
              return const SizedBox.shrink();
            },
            data: (requests) {
              final visible = requests
                  .where((r) => !blockedAny.contains(r.fromUser))
                  .toList();
              if (visible.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: l.inboxSectionRequests),
                  ...visible.map((r) => _RequestTile(request: r)),
                ],
              );
            },
          ),
          chats.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) {
              // Same idea as above: log for the dev, show empty UI to
              // the user. This also keeps "fresh install" / "no chats
              // yet" looking clean.
              debugPrint('inbox: chats error: $e');
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Center(
                  child: Text(l.inboxEmpty, textAlign: TextAlign.center),
                ),
              );
            },
            data: (chatList) {
              final visibleChats = chatList
                  .where((c) => !iBlocked.contains(c.otherUid(user.uid)))
                  .where((c) => !c.isHiddenFor(user.uid))
                  .toList();
              final visiblePending =
                  (pending.valueOrNull ?? const <ChatRequest>[])
                      .where((r) => !blockedAny.contains(r.fromUser))
                      .toList();
              if (visibleChats.isEmpty && visiblePending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Center(child: Text(l.inboxEmpty, textAlign: TextAlign.center)),
                );
              }
              if (visibleChats.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: l.inboxSectionChats),
                  ...visibleChats.map((c) => _ChatTile(chat: c, myUid: user.uid)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.request});
  final ChatRequest request;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final chatId = await ref.read(chatRepositoryProvider).acceptRequest(
            req: widget.request,
            me: ChatParticipant(
              uid: user.uid,
              displayName: user.displayName ?? '',
              photoUrl: user.photoURL,
            ),
          );
      if (!mounted) return;
      // Navigate to the newly created chat.
      final chat = await ref.read(chatRepositoryProvider).getChat(chatId);
      if (chat != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatDetailScreen(chat: chat),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref.read(chatRepositoryProvider).declineRequest(widget.request.id);
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.inboxRequestDeclined)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.request;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: r.fromDisplayName,
                  photoUrl: r.fromPhotoUrl,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.fromDisplayName.isEmpty ? '—' : r.fromDisplayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.introMessage),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : _decline,
                  child: Text(l.inboxRequestDecline),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _busy ? null : _accept,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.inboxRequestAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat, required this.myUid});
  final Chat chat;
  final String myUid;

  static final _timeFmt = DateFormat.Hm();
  static final _dateFmt = DateFormat('d.M.');

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return sameDay ? _timeFmt.format(local) : _dateFmt.format(local);
  }

  /// Long-press handler: confirm, then "delete for me" (hide the chat).
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.chatDeleteTitle),
        content: Text(l.chatDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final l2 = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatRepositoryProvider).hideChatForMe(chat.id, myUid);
      messenger.showSnackBar(
        SnackBar(content: Text(l2.chatDeletedSnack)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final otherName = chat.otherName(myUid);
    final otherPhoto = chat.otherPhoto(myUid);
    final lastMsg = chat.lastMessage ?? l.chatNoLastMessage;
    final unread = chat.hasUnreadFor(myUid);

    return ListTile(
      leading: UserAvatar(name: otherName, photoUrl: otherPhoto, radius: 20),
      title: Text(
        otherName.isEmpty ? '—' : otherName,
        style: unread
            ? const TextStyle(fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(
        lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: unread
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              )
            : null,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageAt ?? chat.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: unread ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: unread ? FontWeight.w700 : null,
                ),
          ),
          const SizedBox(height: 4),
          if (unread)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(chat: chat),
      )),
      onLongPress: () => _confirmDelete(context, ref),
    );
  }
}
