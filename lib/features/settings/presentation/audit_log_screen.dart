import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/records.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../refresh/application/app_refresher.dart';
import 'settings_widgets.dart';

IconData _entityIcon(String type) => switch (type) {
      'source' => Icons.work_outline_rounded,
      'revision' => Icons.trending_up_rounded,
      'override' => Icons.beach_access_outlined,
      'item' => Icons.card_giftcard_rounded,
      'monthly' => Icons.calendar_view_month_rounded,
      'ledger' => Icons.receipt_long_outlined,
      'event' => Icons.event_outlined,
      _ => Icons.edit_note_rounded,
    };

String _entityLabel(String type) => switch (type) {
      'source' => 'Income source',
      'revision' => 'Pay revision',
      'override' => 'Holiday or leave',
      'item' => 'Bonus or extra pay',
      'monthly' => 'Monthly record',
      'ledger' => 'Transaction',
      'event' => 'Calendar event',
      _ => type,
    };

SettingsTone _actionTone(String action) => switch (action) {
      'create' || 'add' || 'restore' => SettingsTone.mint,
      'delete' || 'remove' || 'archive' => SettingsTone.peach,
      'pause' => SettingsTone.sky,
      _ => SettingsTone.violet,
    };

String _actionLabel(String action) => action.isEmpty ? action : '${action[0].toUpperCase()}${action.substring(1)}';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  Future<void> _refresh(WidgetRef ref) => ref.read(appRefresherProvider).refresh({RefreshScope.audit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditProvider(null));
    final cal = ref.watch(financialCalendarProvider);
    final today = ref.watch(todayProvider);
    final c = context.colors;

    final entries = async.value;
    if (entries == null) {
      return SettingsPage(title: 'Change history', children: [
        if (async.hasError)
          ErrorState(
            message: 'The change history could not be loaded.',
            onRetry: () => ref.invalidate(auditProvider(null)),
          )
        else
          const LoadingState(label: 'Loading change history'),
      ]);
    }
    if (entries.isEmpty) {
      return SettingsPage(title: 'Change history', onRefresh: () => _refresh(ref), children: const [
        EmptyState(
          icon: Icons.history_rounded,
          title: 'No changes yet',
          message: 'Every time you add, edit or remove income records, a note appears here so you can see '
              'what changed and when.',
        ),
      ]);
    }

    final sorted = [...entries]..sort((a, b) => b.at.compareTo(a.at));
    final groups = <LocalDate, List<AuditEntry>>{};
    for (final e in sorted) {
      groups.putIfAbsent(cal.dateOf(e.at.microsecondsSinceEpoch), () => []).add(e);
    }
    final timeFmt = DateFormat('HH:mm');
    String dayLabel(LocalDate d) {
      final diff = d.daysUntil(today);
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return formatDate(d);
    }

    return SettingsPage(
      title: 'Change history',
      onRefresh: () => _refresh(ref),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, AppSpace.sm, 6, 0),
          child: Text(
            'Showing the latest ${sorted.length} changes. Tap one to see exactly what changed.',
            style: AppType.bodySmall.copyWith(color: c.inkMuted),
          ),
        ),
        for (final (gi, g) in groups.entries.indexed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, AppSpace.xl - 2, 6, AppSpace.sm + 2),
            child: Row(children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(dayLabel(g.key),
                      style: AppType.section.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                ),
              ),
              Pill('${g.value.length} ${g.value.length == 1 ? 'change' : 'changes'}',
                  color: c.accentSoft, textColor: c.accentText),
            ]),
          ),
          EntranceScale(
            delay: Duration(milliseconds: 50 * gi.clamp(0, 6)),
            child: EarnCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final (i, e) in g.value.indexed)
                  _TimelineRow(
                    entry: e,
                    time: timeFmt.format(tz.TZDateTime.from(e.at, cal.location)),
                    first: i == 0,
                    last: i == g.value.length - 1,
                    onTap: () => _showDetails(context, e, cal.location),
                  ),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  void _showDetails(BuildContext context, AuditEntry e, tz.Location location) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              SheetHeader(
                icon: _entityIcon(e.entityType),
                tone: _actionTone(e.action),
                title: e.summary,
                subtitle: '${_entityLabel(e.entityType)} · ${_actionLabel(e.action)} · '
                    '${DateFormat('d MMM yyyy, HH:mm:ss').format(tz.TZDateTime.from(e.at, location))}',
              ),
              const NoteCard(
                message: 'Amounts in these records are stored in minor units — for example 150000 means 1,500.00 '
                    '(paise, cents). Dates are calendar dates.',
              ),
              _JsonBlock(title: 'Before', json: e.beforeJson, emptyText: 'Nothing — this record was created.'),
              _JsonBlock(title: 'After', json: e.afterJson, emptyText: 'Nothing — this record was removed.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.time,
    required this.first,
    required this.last,
    required this.onTap,
  });
  final AuditEntry entry;
  final String time;
  final bool first;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = _actionTone(entry.action);
    final (fg, _) = settingsToneColors(context, tone);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(width: 16),
              SizedBox(
                width: 42,
                child: Column(children: [
                  Container(width: 2, height: 12, color: first ? Colors.transparent : c.line),
                  SettingsIcon(_entityIcon(entry.entityType), tone: tone),
                  Expanded(child: Container(width: 2, color: last ? Colors.transparent : c.line)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.summary,
                        style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(_actionLabel(entry.action),
                          style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
                      Text('· ${_entityLabel(entry.entityType)}', style: AppType.caption.copyWith(color: c.inkMuted)),
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 0),
                child: Text(time, style: AppType.caption.copyWith(color: c.inkMuted)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.title, required this.json, required this.emptyText});
  final String title;
  final String? json;
  final String emptyText;

  static String _pretty(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } on FormatException {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title),
      if (json == null || json!.isEmpty)
        Text(emptyText, style: AppType.body.copyWith(color: c.inkMuted))
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              _pretty(json!),
              style: AppType.bodySmall.copyWith(fontFamily: 'monospace', color: c.ink),
            ),
          ),
        ),
    ]);
  }
}
