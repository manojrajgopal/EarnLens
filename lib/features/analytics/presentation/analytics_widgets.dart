import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';

/// Width at which analytics pages switch to two columns.
const wideBreakpoint = 900.0;
const maxContentWidth = 1100.0;

/// Scrollable page body with the standard padding (room for the floating
/// nav bar) and a centred maximum width.
///
/// Set [safeTop] on tab roots without an app bar so content starts below the
/// status bar / cutout.
class AnalyticsBody extends StatelessWidget {
  const AnalyticsBody({super.key, required this.children, this.onRefresh, this.safeTop = false});
  final List<Widget> children;

  /// Enables the branded pull-to-refresh (reloads and recomputes; filters
  /// held in widget state are preserved).
  final Future<void> Function()? onRefresh;
  final bool safeTop;

  @override
  Widget build(BuildContext context) => EarnPageList(
        maxWidth: maxContentWidth,
        onRefresh: onRefresh,
        top: safeTop ? MediaQuery.paddingOf(context).top + AppSpace.lg : AppSpace.sm,
        children: [Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)],
      );
}

/// Large light page title for tab roots, matching the dashboard greeting.
class TabPageHeader extends StatelessWidget {
  const TabPageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xl - 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(
              header: true,
              child: Text(title, style: AppType.headlineLight.copyWith(color: c.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            ],
          ]),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpace.md),
          Wrap(spacing: AppSpace.sm, children: actions),
        ],
      ]),
    );
  }
}

/// Pill-shaped "‹ October 2026 ⌄ ›" control. Tapping the label opens a picker.
class MonthNavPill extends StatelessWidget {
  const MonthNavPill({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    this.previousTooltip = 'Previous month',
    this.nextTooltip = 'Next month',
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget arrow(IconData icon, String tip, VoidCallback onTap) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: Icon(icon, color: c.accentText),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.card(Theme.of(context).brightness),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          arrow(Icons.chevron_left_rounded, previousTooltip, onPrevious),
          Expanded(
            child: Semantics(
              button: true,
              label: semanticLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: onPick,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ExcludeSemantics(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.section.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_more_rounded, size: AppIconSize.sm, color: c.inkMuted),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, nextTooltip, onNext),
        ]),
      ),
    );
  }
}

/// Single-choice filter pills: the selected pill is a violet gradient.
class FilterPills<T> extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.scroll = false,
    this.semanticPrefix,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Lay pills out in a horizontal scroller instead of wrapping.
  final bool scroll;
  final String? semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final pills = [
      for (final v in values) _FilterPill(label: label(v), selected: v == selected, onTap: () => onSelected(v), prefix: semanticPrefix),
    ];
    if (!scroll) return Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: pills);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (final (i, p) in pills.indexed) ...[if (i > 0) const SizedBox(width: AppSpace.sm), p],
      ]),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap, this.prefix});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(AppRadius.pill);
    return Semantics(
      button: true,
      selected: selected,
      label: prefix == null ? label : '$prefix $label',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.fast,
        curve: AppCurves.emphasized,
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: selected ? AppGradients.orb : null,
          color: selected ? null : c.card,
          border: selected ? null : Border.all(color: c.line),
          boxShadow: selected ? AppShadows.glow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppType.label.copyWith(
                      color: selected ? AppColors.white : c.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stacks cards vertically; on wide screens splits them into two columns.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children, this.spacing = AppSpace.lg + 4});
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        List<Widget> spaced(Iterable<Widget> ws) => [
              for (final (i, w) in ws.indexed) ...[if (i > 0) SizedBox(height: spacing), w],
            ];
        if (c.maxWidth < wideBreakpoint - 40) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced(children));
        }
        final left = [for (var i = 0; i < children.length; i += 2) children[i]];
        final right = [for (var i = 1; i < children.length; i += 2) children[i]];
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced(left))),
          SizedBox(width: spacing),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced(right))),
        ]);
      });
}

/// True when content sits on a purple/night [EarnCard] (white foreground).
bool onDarkSurface(BuildContext context) => DefaultTextStyle.of(context).style.color == AppColors.white;

/// Muted text colour that adapts to the surrounding card.
Color mutedColor(BuildContext context) =>
    onDarkSurface(context) ? AppColors.white.withValues(alpha: 0.72) : context.colors.inkMuted;

/// Colour for a signed change, readable on light and purple surfaces.
Color? signedColor(BuildContext context, int delta) {
  final dark = onDarkSurface(context);
  if (delta > 0) return dark ? AppColors.mint : context.colors.positive;
  if (delta < 0) return dark ? AppColors.peach : context.colors.overdue;
  return null;
}

