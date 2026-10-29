import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/local/data_wiper.dart';
import '../../../domain/models/settings.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../authentication/application/session_controller.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../../refresh/application/app_refresher.dart';
import 'backup_flows.dart';
import 'csv_flows.dart';

/// Live row counts for the main tables.
final _tableCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  final db = ref.watch(databaseProvider);
  final tables = <drift.TableInfo<drift.Table, dynamic>>[
    db.incomeSources,
    db.rateRevisions,
    db.sourcePauses,
    db.dayOverrides,
    db.compensationItems,
    db.monthlyRecords,
    db.ledgerEntries,
    db.calendarEvents,
    db.auditLog,
  ];
  final names = [for (final t in tables) t.actualTableName];
  final sql = 'SELECT ${[for (final n in names) '(SELECT COUNT(*) FROM "$n") AS "$n"'].join(', ')}';
  return db
      .customSelect(sql, readsFrom: tables.toSet())
      .watchSingle()
      .map((row) => {for (final n in names) n: row.read<int>(n)});
});

class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.watch(backupStateProvider);
    final today = ref.watch(todayProvider);
    final cal = ref.watch(financialCalendarProvider);
    final sources = ref.watch(sourcesProvider);
    final hasSample = sources.any((s) => s.isSample);
    final c = context.colors;

    final last = backup.lastBackupAt;
    final String lastLabel;
    String? lastDetail;
    var overdue = false;
    if (last == null) {
      lastLabel = 'No backup yet';
      overdue = true;
    } else {
      final d = cal.dateOf(last.microsecondsSinceEpoch);
      final days = d.daysUntil(today);
      overdue = days >= backup.reminderDays;
      lastLabel = 'Last backup ${switch (days) {
        <= 0 => 'today',
        1 => 'yesterday',
        _ => '$days days ago',
      }}';
      lastDetail = formatDate(d);
    }

    Future<void> refresh() async {
      ref.invalidate(_tableCountsProvider);
      ref.invalidate(backupStateProvider);
      await ref.read(appRefresherProvider).refresh({RefreshScope.earnings});
      await ref.read(_tableCountsProvider.future);
    }

    return SettingsPage(
      title: 'Data management',
      onRefresh: refresh,
      children: [
        const SizedBox(height: AppSpace.sm),
        EntranceScale(
          child: _BackupHero(
            label: lastLabel,
            detail: lastDetail,
            overdue: overdue,
            reminderDays: backup.reminderDays,
            onBackup: () => showCreateBackupSheet(context),
          ),
        ),
        if (kIsWeb)
          const NoteCard(
            warning: true,
            icon: Icons.web_asset_off_outlined,
            message: 'In the browser, EarnLens stores your data in this browser only. Clearing site data, private '
                'windows or browser clean-up tools can delete it, and it is not shared with other browsers or '
                'devices. Create backups regularly.',
          ),
        SettingsGroup(title: 'Backup', children: [
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            tone: SettingsTone.peach,
            title: 'Backup reminder',
            subtitle: 'Remind me after ${backup.reminderDays} days without a backup',
            value: '${backup.reminderDays} days',
            onTap: () async {
              final v = await pickOption<int>(
                context,
                title: 'Remind me to back up after',
                values: const [7, 14, 30, 60, 90],
                selected: backup.reminderDays,
                label: (d) => '$d days',
              );
              if (v != null && context.mounted) {
                await runGuarded(
                  context,
                  () => ref
                      .read(settingsControllerProvider)
                      .saveBackup(BackupState(lastBackupAt: backup.lastBackupAt, reminderDays: v)),
                );
              }
            },
          ),
          SettingsTile(
            icon: Icons.settings_backup_restore_rounded,
            tone: SettingsTone.mint,
            title: 'Restore from backup',
            subtitle: 'Preview a backup, then replace or merge',
            onTap: () => runRestoreFlow(context, ref),
          ),
        ]),
        if (!ref.watch(notificationSettingsProvider).isOn(NotificationCategory.backupReminder))
          Padding(
            padding: const EdgeInsets.fromLTRB(10, AppSpace.sm + 2, 10, 0),
            child: Text(
              'Backup reminders are switched off in Notifications, so this interval only affects the warning above.',
              style: AppType.bodySmall.copyWith(color: c.inkMuted),
            ),
          ),
        const CsvSectionTiles(),
        SettingsGroup(
          title: 'Sample data',
          footer: hasSample
              ? 'Sample sources are named "Sample: …". Removing them deletes only sample records.'
              : 'Adds a clearly labelled example salary and side income so you can explore. You can remove it '
                  'at any time without touching your own data.',
          children: [
            if (hasSample)
              SettingsTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Remove sample data',
                danger: true,
                chevron: false,
                onTap: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Remove sample data?',
                    message: 'All sample income sources and their records will be deleted. Your own data is not '
                        'affected.',
                    confirm: 'Remove',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  await runGuarded(context, () async {
                    final n = await ref.read(sampleDataServiceProvider).remove();
                    if (context.mounted) {
                      showMessage(context, 'Removed $n sample source${n == 1 ? '' : 's'}');
                    }
                  });
                },
              )
            else
              SettingsTile(
                icon: Icons.science_outlined,
                tone: SettingsTone.sky,
                title: 'Add sample data',
                chevron: false,
                onTap: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Add sample data?',
                    message: 'Example income sources labelled "Sample" will be added alongside your own data. '
                        'They are included in totals until you remove them.',
                    confirm: 'Add samples',
                  );
                  if (!ok || !context.mounted) return;
                  await runGuarded(
                    context,
                    () => ref.read(sampleDataServiceProvider).insert(
                          currencyCode: ref.read(currencyProvider).code,
                          today: ref.read(todayProvider),
                        ),
                    success: 'Sample data added',
                  );
                },
              ),
          ],
        ),
        const _StorageSection(),
        const _ValidationSection(),
        SettingsGroup(title: 'Danger zone', children: [
          SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete all data',
            subtitle: 'Erase everything on this device and start again',
            danger: true,
            onTap: () => _deleteAll(context, ref),
          ),
        ]),
      ],
    );
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final first = await confirmDialog(
      context,
      title: 'Delete all data?',
      message: 'Every income source, record, transaction, setting and your PIN will be permanently erased from this '
          'device. Backup files you saved elsewhere are not affected. This cannot be undone.',
      confirm: 'Continue',
      destructive: true,
    );
    if (!first || !context.mounted) return;
    final typed = await showDialog<bool>(context: context, builder: (_) => const _TypeDeleteDialog());
    if (typed != true || !context.mounted) return;
    // Read everything up front: once the profile is gone the router leaves
    // this screen and its WidgetRef is disposed.
    final wiper = DataWiper(
      ref.read(databaseProvider),
      ref.read(pinServiceProvider),
      ref.read(notificationProviderProvider),
    );
    final pinConfigured = ref.read(pinConfiguredProvider.notifier);
    final session = ref.read(sessionProvider.notifier);
    await runGuarded(context, () async {
      await wiper.wipeEverything();
      pinConfigured.set(false);
      session.unlock();
    });
  }
}

