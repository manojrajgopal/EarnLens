import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../bootstrap/dependency_injection.dart';
import '../../../../core/date_time/local_date.dart';
import '../../../../core/formatting/money_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../domain/calculation/payment_schedule.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/income_source.dart';
import '../../../../domain/money/currency.dart';
import '../../../../shared/widgets/components.dart';
import '../../../../shared/widgets/earnlens_refresh_indicator.dart';
import '../../../../shared/layout/page_layout.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/income_visuals.dart';
import '../../../../shared/widgets/organic.dart';

/// Shared building blocks for the income management screens.

const double kPageMaxWidth = 720;
const vGap = SizedBox(height: AppSpace.lg);
const vGapSmall = SizedBox(height: AppSpace.sm);

/// Scrollable page body: centred and width-limited on wide screens, with
/// bottom clearance for the floating navigation bar (see [AppInsets]).
/// Pass [onRefresh] on screens that show refreshable data; leave it null on
/// forms so pulling never interferes with unsaved input.
class PageList extends StatelessWidget {
  const PageList({
    super.key,
    required this.children,
    this.onRefresh,
    this.extraBottom = 0,
    this.top = AppSpace.sm,
    this.refreshEdgeOffset = 0,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double extraBottom;

  /// Top padding (tab roots without an app bar pass the status-bar inset).
  final double top;

  /// Where the refresh indicator starts (status-bar inset on screens
  /// without an app bar).
  final double refreshEdgeOffset;

  @override
  Widget build(BuildContext context) {
    if (onRefresh != null && refreshEdgeOffset > 0) {
      return EarnLensRefreshIndicator(
        edgeOffset: refreshEdgeOffset,
        onRefresh: onRefresh!,
        child: EarnPageList(maxWidth: kPageMaxWidth, extraBottom: extraBottom, top: top, children: children),
      );
    }
    return EarnPageList(
      maxWidth: kPageMaxWidth,
      onRefresh: onRefresh,
      extraBottom: extraBottom,
      top: top,
      children: children,
    );
  }
}

/// Today in the user's financial timezone, read fresh from the clock.
LocalDate currentDate(WidgetRef ref) => ref.read(financialCalendarProvider).today(ref.read(clockProvider).now());

int currentMicros(WidgetRef ref) => ref.read(clockProvider).now().microsecondsSinceEpoch;

/// Live "now" for earned-so-far figures: watching it rebuilds the caller every
/// second, so amounts keep accruing on screen without a refresh.
(LocalDate, int) liveNow(WidgetRef ref) {
  final now = ref.watch(liveNowProvider);
  return (ref.read(financialCalendarProvider).today(now), now.microsecondsSinceEpoch);
}

/// Formatter for a specific currency (a source's own currency).
MoneyFormatter moneyFormatterFor(WidgetRef ref, String currencyCode) {
  final locale = ref.watch(profileStreamProvider).value?.locale ?? 'en_IN';
  return MoneyFormatter(locale, Currency.byCode(currencyCode));
}

final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm');
String formatDateTime(DateTime t) => _dateTimeFormat.format(t.toLocal());

String weekdayName(LocalDate d) => weekdayShort[d.weekday - 1];

/// Basis points as a human percentage, e.g. 1250 → "12.50".
String formatBps(int bps) {
  final neg = bps < 0;
  final abs = bps.abs();
  return '${neg ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

String payOffsetLabel(int months) => switch (months) {
  0 => 'Paid in the same month',
  1 => 'Paid the following month',
  _ => 'Paid $months months later',
};

/// Soft explanatory panel used for plain-language guidance.
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.message, {super.key, this.icon = Icons.lightbulb_outline_rounded, this.tone = BannerTone.info});

  final String message;
  final IconData icon;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      BannerTone.info => (c.accentSoft, c.accentText),
      BannerTone.warning => (c.warningSoft, c.warning),
      BannerTone.positive => (c.positiveSoft, c.positive),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg + 2, AppSpace.lg, AppSpace.lg + 2, AppSpace.lg),
      decoration: ShapeDecoration(color: bg, shape: BlobBorder(BlobShapes.cloud(11 + tone.index, radius: 22, wobble: 0.4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(message, style: AppType.bodySmall.copyWith(color: c.ink)),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { info, warning, positive }

class SourceStatusPill extends StatelessWidget {
  const SourceStatusPill(this.status, {super.key});
  final SourceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      SourceStatus.active => (c.positiveSoft, c.positive),
      SourceStatus.paused => (c.warningSoft, c.warning),
      SourceStatus.ended => (c.cardHigh, c.inkMuted),
      SourceStatus.archived => (c.cardHigh, c.inkMuted),
    };
    return Pill(status.label, color: bg, textColor: fg);
  }
}

class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill(this.status, {super.key});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      PaymentStatus.received => (c.positiveSoft, c.positive),
      PaymentStatus.partiallyReceived => (c.warningSoft, c.warning),
      PaymentStatus.overdue => (c.errorSoft, c.overdue),
      PaymentStatus.dueToday => (c.accentSoft, c.accentText),
      PaymentStatus.upcoming => (c.cardHigh, c.inkMuted),
    };
    return Pill(status.label, color: bg, textColor: fg);
  }
}