/// Pastel background + matching foreground for organic tiles, coordinated
/// with the dashboard's rate tiles (tinted surfaces in dark mode).
(Color, Color) pastelAt(BuildContext context, int i) {
  const pastels = [
    (AppColors.lilacSoft, AppColors.violet),
    (AppColors.skySoft, AppColors.sky),
    (AppColors.mintSoft, AppColors.mint),
    (AppColors.peachSoft, AppColors.peach),
  ];
  final p = pastels[i % pastels.length];
  if (Theme.of(context).brightness == Brightness.dark) {
    return (Color.alphaBlend(p.$2.withValues(alpha: 0.18), context.colors.card), p.$2);
  }
  return p;
}

/// Compact axis label ("1.2L", "45K") for chart axes.
String compactAxis(double minorUnits, Currency currency) {
  final major = minorUnits / currency.minorPerMajor;
  if (major >= 10000000) return '${(major / 10000000).toStringAsFixed(1)}Cr';
  if (major >= 100000) return '${(major / 100000).toStringAsFixed(1)}L';
  if (major >= 1000) return '${(major / 1000).round()}K';
  return major.round().toString();
}

/// Card title row with an optional plain-language explanation.
class CardTitle extends StatelessWidget {
  const CardTitle(this.title, {super.key, this.info, this.trailing, this.subtitle});
  final String title;
  final (String, String)? info;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = mutedColor(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            header: true,
            child: Text(title, style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppType.caption.copyWith(color: muted)),
          ],
        ]),
      ),
      if (trailing != null) ...[const SizedBox(width: AppSpace.sm), trailing!],
      if (info != null) InfoTip(title: info!.$1, message: info!.$2, color: muted),
    ]);
  }
}

/// "Estimate" tag used on every forecast figure.
class EstimatePill extends StatelessWidget {
  const EstimatePill({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = onDarkSurface(context);
    return Pill(
      'Estimate',
      icon: Icons.auto_graph_rounded,
      color: dark ? AppColors.white.withValues(alpha: 0.18) : context.colors.accentSoft,
      textColor: dark ? AppColors.white : context.colors.accentText,
    );
  }
}

/// Label on the left, amount on the right.
class AmountRow extends ConsumerWidget {
  const AmountRow({super.key, required this.label, required this.minor, this.signed = false, this.bold = false, this.caption});
  final String label;
  final int minor;
  final bool signed;
  final bool bold;
  final String? caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final color = signed ? signedColor(context, minor) : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              label,
              style: bold ? AppType.label.copyWith(fontWeight: FontWeight.w700) : AppType.label.copyWith(color: mutedColor(context)),
            ),
            if (caption != null) Text(caption!, style: AppType.caption.copyWith(color: mutedColor(context))),
          ]),
        ),
        const SizedBox(width: AppSpace.md),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: AmountText(
              signed ? f.signed(minor) : f.minor(minor),
              style: (bold ? AppType.section : AppType.label).copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          ),
        ),
      ]),
    );
  }
}

/// Signed change with an optional percentage ("—" when not computable).
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.delta, required this.percent});
  final int delta;
  final String? percent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = onDarkSurface(context);
    final up = delta > 0;
    final down = delta < 0;
    final Color fg;
    final Color bg;
    if (dark) {
      fg = up ? AppColors.mint : (down ? AppColors.peach : AppColors.white);
      bg = AppColors.white.withValues(alpha: 0.16);
    } else {
      fg = up ? c.positive : (down ? c.overdue : c.inkMuted);
      bg = up ? c.positiveSoft : (down ? c.errorSoft : c.cardHigh);
    }
    final text = percent ?? '—';
    final label = percent == null
        ? 'No percentage: the earlier period had no earnings'
        : '${up ? 'Up' : (down ? 'Down' : 'No change,')} $text';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              up ? Icons.arrow_upward_rounded : (down ? Icons.arrow_downward_rounded : Icons.remove_rounded),
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(text, style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// Rounded square icon badge (tinted background, coloured glyph).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.background, this.size = AppIconSize.badge});
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(size * 0.34),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );
}

/// "42.5%" from basis points.
String formatBps(int bps) {
  final tenths = (bps + 5) ~/ 10;
  return '${tenths ~/ 10}.${tenths % 10}%';
}

/// Small coloured legend swatch.
class LegendDot extends StatelessWidget {
  const LegendDot(this.color, {super.key, this.size = 10, this.ring = false});
  final Color color;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ring ? null : color,
          shape: BoxShape.circle,
          border: ring ? Border.all(color: color, width: 2) : null,
        ),
      );
}