class _TypeDeleteDialog extends StatefulWidget {
  const _TypeDeleteDialog();

  @override
  State<_TypeDeleteDialog> createState() => _TypeDeleteDialogState();
}

class _TypeDeleteDialogState extends State<_TypeDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ok = _controller.text.trim() == 'DELETE';
    return AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: c.error, size: 32),
      title: const Text('Type DELETE to confirm'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('This is your last chance to cancel.', style: AppType.body),
        const SizedBox(height: AppSpace.lg),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Type DELETE'),
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: Colors.white),
          onPressed: ok ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

class _StorageSection extends ConsumerWidget {
  const _StorageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(_tableCountsProvider);
    return SettingsGroup(
      title: 'Storage',
      footer: kIsWeb
          ? 'Stored in this browser\'s site storage for this address only.'
          : 'Stored in a private database inside the app\'s storage on this device.',
      children: [
        SettingsBlock(
          child: counts.when(
            loading: () => const LoadingState(label: 'Counting records'),
            error: (_, _) => Text('Record counts are unavailable right now.', style: AppType.body),
            data: (m) {
              final c = context.colors;
              final total = m.values.fold<int>(0, (a, b) => a + b);
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const SettingsIcon(Icons.dns_outlined, tone: SettingsTone.sky),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$total', style: AppType.amountMedium.copyWith(color: c.ink)),
                      Text('records on this device', style: AppType.caption.copyWith(color: c.inkMuted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: AppSpace.md),
                for (final e in m.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(
                        child: Text(tableLabels[e.key] ?? e.key, style: AppType.body.copyWith(color: c.inkMuted)),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: e.value > 0 ? c.accentSoft : c.cardHigh,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${e.value}',
                          textAlign: TextAlign.center,
                          style: AppType.label.copyWith(
                            color: e.value > 0 ? c.accentText : c.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
        ),
      ],
    );
  }
}

class _ValidationSection extends ConsumerStatefulWidget {
  const _ValidationSection();

  @override
  ConsumerState<_ValidationSection> createState() => _ValidationSectionState();
}

class _ValidationSectionState extends ConsumerState<_ValidationSection> {
  (bool ok, String message)? _result;

  Future<void> _check() async {
    final service = ref.read(backupServiceProvider);
    (bool, String) result;
    try {
      final bytes = await service.createBackup();
      final preview = await service.inspect(bytes);
      final total = preview.counts.values.fold<int>(0, (a, b) => a + b);
      result = (
        true,
        'All $total records were read, checked for missing references and verified with a checksum. '
            'A backup made now would restore correctly.',
      );
    } on AppException catch (e) {
      result = (false, e.message);
    } on Object {
      result = (false, 'Some records could not be read. Restoring a recent backup may fix this.');
    }
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = _result;
    return SettingsGroup(
      title: 'Data check',
      children: [
        SettingsBlock(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              'Reads every record, checks links between records and runs a full backup round-trip in memory. '
              'Nothing is changed or saved.',
              style: AppType.bodySmall.copyWith(color: c.inkMuted),
            ),
            if (r != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpace.md),
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: ShapeDecoration(
                    color: r.$1 ? c.positiveSoft : c.errorSoft,
                    shape: BlobBorder(BlobShapes.cloud(8, radius: 18, wobble: 0.4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(r.$1 ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: r.$1 ? c.positive : c.error, size: 20),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(r.$2, style: AppType.bodySmall.copyWith(color: c.ink))),
                  ]),
                ),
              ),
            const SizedBox(height: AppSpace.md),
            BusyButton(label: r == null ? 'Check my data' : 'Check again', accent: true, onPressed: _check),
          ]),
        ),
      ],
    );
  }
}