class LedgerStatusPill extends StatelessWidget {
  const LedgerStatusPill(this.status, {super.key});
  final LedgerStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      LedgerStatus.completed => (c.positiveSoft, c.positive),
      LedgerStatus.pending => (c.warningSoft, c.warning),
      LedgerStatus.cancelled => (c.cardHigh, c.inkMuted),
      LedgerStatus.reversed => (c.errorSoft, c.error),
    };
    return Pill(status.label, color: bg, textColor: fg);
  }
}

/// Label on the left, amount on the right.
class AmountRow extends StatelessWidget {
  const AmountRow({super.key, required this.label, required this.value, this.emphasis = false, this.caption});

  final String label;
  final String value;
  final bool emphasis;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: emphasis ? AppType.label.copyWith(fontWeight: FontWeight.w700) : AppType.label),
              if (caption != null) Text(caption!, style: AppType.caption.copyWith(color: context.colors.inkMuted)),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        AmountText(value, style: emphasis ? AppType.section : AppType.label),
      ],
    ),
  );
}

/// Switch with a title and explanation, sized for 48dp touch targets.
class ToggleTile extends StatelessWidget {
  const ToggleTile({super.key, required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.cardHigh,
    shape: BlobBorder(BlobShapes.cloud(title.length, radius: 22, wobble: 0.35)),
    clipBehavior: Clip.antiAlias,
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 2),
    ),
  );
}

