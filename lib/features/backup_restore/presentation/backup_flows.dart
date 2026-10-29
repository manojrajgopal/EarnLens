import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/backup/backup_service.dart';
import '../../../domain/models/settings.dart';
import '../../../shared/widgets/components.dart';
import '../../settings/presentation/settings_widgets.dart';

/// Friendly names for database tables shown in previews and storage info.
const tableLabels = <String, String>{
  'profiles': 'Profile',
  'settings': 'Preference groups',
  'income_sources': 'Income sources',
  'rate_revisions': 'Pay revisions',
  'source_pauses': 'Pauses',
  'day_overrides': 'Holidays & leave days',
  'compensation_items': 'Bonuses & extra pay',
  'monthly_records': 'Monthly records',
  'ledger_entries': 'Transactions',
  'calendar_events': 'Calendar events',
  'audit_log': 'Change history entries',
  'notification_history': 'Notification history',
};

String _pad(int v) => v.toString().padLeft(2, '0');

// ============================================================================
// Create backup
// ============================================================================

Future<void> showCreateBackupSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateBackupSheet(),
    );

class _CreateBackupSheet extends ConsumerStatefulWidget {
  const _CreateBackupSheet();

  @override
  ConsumerState<_CreateBackupSheet> createState() => _CreateBackupSheetState();
}

class _CreateBackupSheetState extends ConsumerState<_CreateBackupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _encrypt = true;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run({required bool share}) async {
    if (_encrypt && !(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final service = ref.read(backupServiceProvider);
    final files = ref.read(fileServiceProvider);
    final controller = ref.read(settingsControllerProvider);
    final clock = ref.read(clockProvider);
    final existing = ref.read(backupStateProvider);
    final today = ref.read(todayProvider);
    try {
      final bytes = await service.createBackup(password: _encrypt ? _password.text : null);
      final name = 'earnlens-backup-${today.year}-${_pad(today.month)}-${_pad(today.day)}.earnlens';
      if (share) {
        await files.share(name, bytes, 'application/json');
      } else {
        final saved = await files.save(name, bytes, 'application/json');
        if (!saved) {
          messenger.showSnackBar(const SnackBar(content: Text('Backup not saved — you cancelled choosing a location.')));
          return;
        }
      }
      await controller.saveBackup(BackupState(lastBackupAt: clock.now(), reminderDays: existing.reminderDays));
      if (navigator.mounted && mounted) navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(share ? 'Backup created and handed to the share sheet.' : 'Backup saved as $name'),
      ));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('The backup could not be created. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SheetHeader(
                icon: Icons.backup_outlined,
                title: 'Create backup',
                subtitle: 'A single file with all your income sources, records, transactions and settings. '
                    'Your PIN is never included.',
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: SettingsSwitch(
                  icon: _encrypt ? Icons.lock_rounded : Icons.lock_open_rounded,
                  tone: _encrypt ? SettingsTone.mint : SettingsTone.peach,
                  title: 'Protect with a password',
                  subtitle: 'Recommended — encrypts the file with AES-256',
                  value: _encrypt,
                  onChanged: (v) => setState(() => _encrypt = v),
                ),
              ),
              if (_encrypt) ...[
                const SizedBox(height: AppSpace.sm),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Backup password',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const NoteCard(
                  warning: true,
                  icon: Icons.key_off_outlined,
                  message: 'If you forget this password the backup cannot be opened by anyone — including us. '
                      'Store it in a password manager.',
                ),
              ] else
                const NoteCard(
                  warning: true,
                  icon: Icons.lock_open_rounded,
                  message: 'Without a password anyone who gets this file can read your income details.',
                ),
              const SizedBox(height: AppSpace.xl),
              BusyButton(label: 'Save to file', accent: true, onPressed: () => _run(share: false)),
              const SizedBox(height: AppSpace.sm),
              _OutlinedBusy(label: 'Share…', icon: Icons.ios_share_rounded, onPressed: () => _run(share: true)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Outlined pill variant of [BusyButton].
class _OutlinedBusy extends StatefulWidget {
  const _OutlinedBusy({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  State<_OutlinedBusy> createState() => _OutlinedBusyState();
}

class _OutlinedBusyState extends State<_OutlinedBusy> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            foregroundColor: context.colors.accentText,
            side: BorderSide(color: context.colors.accentText.withValues(alpha: 0.3), width: 1.2),
          ),
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await widget.onPressed();
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(widget.icon),
          label: Text(widget.label),
        ),
      );
}

// ============================================================================
// Restore
// ============================================================================

