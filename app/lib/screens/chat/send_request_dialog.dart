import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/public_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../repositories/chat_repository.dart';

const int _maxLen = 280;

/// Modal bottom sheet for composing a chat request to a swap partner.
/// Opens from the Swap screen's "Poruka" button.
Future<void> showSendRequestSheet(
  BuildContext context, {
  required PublicProfile toProfile,
  required String albumId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _SendRequestSheet(toProfile: toProfile, albumId: albumId),
  );
}

class _SendRequestSheet extends ConsumerStatefulWidget {
  const _SendRequestSheet({required this.toProfile, required this.albumId});
  final PublicProfile toProfile;
  final String albumId;

  @override
  ConsumerState<_SendRequestSheet> createState() => _SendRequestSheetState();
}

class _SendRequestSheetState extends ConsumerState<_SendRequestSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = ref.read(currentUserProvider);
    final l = AppLocalizations.of(context);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.requestSignInRequired)),
      );
      return;
    }
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final repo = ref.read(chatRepositoryProvider);

      // Cooldown / duplicate-request guard. Stops re-spamming someone who
      // declined, and prevents sending a second request while one is
      // still pending.
      final check = await repo.checkCanSendRequest(
        user.uid,
        widget.toProfile.uid,
      );
      if (check.check != SendRequestCheck.ok) {
        if (!mounted) return;
        final msg = check.check == SendRequestCheck.alreadyPending
            ? l.requestAlreadyPending
            : l.requestCooldownActive(_cooldownHours(check.cooldownRemaining));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        setState(() => _sending = false);
        return;
      }

      await repo.sendRequest(
            fromUid: user.uid,
            fromDisplayName: user.displayName ?? '',
            fromPhotoUrl: user.photoURL,
            toUid: widget.toProfile.uid,
            albumId: widget.albumId,
            introMessage: text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.requestSent)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Cooldown remaining rounded up to whole hours, kept within 1..24, so
  /// the "try again in {hours} h" message is always sensible.
  int _cooldownHours(Duration? remaining) {
    if (remaining == null || remaining.inMinutes <= 0) return 1;
    final hours = (remaining.inMinutes / 60).ceil();
    if (hours < 1) return 1;
    if (hours > 24) return 24;
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + mq),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.requestDialogTitle(widget.toProfile.displayName.isEmpty
                ? '—'
                : widget.toProfile.displayName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLength: _maxLen,
            maxLines: 4,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.requestDialogHint,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l.requestDialogCharsLeft(_maxLen - _ctrl.text.length),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: Text(l.requestDialogCancel),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: (_sending || _ctrl.text.trim().isEmpty) ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(l.requestDialogSend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
