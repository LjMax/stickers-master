import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/moderation_provider.dart';

/// Confirmation dialog shown before blocking a user. Returns `true` if the
/// user confirmed, `false` otherwise.
Future<bool> showBlockConfirmDialog(BuildContext context, String name) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.modBlockConfirmTitle(name)),
      content: Text(l.modBlockConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.modBlock),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Opens the abuse-report dialog. Picks a reason, optionally adds details,
/// and writes the report to Firestore. Self-contained — shows its own
/// success/error snackbar.
Future<void> showReportDialog(
  BuildContext context, {
  required String reportedUid,
  required String reportedName,
  String? chatId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReportDialog(
      reportedUid: reportedUid,
      reportedName: reportedName,
      chatId: chatId,
    ),
  );
}

/// A row (icon + label) for use as a [PopupMenuItem] child in the
/// moderation menus on the chat and swap screens.
class ModerationMenuRow extends StatelessWidget {
  const ModerationMenuRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({
    required this.reportedUid,
    required this.reportedName,
    this.chatId,
  });

  final String reportedUid;
  final String reportedName;
  final String? chatId;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  // Stored report reason codes (stable, not localized).
  String _reason = 'spam';
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(moderationRepositoryProvider).submitReport(
            reporterUid: user.uid,
            reportedUid: widget.reportedUid,
            reason: _reason,
            chatId: widget.chatId,
            details: _detailsCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.modReportSentSnack)));
    } catch (e) {
      debugPrint('moderation: report submit failed: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reasons = <String, String>{
      'spam': l.modReportReasonSpam,
      'harassment': l.modReportReasonHarassment,
      'inappropriate': l.modReportReasonInappropriate,
      'other': l.modReportReasonOther,
    };

    return AlertDialog(
      title: Text(l.modReportTitle(widget.reportedName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.modReportReasonLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            for (final entry in reasons.entries)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.value),
                value: entry.key,
                groupValue: _reason,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _reason = v ?? _reason),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsCtrl,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.modReportDetailsHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.modReportSubmit),
        ),
      ],
    );
  }
}