Future<void> runRestoreFlow(BuildContext context, WidgetRef ref) async {
  final files = ref.read(fileServiceProvider);
  final service = ref.read(backupServiceProvider);
  final picked = await files.pick();
  if (picked == null || !context.mounted) return;

  BackupPreview? preview;
  if (BackupService.isEncrypted(picked.bytes)) {
    preview = await _askPasswordAndInspect(context, service, picked.bytes);
  } else {
    try {
      preview = await service.inspect(picked.bytes);
    } on AppException catch (e) {
      if (context.mounted) await _info(context, 'Cannot restore this file', e.message);
      return;
    } on Object {
      if (context.mounted) await _info(context, 'Cannot restore this file', 'This file is not a valid EarnLens backup.');
      return;
    }
  }
  if (preview == null || !context.mounted) return;

  final mode = await showModalBottomSheet<RestoreMode>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RestorePreviewSheet(preview: preview!, fileName: picked.name),
  );
  if (mode == null || !context.mounted) return;

  final ok = await confirmDialog(
    context,
    title: mode == RestoreMode.replace ? 'Replace all data?' : 'Merge backup?',
    message: mode == RestoreMode.replace
        ? 'Everything currently in EarnLens on this device will be permanently deleted and replaced with the '
            'backup from ${DateFormat('d MMM yyyy').format(preview.createdAt.toLocal())}. This cannot be undone. '
            'Consider creating a backup of the current data first.'
        : 'Records from the backup that are not on this device will be added. Existing records, your profile and '
            'your settings stay as they are.',
    confirm: mode == RestoreMode.replace ? 'Delete and replace' : 'Merge',
    destructive: mode == RestoreMode.replace,
  );
  if (!ok || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(content: Row(children: [
        EarnLoader(size: 32),
        SizedBox(width: 20),
        Expanded(child: Text('Restoring…')),
      ])),
    ),
  );
  RestoreResult? result;
  String? error;
  try {
    result = await service.restore(preview, mode);
  } on AppException catch (e) {
    error = e.message;
  } on Object {
    error = 'The restore failed.';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (result != null) {
    await _info(
      context,
      'Restore complete',
      '${result.inserted} record${result.inserted == 1 ? '' : 's'} restored'
          '${result.skipped > 0 ? ', ${result.skipped} already present and skipped' : ''}.',
    );
  } else {
    await _info(context, 'Restore failed', '$error Nothing on this device was changed.');
  }
}

Future<BackupPreview?> _askPasswordAndInspect(BuildContext context, BackupService service, Uint8List bytes) =>
    showDialog<BackupPreview>(
      context: context,
      builder: (_) => _PasswordDialog(service: service, bytes: bytes),
    );

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.service, required this.bytes});
  final BackupService service;
  final Uint8List bytes;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty) {
      setState(() => _error = 'Enter the backup password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.service.inspect(widget.bytes, password: _controller.text);
      if (mounted) Navigator.pop(context, preview);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) setState(() => _error = 'This backup could not be opened.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: Icon(Icons.lock_rounded, color: context.colors.accentText, size: 30),
        title: const Text('Password protected backup'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter the password you chose when creating this backup.', style: AppType.body),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            enabled: !_busy,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Backup password',
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Unlock'),
          ),
        ],
      );
}

class _RestorePreviewSheet extends StatefulWidget {
  const _RestorePreviewSheet({required this.preview, required this.fileName});
  final BackupPreview preview;
  final String fileName;

  @override
  State<_RestorePreviewSheet> createState() => _RestorePreviewSheetState();
}

class _RestorePreviewSheetState extends State<_RestorePreviewSheet> {
  RestoreMode _mode = RestoreMode.merge;

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final c = context.colors;
    final rows = [
      for (final e in tableLabels.entries)
        if ((p.counts[e.key] ?? 0) > 0) (e.value, p.counts[e.key]!),
    ];
    final created = DateFormat('d MMM yyyy, HH:mm').format(p.createdAt.toLocal());
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            SheetHeader(
              icon: Icons.settings_backup_restore_rounded,
              tone: SettingsTone.mint,
              title: 'Backup contents',
              subtitle: widget.fileName,
            ),
            const SizedBox(height: AppSpace.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
              decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(children: [
                _kv(context, 'Created', created),
                _kv(context, 'App version', p.appVersion),
                _kv(context, 'Encrypted', p.encrypted ? 'Yes' : 'No'),
              ]),
            ),
            const SizedBox(height: AppSpace.md),
            if (rows.isEmpty)
              Text('This backup contains no records.', style: AppType.body)
            else
              Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: [
                for (final (label, n) in rows)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '$n ',
                          style: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: label, style: AppType.bodySmall.copyWith(color: c.ink)),
                      ]),
                    ),
                  ),
              ]),
            const SizedBox(height: AppSpace.xl),
            Text('How should it be restored?', style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.md),
            RadioGroup<RestoreMode>(
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v ?? _mode),
              child: Column(children: [
                for (final m in RestoreMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.fast,
                      decoration: BoxDecoration(
                        color: _mode == m
                            ? (m == RestoreMode.replace ? c.errorSoft : c.accentSoft)
                            : c.cardHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _mode == m
                              ? (m == RestoreMode.replace ? c.error : c.accentText).withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: RadioListTile<RestoreMode>(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        contentPadding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                        value: m,
                        title: Text(m.label, style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          m == RestoreMode.replace
                              ? 'Deletes everything on this device first, then loads the backup exactly as it was.'
                              : 'Keeps everything on this device and adds only records that are missing. Nothing is '
                                  'duplicated or overwritten; your current profile and settings are kept.',
                          style: AppType.bodySmall.copyWith(color: c.inkMuted),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const NoteCard(
              icon: Icons.verified_outlined,
              message: 'The restore runs as a single transaction: if anything goes wrong, nothing on this device '
                  'is changed.',
            ),
            const SizedBox(height: AppSpace.xl),
            if (_mode == RestoreMode.replace)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, _mode),
                child: const Text('Continue to replace'),
              )
            else
              GradientButton(
                onPressed: () => Navigator.pop(context, _mode),
                child: const Text('Continue to merge'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: AppType.body.copyWith(color: context.colors.inkMuted))),
          const SizedBox(width: AppSpace.sm),
          Flexible(child: Text(v, textAlign: TextAlign.end, style: AppType.label.copyWith(color: context.colors.ink))),
        ]),
      );
}

Future<void> _info(BuildContext context, String title, String message) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppType.body),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );

Future<void> showInfoDialog(BuildContext context, String title, String message) => _info(context, title, message);