/// Simple month/year picker dialog.
Future<YearMonth?> pickMonth(BuildContext context, {required YearMonth initial, String title = 'Choose a month'}) =>
    showDialog<YearMonth>(
      context: context,
      builder: (_) => _MonthPickerDialog(initial: initial, title: title),
    );

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial, required this.title});
  final YearMonth initial;
  final String title;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() => _year--),
                ),
                Expanded(
                  child: Text('$_year', textAlign: TextAlign.center, style: AppType.section),
                ),
                IconButton(
                  tooltip: 'Next year',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.1,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (var m = 1; m <= 12; m++)
                  Builder(
                    builder: (context) {
                      final ym = YearMonth(_year, m);
                      final selected = ym == widget.initial;
                      return Semantics(
                        selected: selected,
                        button: true,
                        label: formatMonth(ym),
                        excludeSemantics: true,
                        child: Material(
                          color: selected ? AppColors.violet : c.cardHigh,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () => Navigator.pop(context, ym),
                            child: Center(
                              child: Text(
                                formatMonthShort(ym),
                                style: AppType.label.copyWith(
                                  color: selected ? AppColors.white : c.ink,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

/// Tappable field showing a month and opening [pickMonth].
class MonthPickerField extends StatelessWidget {
  const MonthPickerField({super.key, required this.label, required this.value, required this.onChanged, this.helper});

  final String label;
  final YearMonth value;
  final ValueChanged<YearMonth> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) => InkWell(
    // Matches the organic outline of the themed input border.
    customBorder: const BlobInputBorder(),
    onTap: () async {
      final m = await pickMonth(context, initial: value, title: label);
      if (m != null) onChanged(m);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        suffixIcon: const Icon(Icons.calendar_view_month_rounded, size: 20),
      ),
      child: Text(formatMonth(value), style: AppType.body),
    ),
  );
}

/// Audit history for one entity (source, record...), newest first.
class AuditHistoryList extends ConsumerWidget {
  const AuditHistoryList({super.key, required this.entityId, this.limit = 30});
  final String entityId;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final audit = ref.watch(auditProvider(entityId));
    return audit.when(
      loading: () => const LoadingState(label: 'Loading history'),
      error: (e, _) => Text('History could not be loaded.', style: AppType.bodySmall.copyWith(color: c.error)),
      data: (entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text('No changes recorded yet.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
          );
        }
        return Column(
          children: [
            for (final (i, e) in entries.take(limit).indexed)
              TimelineRow(
                first: i == 0,
                last: i == entries.take(limit).length - 1,
                icon: _auditIcon(e.action),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.summary, style: AppType.label),
                      const SizedBox(height: 2),
                      Text(formatDateTime(e.at), style: AppType.caption.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static IconData _auditIcon(String action) => switch (action) {
    'create' => Icons.add_circle_outline_rounded,
    'update' => Icons.edit_outlined,
    'delete' => Icons.delete_outline_rounded,
    'archive' => Icons.archive_outlined,
    'restore' => Icons.unarchive_outlined,
    'pause' => Icons.pause_circle_outline_rounded,
    'resume' => Icons.play_circle_outline_rounded,
    'finalize' => Icons.lock_outline_rounded,
    'reopen' => Icons.lock_open_rounded,
    'cancel' => Icons.cancel_outlined,
    _ => Icons.history_rounded,
  };
}

/// A white card holding a titled group of rows.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => EarnCard(
    padding: padding ?? const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

/// Message shown when a source id does not resolve (deleted or still loading).
class MissingSourceScaffold extends ConsumerWidget {
  const MissingSourceScaffold({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(snapshotStreamProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: snap.isLoading && !snap.hasValue
          ? const LoadingState()
          : snap.hasError && !snap.hasValue
          ? ErrorState(message: 'Your data could not be loaded.', onRetry: () => ref.invalidate(snapshotStreamProvider))
          : const Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Not found',
                message: 'This income source no longer exists. It may have been deleted.',
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Redesign building blocks (cards, heroes, timelines)
// ---------------------------------------------------------------------------

/// Organic badge holding an icon; [color] is the strong tone and the
/// background is a translucent wash of it (works in light and dark themes).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 40});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.accentText;
    return BlobBadge(
      color: fg.withValues(alpha: 0.14),
      size: size,
      seed: icon.codePoint,
      child: Icon(icon, size: size * 0.5, color: fg),
    );
  }
}

/// A titled form/content section on a white card: icon badge, bold title,
/// optional subtitle and trailing widget (e.g. an [InfoTip]).
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.color,
    this.subtitle,
    this.trailing,
    this.topGap = AppSpace.lg,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final Widget? trailing;
  final double topGap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topGap),
    child: EarnCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(title: title, icon: icon, color: color, subtitle: subtitle, trailing: trailing),
          const SizedBox(height: AppSpace.lg),
          ...children,
        ],
      ),
    ),
  );
}

/// Header row used inside cards: icon badge, bold title, optional subtitle
/// and a trailing widget.
class CardTitle extends StatelessWidget {
  const CardTitle({super.key, required this.title, this.icon, this.color, this.subtitle, this.trailing});
  final String title;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[IconBadge(icon!, color: color), const SizedBox(width: AppSpace.md)],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: AppType.caption.copyWith(color: context.colors.inkMuted)),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

/// Collapsible card for optional/advanced content. Children stay mounted
/// while collapsed so entered values (and form fields) are kept.
class ExpandableCard extends StatelessWidget {
  const ExpandableCard({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.tune_rounded,
    this.color,
    this.subtitle,
    this.initiallyExpanded = false,
    this.topGap = AppSpace.lg,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final List<Widget> children;
  final bool initiallyExpanded;
  final double topGap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topGap),
    child: EarnCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          leading: IconBadge(icon, color: color),
          title: Text(title, style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: AppType.caption.copyWith(color: context.colors.inkMuted)),
          children: children,
        ),
      ),
    ),
  );
}

/// Organic purple hero surface (matches the dashboard hero). Content gets
/// white text and icons by default. [night] uses the deep night gradient.
class HeroSurface extends StatelessWidget {
  const HeroSurface({super.key, required this.child, this.night = false, this.seed = 5, this.semanticLabel});
  final Widget child;
  final bool night;
  final int seed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = OrganicBorder(seed: seed, wobble: 0.8, radius: 38);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: AppShadows.glow,
          gradient: night ? AppGradients.night : AppGradients.hero,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                top: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.white.withValues(alpha: night ? 0.10 : 0.18),
                          AppColors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 22, 24),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: AppColors.white),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: AppColors.white),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark translucent pill used on hero surfaces (rates, status).
class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.child, this.icon, this.iconColor});
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.violetNight.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16, color: iconColor ?? AppColors.white), const SizedBox(width: 6)],
        Flexible(
          child: DefaultTextStyle.merge(
            style: AppType.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// Small pill telling the user which income a form or sub-page belongs to.
class SourceContextChip extends StatelessWidget {
  const SourceContextChip({super.key, required this.source, this.detail});
  final IncomeSource source;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.card(Theme.of(context).brightness),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SourceAvatar(source, size: 30),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                detail == null ? source.name : '${source.name} · $detail',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of a vertical timeline: a dot (or icon) on a connecting line.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.child,
    this.first = false,
    this.last = false,
    this.active = false,
    this.icon,
  });

  final Widget child;
  final bool first;
  final bool last;

  /// Highlights the dot (e.g. the rate currently in force).
  final bool active;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = icon != null
        ? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: c.accentText),
          )
        : Container(
            width: active ? 16 : 12,
            height: active ? 16 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active ? AppGradients.orb : null,
              color: active ? null : c.card,
              border: Border.all(color: active ? c.accentSoft : c.accentText, width: active ? 3 : 2),
            ),
          );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(width: 2, height: icon != null ? 8 : 18, color: first ? Colors.transparent : c.line),
                dot,
                Expanded(child: Container(width: 2, color: last ? Colors.transparent : c.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Large light headline with a muted subtitle (tab-root page title).
class PageHeadline extends StatelessWidget {
  const PageHeadline({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: AppType.headlineLight)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
      ],
    ],
  );
}

/// Shows the first [cap] children with a "Show all" link for the rest.
/// The expanded state lives in State, so it survives pull-to-refresh.
class CappedList extends StatefulWidget {
  const CappedList({super.key, required this.children, required this.noun, this.cap = 4});
  final List<Widget> children;
  final String noun;
  final int cap;

  @override
  State<CappedList> createState() => _CappedListState();
}

class _CappedListState extends State<CappedList> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.children;
    final capped = items.length > widget.cap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...(_all || !capped ? items : items.take(widget.cap)),
        if (capped)
          Center(
            child: LinkAction(
              label: _all ? 'Show fewer' : 'Show all ${items.length} ${widget.noun}',
              icon: _all ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              onTap: () => setState(() => _all = !_all),
            ),
          ),
      ],
    );
  }
}
