import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moderation_provider.dart';
import '../../widgets/moderation_dialogs.dart';
import '../../widgets/user_avatar.dart';

/// 1:1 chat screen. Streams messages from Firestore in real time; input
/// box at the bottom sends new messages via [ChatRepository].
class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.chat});
  final Chat chat;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Opening the chat counts as reading it — clear the unread badge.
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).markChatRead(widget.chat.id, uid);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String myUid) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: widget.chat.id,
            senderId: myUid,
            text: text,
          );
      _inputCtrl.clear();
      // Scroll to bottom after the new message renders.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onModerationMenu(
    String action,
    String myUid,
    String otherUid,
    String displayName,
    String? otherPhoto,
  ) {
    switch (action) {
      case 'block':
        _blockUser(myUid, otherUid, displayName, otherPhoto);
        break;
      case 'unblock':
        _unblockUser(myUid, otherUid, displayName);
        break;
      case 'report':
        showReportDialog(
          context,
          reportedUid: otherUid,
          reportedName: displayName,
          chatId: widget.chat.id,
        );
        break;
    }
  }

  Future<void> _blockUser(
    String myUid,
    String otherUid,
    String displayName,
    String? otherPhoto,
  ) async {
    final confirmed = await showBlockConfirmDialog(context, displayName);
    if (!confirmed || !mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(moderationRepositoryProvider).blockUser(
            blockerUid: myUid,
            blockedUid: otherUid,
            blockedName: displayName,
            blockedPhotoUrl: otherPhoto,
          );
      // The chat is now hidden from this user's inbox — leave the screen.
      if (mounted) navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.modBlockedSnack(displayName))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _unblockUser(
    String myUid,
    String otherUid,
    String displayName,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moderationRepositoryProvider).unblockUser(
            blockerUid: myUid,
            blockedUid: otherUid,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.modUnblockedSnack(displayName))),
      );
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final otherName = widget.chat.otherName(user.uid);
    final otherPhoto = widget.chat.otherPhoto(user.uid);
    final otherUid = widget.chat.otherUid(user.uid);
    final displayName = otherName.isEmpty ? l.swapAnonymous : otherName;
    final isBlocked =
        (ref.watch(iBlockedProvider).valueOrNull ?? const <String>{})
            .contains(otherUid);

    // While the chat is open, a message arriving from the other user is
    // read immediately — re-stamp last_read so the inbox badge stays clear.
    ref.listen(chatMessagesProvider(widget.chat.id), (prev, next) {
      next.whenData((messages) {
        if (messages.isEmpty || !mounted) return;
        if (messages.last.senderId != user.uid) {
          ref.read(chatRepositoryProvider).markChatRead(widget.chat.id, user.uid);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(name: otherName, photoUrl: otherPhoto, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(otherName.isEmpty ? '—' : otherName,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: '',
            onSelected: (v) => _onModerationMenu(
                v, user.uid, otherUid, displayName, otherPhoto),
            itemBuilder: (ctx) => [
              if (isBlocked)
                PopupMenuItem<String>(
                  value: 'unblock',
                  child: ModerationMenuRow(
                    icon: Icons.person_add_alt_1_outlined,
                    label: l.modUnblockUser,
                  ),
                )
              else
                PopupMenuItem<String>(
                  value: 'block',
                  child: ModerationMenuRow(
                    icon: Icons.block,
                    label: l.modBlockUser,
                  ),
                ),
              PopupMenuItem<String>(
                value: 'report',
                child: ModerationMenuRow(
                  icon: Icons.flag_outlined,
                  label: l.modReportUser,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(chatMessagesProvider(widget.chat.id)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (messages) => _MessageList(
                    messages: messages,
                    myUid: user.uid,
                    scrollCtrl: _scrollCtrl,
                  ),
                ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l.chatInputHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(user.uid),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(user.uid),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    tooltip: l.chatInputSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.myUid,
    required this.scrollCtrl,
  });

  final List<ChatMessage> messages;
  final String myUid;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).chatNoLastMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    // Auto-scroll to bottom on first build / when new messages arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        final mine = m.senderId == myUid;
        return _MessageBubble(message: m, mine: mine);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  static final _timeFmt = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(mine ? 14 : 2),
                bottomRight: Radius.circular(mine ? 2 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeFmt.format(message.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
