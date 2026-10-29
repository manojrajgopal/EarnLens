import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../../shared/widgets/organic.dart';
import '../../refresh/application/app_refresher.dart';
import 'widgets/income_common.dart';

/// Everything about one income source: live earnings, monthly history, rates,
/// expected payments, bonuses, transactions, pauses and audit history.
class SourceDetailScreen extends ConsumerWidget {
  const SourceDetailScreen({super.key, required this.sourceId});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(sourceProvider(sourceId));
    if (source == null) return const MissingSourceScaffold(title: 'Income');
    final s = source;
    final ruleBased = s.kind.accruesContinuously && !s.usesFixedTotal;
    final hasRates = s.kind != IncomeKind.oneTime && !s.usesFixedTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/income/${s.id}/edit'),
          ),
          _SourceMenu(source: s),
        ],
      ),
      body: PageList(
        onRefresh: () => ref.read(appRefresherProvider).refresh({
          RefreshScope.earnings,
          RefreshScope.sourceDetails,
          RefreshScope.audit,
        }),
        children: [
          EntranceScale(child: _HeroCard(source: s)),
          _ThisMonth(source: s),
          _MonthsList(source: s),
          if (hasRates) _RateHistory(source: s, ruleBased: ruleBased),
          _ExpectedPayments(source: s),
          _Items(source: s),
          _Transactions(source: s),
          const SizedBox(height: AppSpace.sm),
          ExpandableCard(
            title: 'Pauses',
            subtitle: 'When this income stopped for a while',
            icon: Icons.pause_circle_outline_rounded,
            color: AppColors.peach,
            children: [_PausesList(source: s)],
          ),
          ExpandableCard(
            title: 'History of changes',
            subtitle: 'Every edit, recorded',
            icon: Icons.history_rounded,
            topGap: AppSpace.md,
            children: [AuditHistoryList(entityId: s.id)],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App-bar menu
// ---------------------------------------------------------------------------

enum _MenuAction { edit, pause, resume, archive, restore, adjustment, delete }

class _SourceMenu extends ConsumerWidget {
  const _SourceMenu({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final archived = s.status == SourceStatus.archived;
    final paused = s.status == SourceStatus.paused;
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (a) => _handle(context, ref, a),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _MenuAction.edit, child: _MenuRow(Icons.edit_outlined, 'Edit details')),
        if (!archived && s.kind.accruesContinuously)
          paused
              ? const PopupMenuItem(value: _MenuAction.resume, child: _MenuRow(Icons.play_arrow_rounded, 'Resume'))
              : const PopupMenuItem(value: _MenuAction.pause, child: _MenuRow(Icons.pause_rounded, 'Pause')),
        const PopupMenuItem(value: _MenuAction.adjustment, child: _MenuRow(Icons.tune_rounded, 'Record adjustment')),
        archived
            ? const PopupMenuItem(value: _MenuAction.restore, child: _MenuRow(Icons.unarchive_outlined, 'Restore'))
            : const PopupMenuItem(value: _MenuAction.archive, child: _MenuRow(Icons.archive_outlined, 'Archive')),
        const PopupMenuItem(value: _MenuAction.delete, child: _MenuRow(Icons.delete_outline_rounded, 'Delete')),
      ],
    );
  }

  Future<void> _handle(BuildContext context, WidgetRef ref, _MenuAction a) async {
    final repo = ref.read(incomeRepositoryProvider);
    final s = source;
    final today = currentDate(ref);
    switch (a) {
      case _MenuAction.edit:
        context.push('/income/${s.id}/edit');
      case _MenuAction.adjustment:
        context.push('/income/${s.id}/entry?type=adjustment');
      case _MenuAction.pause:
        final from = await _pickDate(context, today, 'Pause from', first: s.startDate);
        if (from == null || !context.mounted) return;
        final ok = await confirmDialog(
          context,
          title: 'Pause ${s.name}?',
          message:
              'Nothing is earned from ${formatDate(from)} until you resume. '
              'Earnings before that date stay as they are.',
          confirm: 'Pause',
        );
        if (ok && context.mounted) await runGuarded(context, () => repo.pauseSource(s.id, from), success: 'Paused');
      case _MenuAction.resume:
        final on = await _pickDate(context, today, 'Resume on');
        if (on == null || !context.mounted) return;
        await runGuarded(context, () => repo.resumeSource(s.id, on), success: 'Resumed from ${formatDate(on)}');
      case _MenuAction.archive:
        LocalDate? end = s.endDate;
        if (end == null) {
          end = await _pickDate(context, today, 'Last day of this income', first: s.startDate);
          if (end == null || !context.mounted) return;
        }
        final ok = await confirmDialog(
          context,
          title: 'Archive ${s.name}?',
          message:
              'It stops earning after ${formatDate(end)} and is hidden from your income list. '
              'All payments and history are kept, and you can restore it at any time.',
          confirm: 'Archive',
        );
        if (ok && context.mounted) {
          await runGuarded(context, () => repo.archiveSource(s.id, end!), success: 'Archived');
        }
      case _MenuAction.restore:
        await runGuarded(context, () => repo.restoreSource(s.id), success: 'Restored');
      case _MenuAction.delete:
        final ok = await confirmDialog(
          context,
          title: 'Delete ${s.name}?',
          message: s.isSample
              ? 'This sample income and all its sample records will be removed.'
              : 'This can only be done if nothing has been recorded for it yet. This cannot be undone.',
          confirm: 'Delete',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        try {
          await repo.deleteSourceIfUnused(s.id);
          if (context.mounted) {
            showMessage(context, 'Deleted ${s.name}');
            context.go('/income');
          }
        } on ProtectedHistoryException catch (e) {
          if (!context.mounted) return;
          final archive = await confirmDialog(
            context,
            title: 'Cannot delete',
            message: e.message,
            confirm: 'Archive instead',
          );
          if (archive && context.mounted) await _handle(context, ref, _MenuAction.archive);
        } on AppException catch (e) {
          if (context.mounted) showMessage(context, e.message);
        } on Object {
          if (context.mounted) showMessage(context, 'Could not delete. Your data was not changed.');
        }
    }
  }

  static Future<LocalDate?> _pickDate(BuildContext context, LocalDate initial, String help, {LocalDate? first}) async {
    final f = first ?? LocalDate(1970, 1, 1);
    final init = initial.isBefore(f) ? f : initial;
    final picked = await showDatePicker(
      context: context,
      helpText: help,
      initialDate: init.toDateTime(),
      firstDate: f.toDateTime(),
      lastDate: DateTime(initial.year + 20, 12, 31),
    );
    return picked == null ? null : LocalDate.fromDateTime(picked);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: AppSpace.md),
      Text(label),
    ],
  );
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final snap = ref.watch(snapshotProvider);
    final calc = ref.watch(earningsCalculatorProvider);
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final today = currentDate(ref);
    final live = s.kind.accruesContinuously && s.status != SourceStatus.archived;
    const fg = AppColors.white;
    final muted = fg.withValues(alpha: 0.8);

    final rateLines = <String>[];
    final rules = snap.rules[s.id];
    if (rules != null && s.kind.accruesContinuously) {
      final month = calc.rates.rate(rules, EarningUnit.month, today);
      final day = calc.rates.rate(rules, EarningUnit.day, today);
      if (!month.isZero) rateLines.add('${fmt.fraction(month)} per month');
      if (!day.isZero) rateLines.add('${fmt.fraction(day)} per day');
    } else if (s.kind == IncomeKind.variable) {
      final est = snap.defaultEstimate(s.id, today);
      if (est != null) rateLines.add('Estimate ${fmt.minor(est)} per month');
    }

    final amountStyle = AppType.amountHero.copyWith(
      color: fg,
      fontSize: 42,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget progress(double? value, int expected) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientProgress(value: value, height: 8, onDark: true, semanticsLabel: 'Progress this month'),
                const SizedBox(height: 6),
                AmountText(
                  '${(value * 100).round()}% of ${fmt.minor(expected)} expected this month',
                  style: AppType.caption.copyWith(color: muted),
                ),
              ],
            ),
          );

    return HeroSurface(
      seed: 3,
      semanticLabel: '${s.name} summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Icon(IncomeVisuals.categoryIcon(s.category), color: AppColors.violet, size: AppIconSize.lg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: AppType.title.copyWith(color: fg, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [s.kind.label, s.categoryLabel, if (s.employer != null) s.employer!].join(' · '),
                      style: AppType.bodySmall.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SourceStatusPill(s.status),
              if (s.isSample) Pill('Sample', color: fg.withValues(alpha: 0.22), textColor: fg),
              Pill(
                s.accrualPolicy == AccrualPolicy.workingDay ? 'Working days' : 'Every day',
                color: fg.withValues(alpha: 0.22),
                textColor: fg,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            s.kind.accruesContinuously ? 'Money earned so far this month' : 'Earned this month',
            style: AppType.label.copyWith(color: fg.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: AppSpace.sm),
          if (rules == null)
            const SizedBox.shrink()
          else if (live)
            Consumer(
              builder: (context, ref, _) {
                ref.watch(tickerProvider);
                final now = ref.read(clockProvider).now().microsecondsSinceEpoch;
                final todayNow = ref.read(financialCalendarProvider).dateOf(now);
                final sum = calc.summarizeSource(snap, s, DateRange.month(todayNow.yearMonth), now, todayNow);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AmountText(fmt.fraction(sum.accrued), style: amountStyle),
                    ),
                    progress(
                      sum.expected > 0 ? (sum.accrued.toDouble() / sum.expected).clamp(0.0, 1.0) : null,
                      sum.expected,
                    ),
                  ],
                );
              },
            )
          else
            Builder(
              builder: (context) {
                final sum = calc.summarizeSource(snap, s, DateRange.month(today.yearMonth), currentMicros(ref), today);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sum.hasActual)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AmountText(fmt.minor(sum.actual), style: amountStyle),
                      )
                    else
                      Text('Not recorded yet', style: AppType.amountMedium.copyWith(color: fg)),
                    progress(
                      sum.expected > 0 && sum.hasActual ? (sum.actual / sum.expected).clamp(0.0, 1.0) : null,
                      sum.expected,
                    ),
                  ],
                );
              },
            ),
          if (rateLines.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (i, line) in rateLines.indexed)
                  HeroChip(
                    icon: i == 0 ? Icons.bolt_rounded : Icons.wb_sunny_outlined,
                    iconColor: i == 0 ? AppColors.peachSoft : null,
                    child: AmountText(
                      line,
                      style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
          if (s.status == SourceStatus.paused) ...[
            const SizedBox(height: AppSpace.md),
            HeroChip(
              icon: Icons.pause_circle_outline_rounded,
              child: Text(
                'Paused — nothing is earned until you resume.',
                style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// This month
// ---------------------------------------------------------------------------

/// Small labelled amount on a soft tile (scales down instead of overflowing).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.seed,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Picks one of the four pastel pebble silhouettes.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // A pastel wash of the tile's accent colour on an organic pebble.
    final tint = Color.alphaBlend(color.withValues(alpha: dark ? 0.18 : 0.12), c.card);
    return OrganicTile(
      spec: BlobShapes.pebble(seed),
      color: tint,
      glow: color,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AmountText(value, style: AppType.amountMedium.copyWith(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _ThisMonth extends ConsumerWidget {
  const _ThisMonth({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(snapshotProvider);
    if (!snap.rules.containsKey(source.id)) return const SizedBox.shrink();
    final calc = ref.watch(earningsCalculatorProvider);
    final fmt = moneyFormatterFor(ref, source.currencyCode);
    final (today, now) = liveNow(ref);
    final sum = calc.summarizeSource(snap, source, DateRange.month(today.yearMonth), now, today);
    final c = context.colors;

    return FormSection(
      title: 'This month',
      subtitle: formatMonth(today.yearMonth),
      icon: Icons.calendar_month_rounded,
      topGap: AppSpace.xl,
      trailing: const InfoTip(
        title: 'This month',
        message:
            'Expected is what this month should earn in total. Earned is what you have earned so far. '
            'Received is money paid to you for this month. Outstanding is earned but not yet paid '
            '(earned minus received and deductions).',
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                seed: 0,
                label: 'Expected',
                value: fmt.minor(sum.expected),
                icon: Icons.flag_outlined,
                color: c.accentText,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _StatTile(
                seed: 1,
                label: 'Earned so far',
                value: sum.hasActual ? fmt.minor(sum.actual) : '—',
                icon: Icons.trending_up_rounded,
                color: AppColors.orchid,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                seed: 2,
                label: 'Received',
                value: fmt.minor(sum.received),
                icon: Icons.south_west_rounded,
                color: c.positive,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _StatTile(
                seed: 3,
                label: 'Outstanding',
                value: fmt.minor(sum.outstanding),
                icon: Icons.hourglass_bottom_rounded,
                color: AppColors.peach,
              ),
            ),
          ],
        ),
        if (sum.deductions != 0 || sum.adjustments != 0) ...[
          const SizedBox(height: AppSpace.sm),
          if (sum.deductions != 0) AmountRow(label: 'Deductions', value: fmt.minor(sum.deductions)),
          if (sum.adjustments != 0) AmountRow(label: 'Adjustments', value: fmt.signed(sum.adjustments)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Last 12 months
// ---------------------------------------------------------------------------

class _MonthBadge extends StatelessWidget {
  const _MonthBadge(this.month);
  final YearMonth month;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 46,
      height: 46,
      decoration: ShapeDecoration(
        color: c.accentSoft,
        // Seeded by month so each row gets its own stable pebble.
        shape: BlobBorder(BlobSpec(seed: month.year * 12 + month.month, radius: 19, wobble: 0.5, wave: 1.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatMonthShort(month),
            style: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700, height: 1.1),
          ),
          Text('${month.year}', style: AppType.caption.copyWith(color: c.accentText, fontSize: 10, height: 1.1)),
        ],
      ),
    );
  }
}

class _MonthsList extends ConsumerWidget {
  const _MonthsList({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final snap = ref.watch(snapshotProvider);
    if (!snap.rules.containsKey(s.id)) return const SizedBox.shrink();
    final calc = ref.watch(earningsCalculatorProvider);
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final (today, now) = liveNow(ref);
    final c = context.colors;

    final months = <(YearMonth, SourceSummary)>[];
    for (var i = 0; i < 12; i++) {
      final m = today.yearMonth.addMonths(-i);
      if (m.isBefore(s.startDate.yearMonth)) break;
      months.add((m, calc.summarizeSource(snap, s, DateRange.month(m), now, today)));
    }
    if (months.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          s.kind == IncomeKind.variable ? 'Monthly figures' : 'Last 12 months',
          padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 4, AppSpace.sm),
        ),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          children: [
            CappedList(
              noun: 'months',
              children: [
                for (final (m, sum) in months)
                  ListTile(
                    minVerticalPadding: AppSpace.sm,
                    leading: _MonthBadge(m),
                    title: Text(formatMonth(m), style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: AmountText(
                      sum.expected > 0 ? 'Expected ${fmt.minor(sum.expected, compact: true)}' : 'No expected amount',
                      style: AppType.bodySmall.copyWith(color: c.inkMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.kind == IncomeKind.variable && snap.record(s.id, m)?.finalized == true)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpace.sm),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: c.inkMuted,
                              semanticLabel: 'Finalised',
                            ),
                          ),
                        sum.hasActual
                            ? AmountText(
                                fmt.minor(sum.actual),
                                style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                              )
                            : Text('—', style: AppType.label.copyWith(color: c.inkMuted)),
                        Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                      ],
                    ),
                    onTap: () => s.kind == IncomeKind.variable
                        ? context.push('/income/${s.id}/month/${m.toIso()}')
                        : _showBreakdown(context, fmt, m, sum),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showBreakdown(BuildContext context, MoneyFormatter fmt, YearMonth m, SourceSummary sum) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _MonthBadge(m),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(formatMonth(m), style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AmountRow(
                label: 'Expected',
                value: fmt.minor(sum.expected),
                caption: 'What the month should earn in total',
              ),
              AmountRow(
                label: 'Earned',
                value: sum.hasActual ? fmt.minor(sum.actual) : '—',
                caption: 'Including adjustments',
              ),
              if (sum.adjustments != 0) AmountRow(label: 'Adjustments', value: fmt.signed(sum.adjustments)),
              AmountRow(label: 'Received', value: fmt.minor(sum.received)),
              if (sum.deductions != 0) AmountRow(label: 'Deductions', value: fmt.minor(sum.deductions)),
              const Divider(),
              AmountRow(
                label: 'Outstanding',
                value: fmt.minor(sum.outstanding),
                emphasis: true,
                caption: 'Earned but not yet paid',
              ),
              if (sum.expected != 0 && sum.hasActual)
                AmountRow(label: 'Difference from expected', value: fmt.signed(sum.variance)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rate history
// ---------------------------------------------------------------------------

class _RateHistory extends ConsumerWidget {
  const _RateHistory({required this.source, required this.ruleBased});
  final IncomeSource source;
  final bool ruleBased;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final revisions = ref.watch(revisionsProvider(s.id));
    final c = context.colors;
    final today = currentDate(ref);
    final variable = s.kind == IncomeKind.variable;
    final addLabel = switch (s.kind) {
      IncomeKind.salary => 'Add salary revision',
      IncomeKind.variable => 'Update estimate',
      _ => 'Add rate change',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          variable ? 'Estimate history' : 'Rate history',
          action: addLabel,
          onAction: () => context.push('/income/${s.id}/revision'),
          padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
        ),
        revisions.when(
          loading: () => const LoadingState(label: 'Loading rate history'),
          error: (e, _) => const InfoBanner('Rate history could not be loaded.', tone: BannerTone.warning),
          data: (list) {
            if (list.isEmpty) {
              return const InfoBanner(
                'No rate recorded yet. Add one so EarnLens can work out your earnings.',
                tone: BannerTone.warning,
              );
            }
            // Newest first; the first one already in force is the current rate.
            final current = list.where((r) => !r.effectiveFrom.isAfter(today)).firstOrNull;
            return SectionCard(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md),
              children: [
                for (final (i, r) in list.indexed)
                  TimelineRow(
                    first: i == 0,
                    last: i == list.length - 1,
                    active: r == current,
                    child: InkWell(
                      customBorder: BlobBorder(BlobShapes.cloud(i + 7, radius: AppRadius.sm, wobble: 0.3)),
                      onTap: () => context.push('/income/${s.id}/revision?rev=${r.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: AmountText(
                                      '${fmt.minor(r.amountMinor)} ${r.period.label}',
                                      style: AppType.section.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'From ${formatDate(r.effectiveFrom)}',
                                    style: AppType.bodySmall.copyWith(color: c.inkMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (r == current) Pill('Current', color: c.accentSoft, textColor: c.accentText),
                                      Pill(r.changeType.label),
                                      if (r.percentBps != null)
                                        Pill(
                                          '${r.percentBps! >= 0 ? '+' : ''}${formatBps(r.percentBps!)}%',
                                          color: r.percentBps! >= 0 ? c.positiveSoft : c.errorSoft,
                                          textColor: r.percentBps! >= 0 ? c.positive : c.error,
                                        ),
                                    ],
                                  ),
                                  if (r.note != null && r.note!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(r.note!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Rate actions',
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  context.push('/income/${s.id}/revision?rev=${r.id}');
                                } else {
                                  final ok = await confirmDialog(
                                    context,
                                    title: 'Remove this rate?',
                                    message:
                                        'Earnings from ${formatDate(r.effectiveFrom)} will use the previous rate instead. '
                                        'The change is recorded in history.',
                                    confirm: 'Remove',
                                    destructive: true,
                                  );
                                  if (ok && context.mounted) {
                                    await runGuarded(
                                      context,
                                      () => ref.read(incomeRepositoryProvider).deleteRevision(r.id),
                                      success: 'Rate removed',
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Correct this rate')),
                                if (list.length > 1) const PopupMenuItem(value: 'delete', child: Text('Remove')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, AppSpace.sm, AppSpace.md, 0),
                  child: Text(
                    'Tap a rate to correct a mistake. Use "$addLabel" when your pay actually changed.',
                    style: AppType.caption.copyWith(color: c.inkMuted),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expected payments
// ---------------------------------------------------------------------------

class _ExpectedPayments extends ConsumerWidget {
  const _ExpectedPayments({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final mainCurrency = ref.watch(currencyProvider).code;
    final payments = ref.watch(expectedPaymentsProvider).where((p) => p.sourceId == s.id).toList();
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final c = context.colors;

    Widget body;
    if (s.currencyCode != mainCurrency) {
      body = InfoBanner(
        'Expected payments are tracked for income in your main currency ($mainCurrency). '
        'You can still record payments for this income below.',
      );
    } else if (payments.isEmpty) {
      body = const InfoBanner('No payments expected in the last few months or the next three.');
    } else {
      final list = payments.reversed.toList();
      body = SectionCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        children: [
          CappedList(
            noun: 'payments',
            children: [
              for (final (i, p) in list.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.md,
                      AppSpace.lg,
                      p.outstandingMinor > 0 ? AppSpace.xs : AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconBadge(
                              p.status == PaymentStatus.received ? Icons.check_rounded : Icons.event_note_rounded,
                              color: p.status == PaymentStatus.received ? c.positive : c.accentText,
                              size: 36,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Due ${formatDate(p.dueDate)} · for ${formatMonth(p.periodMonth)}',
                                    style: AppType.bodySmall.copyWith(color: c.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PaymentStatusPill(p.status),
                                const SizedBox(height: 6),
                                AmountText(
                                  fmt.minor(p.expectedMinor),
                                  style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (p.receivedMinor > 0 || p.outstandingMinor > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 36 + AppSpace.md, top: AppSpace.xs),
                            child: Row(
                              children: [
                                Expanded(
                                  child: p.receivedMinor > 0
                                      ? AmountText(
                                          'Received ${fmt.minor(p.receivedMinor)}',
                                          style: AppType.caption.copyWith(color: c.inkMuted),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                if (p.outstandingMinor > 0)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: c.accentText,
                                      visualDensity: VisualDensity.compact,
                                      textStyle: AppType.label.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    onPressed: () => context.push(
                                      '/income/${s.id}/entry?type=received&period=${p.periodMonth.toIso()}'
                                      '${p.itemId != null ? '&item=${p.itemId}' : ''}',
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: AppIconSize.sm),
                                    label: const Text('Mark received'),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.md),
          child: Row(
            children: [
              const Expanded(child: SectionHeader('Expected payments')),
              const InfoTip(
                title: 'Expected payments',
                message:
                    'When each month\'s pay should reach you, based on your payment rule. '
                    'Marking a payment as received never changes what you earned — it only records the cash.',
              ),
            ],
          ),
        ),
        body,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bonuses & benefits
// ---------------------------------------------------------------------------

class _Items extends ConsumerWidget {
  const _Items({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final snap = ref.watch(snapshotProvider);
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final items = snap.itemsFor(s.id).toList()
      ..sort((a, b) {
        final da = a.planningDate, db = b.planningDate;
        if (da == null || db == null) return da == null ? 1 : -1;
        return db.compareTo(da);
      });
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          s.kind == IncomeKind.oneTime ? 'Payment details' : 'Bonuses & benefits',
          action: 'Add',
          onAction: () => context.push('/income/${s.id}/item'),
          padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
        ),
        if (items.isEmpty)
          const InfoBanner('Add bonuses, allowances, benefits or reimbursements linked to this income.')
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            children: [
              for (final i in items)
                ListTile(
                  minVerticalPadding: AppSpace.md,
                  leading: IconBadge(
                    i.nonCash ? Icons.card_giftcard_rounded : Icons.redeem_rounded,
                    color: i.isEarned ? c.positive : AppColors.orchid,
                  ),
                  title: Text(i.title, style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      i.type.label,
                      if (i.planningDate != null) formatDate(i.planningDate!),
                      if (i.recurrence != Recurrence.none) i.recurrence.label,
                      if (i.nonCash) 'Non-cash',
                    ].join(' · '),
                    style: AppType.bodySmall.copyWith(color: c.inkMuted),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AmountText(
                        fmt.minor(i.actualMinor ?? i.expectedMinor ?? 0),
                        style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.isEarned ? 'Earned' : 'Expected',
                        style: AppType.caption.copyWith(color: i.isEarned ? c.positive : c.inkMuted),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/income/${s.id}/item?item=${i.id}'),
                ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------

class _Transactions extends ConsumerStatefulWidget {
  const _Transactions({required this.source});
  final IncomeSource source;

  @override
  ConsumerState<_Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends ConsumerState<_Transactions> {
  static const _pageSize = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final snap = ref.watch(snapshotProvider);
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final c = context.colors;
    final entries = snap.ledger.where((e) => e.sourceId == s.id).toList()
      ..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
      });
    final visible = _showAll ? entries : entries.take(_pageSize).toList();
    final defaultType = s.kind == IncomeKind.variable ? LedgerType.earned : LedgerType.received;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Recent transactions',
          action: 'Add',
          onAction: () => context.push('/income/${s.id}/entry?type=${defaultType.name}'),
          padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
        ),
        if (entries.isEmpty)
          const InfoBanner('Payments, deductions and adjustments you record will appear here.')
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            children: [
              for (final e in visible)
                InkWell(
                  onTap: () => context.push('/income/${s.id}/entry?entry=${e.id}'),
                  onLongPress: () => _actions(context, e),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.xs, AppSpace.sm),
                    child: Row(
                      children: [
                        IconBadge(_icon(e.type), color: e.status.counts ? _tone(context, e.type) : c.inkMuted),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.type.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: e.status.counts
                                          ? AppType.label.copyWith(fontWeight: FontWeight.w600)
                                          : AppType.label.copyWith(
                                              color: c.inkMuted,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  AmountText(
                                    _signedAmount(fmt, e),
                                    style: AppType.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: e.status.counts ? null : c.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatDate(e.date)} · for ${formatMonth(e.periodMonth)}'
                                '${e.status == LedgerStatus.completed ? '' : ' · ${e.status.label}'}',
                                style: AppType.bodySmall.copyWith(color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Entry actions',
                          icon: Icon(Icons.more_vert_rounded, color: c.inkMuted),
                          onPressed: () => _actions(context, e),
                        ),
                      ],
                    ),
                  ),
                ),
              if (entries.length > _pageSize)
                Center(
                  child: LinkAction(
                    label: _showAll ? 'Show fewer' : 'Show all ${entries.length}',
                    icon: _showAll ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    onTap: () => setState(() => _showAll = !_showAll),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _signedAmount(MoneyFormatter fmt, LedgerEntry e) => switch (e.type) {
    LedgerType.adjustment => fmt.signed(e.amountMinor),
    LedgerType.deduction || LedgerType.reversal => '−${fmt.minor(e.amountMinor)}',
    _ => fmt.minor(e.amountMinor),
  };

  static IconData _icon(LedgerType t) => switch (t) {
    LedgerType.received => Icons.south_west_rounded,
    LedgerType.earned => Icons.add_chart_rounded,
    LedgerType.adjustment => Icons.tune_rounded,
    LedgerType.deduction => Icons.remove_circle_outline_rounded,
    LedgerType.reversal => Icons.undo_rounded,
  };

  static Color _tone(BuildContext context, LedgerType t) {
    final c = context.colors;
    return switch (t) {
      LedgerType.received => c.positive,
      LedgerType.earned => c.accentText,
      LedgerType.adjustment => AppColors.sky,
      LedgerType.deduction => AppColors.peach,
      LedgerType.reversal => c.error,
    };
  }

  Future<void> _actions(BuildContext context, LedgerEntry e) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit entry'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            if (e.status == LedgerStatus.pending)
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('Mark completed'),
                subtitle: const Text('Counts it in your totals'),
                onTap: () => Navigator.pop(ctx, 'complete'),
              ),
            if (e.status == LedgerStatus.completed || e.status == LedgerStatus.pending) ...[
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel entry'),
                subtitle: const Text('For entries recorded by mistake'),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: const Text('Mark reversed'),
                subtitle: const Text('For payments that bounced or were taken back'),
                onTap: () => Navigator.pop(ctx, 'reverse'),
              ),
            ],
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final records = ref.read(recordsRepositoryProvider);
    switch (choice) {
      case 'edit':
        context.push('/income/${widget.source.id}/entry?entry=${e.id}');
      case 'complete':
        await runGuarded(
          context,
          () => records.setLedgerStatus(e.id, LedgerStatus.completed),
          success: 'Marked completed',
        );
      case 'cancel':
      case 'reverse':
        final cancel = choice == 'cancel';
        final ok = await confirmDialog(
          context,
          title: cancel ? 'Cancel this entry?' : 'Mark as reversed?',
          message: 'It will no longer count in your totals. It stays in your history and the change is recorded.',
          confirm: cancel ? 'Cancel entry' : 'Mark reversed',
          destructive: true,
        );
        if (ok && context.mounted) {
          await runGuarded(
            context,
            () => records.setLedgerStatus(e.id, cancel ? LedgerStatus.cancelled : LedgerStatus.reversed),
            success: cancel ? 'Entry cancelled' : 'Entry marked reversed',
          );
        }
    }
  }
}

// ---------------------------------------------------------------------------
// Pauses
// ---------------------------------------------------------------------------

class _PausesList extends ConsumerWidget {
  const _PausesList({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ref
        .watch(pausesProvider(source.id))
        .when(
          loading: () => const LoadingState(label: 'Loading pauses'),
          error: (e, _) => Text('Pauses could not be loaded.', style: AppType.bodySmall.copyWith(color: c.error)),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Text(
                    'Never paused. Use Pause in the menu when this income stops for a while.',
                    style: AppType.bodySmall.copyWith(color: c.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, p) in list.indexed)
                      TimelineRow(
                        first: i == 0,
                        last: i == list.length - 1,
                        icon: p.endExclusive == null ? Icons.pause_rounded : Icons.check_rounded,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.endExclusive == null
                                    ? 'Paused since ${formatDate(p.start)}'
                                    : '${formatDate(p.start)} – ${formatDate(p.endExclusive!.addDays(-1))}',
                                style: AppType.label.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.endExclusive == null ? 'Ongoing — nothing is being earned' : 'Nothing was earned',
                                style: AppType.caption.copyWith(color: c.inkMuted),
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
