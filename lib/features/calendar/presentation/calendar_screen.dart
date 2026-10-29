import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../analytics/presentation/analytics_widgets.dart';
import '../../history/presentation/month_picker.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/calendar_data.dart';
import 'event_form_sheet.dart';

Color toneColor(BuildContext context, CalTone t) {
  final c = context.colors;
  return switch (t) {
    CalTone.upcoming => c.accent,
    CalTone.overdue => c.overdue,
    CalTone.partial => c.warning,
    CalTone.received => c.positive,
    CalTone.compensation => AppColors.series[3],
    CalTone.transaction => c.ink,
    CalTone.work => AppColors.series[2],
    CalTone.checkIn => AppColors.series[4],
    CalTone.userEvent => AppColors.series[5],
  };
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late YearMonth _month;
  late LocalDate _selected;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _month = today.yearMonth;
    _selected = today;
  }

  void _goTo(YearMonth m) => setState(() {
        _month = m;
        final day = _selected.day.clamp(1, m.lengthInDays);
        _selected = LocalDate(m.year, m.month, day);
      });

  void _today() {
    final today = ref.read(todayProvider);
    setState(() {
      _month = today.yearMonth;
      _selected = today;
    });
  }

  Future<void> _pickMonth() async {
    final m = await showMonthPicker(context, initial: _month);
    if (m != null && mounted) _goTo(m);
  }

  Future<void> _refresh() =>
      ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.calendar});

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(calendarMonthProvider(_month));
    final today = ref.watch(todayProvider);
    final showToday = _month != today.yearMonth || _selected != today;

    final nav = Row(children: [
      Expanded(
        child: MonthNavPill(
          label: formatMonth(_month),
          semanticLabel: 'Showing ${formatMonth(_month)}. Choose another month',
          onPrevious: () => _goTo(_month.previous),
          onNext: () => _goTo(_month.next),
          onPick: _pickMonth,
        ),
      ),
      if (showToday) ...[
        const SizedBox(width: AppSpace.sm),
        _TodayButton(onTap: _today),
      ],
    ]);

    final grid = EarnCard(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -300) _goTo(_month.next);
          if (v > 300) _goTo(_month.previous);
        },
        child: _MonthGrid(
          data: data,
          today: today,
          selected: _selected,
          onSelect: (d) => setState(() => _selected = d),
        ),
      ),
    );

    final day = _DayPanel(
      date: _selected,
      entries: data.on(_selected),
      work: data.workShade[_selected] ?? const [],
    );

    final header = TabPageHeader(
      title: 'Calendar',
      subtitle: 'Paydays, bonuses and your own reminders.',
      actions: [
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Add event',
          filled: true,
          onPressed: () => showEventForm(context, date: _selected),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, cons) {
        if (cons.maxWidth >= wideBreakpoint) {
          return AnalyticsBody(safeTop: true, onRefresh: _refresh, children: [
            header,
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  nav,
                  const SizedBox(height: AppSpace.lg),
                  EntranceScale(child: grid),
                  const SizedBox(height: AppSpace.lg),
                  const _Legend(),
                ]),
              ),
              const SizedBox(width: AppSpace.xl),
              Expanded(flex: 2, child: day),
            ]),
          ]);
        }
        return AnalyticsBody(safeTop: true, onRefresh: _refresh, children: [
          header,
          nav,
          const SizedBox(height: AppSpace.lg),
          EntranceScale(child: grid),
          const SizedBox(height: AppSpace.md),
          const _Legend(),
          day,
        ]);
      }),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Go to today',
      excludeSemantics: true,
      child: Material(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Center(
                widthFactor: 1,
                child: Text('Today', style: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.data, required this.today, required this.selected, required this.onSelect});

  final CalendarMonthData data;
  final LocalDate today;
  final LocalDate selected;
  final ValueChanged<LocalDate> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final month = data.month;
    final offset = month.firstDay.weekday - 1; // Monday first
    final cells = offset + month.lengthInDays;
    final rows = (cells + 6) ~/ 7;

    return Column(children: [
      ExcludeSemantics(
        child: Row(children: [
          for (final w in weekdayShort)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    w.substring(0, w.length < 2 ? w.length : 2),
                    style: AppType.caption.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ]),
      ),
      for (var r = 0; r < rows; r++)
        Row(children: [
          for (var col = 0; col < 7; col++)
            Expanded(
              child: Builder(builder: (context) {
                final dayNum = r * 7 + col - offset + 1;
                if (dayNum < 1 || dayNum > month.lengthInDays) return const SizedBox(height: 56);
                final d = LocalDate(month.year, month.month, dayNum);
                final work = data.workShade[d] ?? const [];
                // Connect shading across neighbouring days within the week row.
                final prevWork = col > 0 && dayNum > 1 && (data.workShade[d.addDays(-1)]?.isNotEmpty ?? false);
                final nextWork =
                    col < 6 && dayNum < month.lengthInDays && (data.workShade[d.addDays(1)]?.isNotEmpty ?? false);
                return _DayCell(
                  date: d,
                  entries: data.on(d),
                  workColor: work.isEmpty ? null : IncomeVisuals.color(work.first),
                  joinLeft: prevWork,
                  joinRight: nextWork,
                  isToday: d == today,
                  isSelected: d == selected,
                  onTap: () => onSelect(d),
                );
              }),
            ),
        ]),
    ]);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entries,
    required this.workColor,
    required this.joinLeft,
    required this.joinRight,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final LocalDate date;
  final List<CalEntry> entries;
  final Color? workColor;
  final bool joinLeft;
  final bool joinRight;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tones = <CalTone>[];
    for (final e in entries) {
      if (!tones.contains(e.tone)) tones.add(e.tone);
    }
    final shown = tones.take(3).toList();
    final more = tones.length - shown.length;

    final label = StringBuffer(DateFormat('EEEE d MMMM yyyy').format(date.toDateTime()));
    if (isToday) label.write(', today');
    if (workColor != null) label.write(', temporary work day');
    if (entries.isEmpty) {
      label.write(', nothing scheduled');
    } else {
      label.write(', ${entries.length} item${entries.length == 1 ? '' : 's'}: ${tones.map((t) => t.label).join(', ')}');
    }

    const radius = Radius.circular(AppRadius.pill);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label.toString(),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 56,
            child: Stack(alignment: Alignment.topCenter, children: [
              if (workColor != null)
                Positioned(
                  top: 4,
                  left: joinLeft ? 0 : 3,
                  right: joinRight ? 0 : 3,
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: workColor!.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.horizontal(
                        left: joinLeft ? Radius.zero : radius,
                        right: joinRight ? Radius.zero : radius,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations ? Duration.zero : AppDurations.fast,
                  width: 40,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.orb : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: isToday && !isSelected ? Border.all(color: c.accentText, width: 1.8) : null,
                    boxShadow: isSelected ? AppShadows.glow : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: AppType.label.copyWith(
                      color: isSelected ? AppColors.white : (isToday ? c.accentText : c.ink),
                      fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final t in shown)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: LegendDot(toneColor(context, t), size: 6),
                    ),
                  if (more > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 1),
                      child: Text('+', style: AppType.caption.copyWith(fontSize: 9, height: 0.8, color: c.inkMuted)),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

IconData toneIcon(CalTone t) => switch (t) {
      CalTone.upcoming => Icons.schedule_rounded,
      CalTone.overdue => Icons.error_outline_rounded,
      CalTone.partial => Icons.timelapse_rounded,
      CalTone.received => Icons.check_circle_outline_rounded,
      CalTone.compensation => Icons.redeem_outlined,
      CalTone.transaction => Icons.swap_horiz_rounded,
      CalTone.work => Icons.work_outline_rounded,
      CalTone.checkIn => Icons.fact_check_outlined,
      CalTone.userEvent => Icons.event_note_outlined,
    };

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: 'Calendar legend',
      child: EarnCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.md,
        elevated: false,
        tint: c.cardHigh,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            childrenPadding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
            expandedAlignment: Alignment.centerLeft,
            iconColor: c.accentText,
            collapsedIconColor: c.inkMuted,
            leading: Icon(Icons.palette_outlined, size: AppIconSize.sm, color: c.accentText),
            title: Text('What the dots mean', style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
            children: [
              Wrap(spacing: 16, runSpacing: 10, children: [
                for (final t in CalTone.values)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    t == CalTone.work
                        ? Container(
                            width: 18,
                            height: 10,
                            decoration: BoxDecoration(
                              color: toneColor(context, t).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          )
                        : LegendDot(toneColor(context, t)),
                    const SizedBox(width: 6),
                    Text(
                      t == CalTone.work ? 'Temporary work (shaded days)' : t.label,
                      style: AppType.caption.copyWith(color: c.ink),
                    ),
                  ]),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends ConsumerWidget {
  const _DayPanel({required this.date, required this.entries, required this.work});
  final LocalDate date;
  final List<CalEntry> entries;
  final List<IncomeSource> work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final title = DateFormat('EEEE, d MMMM').format(date.toDateTime());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        title,
        action: 'Add event',
        onAction: () => showEventForm(context, date: date),
        padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
      ),
      if (entries.isEmpty)
        EarnCard(
          child: Row(children: [
            IconBadge(
              work.isEmpty ? Icons.event_available_outlined : Icons.work_outline_rounded,
              color: c.accentText,
              background: c.accentSoft,
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nothing on this day', style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  work.isEmpty
                      ? 'Payments, bonuses and your own reminders will appear here.'
                      : 'A temporary work day. Payments and reminders will appear here.',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
              ]),
            ),
          ]),
        )
      else
        for (final (i, e) in entries.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.md),
          EntranceScale(
            delay: Duration(milliseconds: 50 * i.clamp(0, 6)),
            child: _EntryTile(entry: e, date: date),
          ),
        ],
    ]);
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.date});
  final CalEntry entry;
  final LocalDate date;

  void _open(BuildContext context) {
    final e = entry;
    if (e.event != null) {
      showEventForm(context, event: e.event, date: date);
    } else if (e.reconcile && e.sourceId != null) {
      context.push('/income/${e.sourceId}/month/${e.period!.toIso()}');
    } else if (e.itemId != null && e.sourceId != null) {
      context.push('/income/${e.sourceId}/item?item=${e.itemId}');
    } else if (e.sourceId != null) {
      context.push('/income/${e.sourceId}');
    }
  }

  bool get _navigable => entry.event != null || entry.sourceId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final base = ref.watch(moneyFormatterProvider);
    final e = entry;
    final neutral = e.tone == CalTone.transaction;
    final tone = toneColor(context, e.tone);
    final badgeColor = neutral ? c.accentText : tone;
    String? amount;
    if (e.amountMinor != null) {
      final f = e.currencyCode == null || e.currencyCode == base.currency.code
          ? base
          : MoneyFormatter(base.locale, Currency.byCode(e.currencyCode!));
      amount = f.minor(e.amountMinor!);
    }

    return EarnCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.md + 4,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: _navigable ? () => _open(context) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.md),
              child: Row(children: [
                Semantics(
                  label: e.tone.label,
                  child: IconBadge(toneIcon(e.tone), color: badgeColor, background: badgeColor.withValues(alpha: 0.14)),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(e.subtitle, style: AppType.caption.copyWith(color: c.inkMuted)),
                    const SizedBox(height: 6),
                    Wrap(spacing: AppSpace.sm, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      ExcludeSemantics(
                        child: Pill(e.tone.label, color: badgeColor.withValues(alpha: 0.14), textColor: badgeColor),
                      ),
                      if (amount != null) AmountText(amount, style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                ),
                if (_navigable) Icon(Icons.chevron_right_rounded, color: c.inkMuted),
              ]),
            ),
          ),
        ),
        if (e.canMarkReceived) ...[
          Divider(height: 1, indent: AppSpace.lg, endIndent: AppSpace.lg, color: c.line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: () => context.push(
                  '/income/${e.sourceId}/entry?type=received&period=${e.period!.toIso()}'
                  '${e.itemId != null ? '&item=${e.itemId}' : ''}',
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Mark received'),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