/// Backup status hero: last backup, reminder interval and the primary action.
class _BackupHero extends StatelessWidget {
  const _BackupHero({
    required this.label,
    required this.detail,
    required this.overdue,
    required this.reminderDays,
    required this.onBackup,
  });
  final String label;
  final String? detail;
  final bool overdue;
  final int reminderDays;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: 4),
            Flexible(child: Text(text, style: AppType.caption.copyWith(color: AppColors.white))),
          ]),
        );
    return EarnCard(
      accent: !overdue,
      dark: overdue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BlobBadge(
            size: 48,
            seed: 9,
            color: AppColors.white.withValues(alpha: 0.2),
            child: Icon(overdue ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, color: AppColors.white),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Backup status', style: AppType.caption.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 2),
              Text(label, style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
              if (detail != null)
                Text(detail!, style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpace.md),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (overdue) chip(Icons.warning_amber_rounded, 'Backup recommended'),
          chip(Icons.notifications_none_rounded, 'Reminder after $reminderDays days'),
        ]),
        const SizedBox(height: AppSpace.md),
        Text(
          'Backups are files you keep — EarnLens has no cloud copy.',
          style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: AppSpace.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.violet,
              minimumSize: const Size(64, 50),
            ),
            onPressed: onBackup,
            icon: const Icon(Icons.backup_rounded, size: 20),
            label: const Text('Create backup'),
          ),
        ),
      ]),
    );
  }
}
