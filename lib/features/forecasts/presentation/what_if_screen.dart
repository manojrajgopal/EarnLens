import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/what_if.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/organic.dart';
import '../../analytics/presentation/analytics_widgets.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/what_if_data.dart';
import 'what_if_change_sheet.dart';

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  // Hypothetical changes live only in widget state: a pull-to-refresh
  // recomputes the baseline and keeps them.
  final List<WhatIfDraft> _changes = [];

  Future<void> _add(WhatIfBaseline base) async {
    final draft = await showWhatIfChangeSheet(context, base);
    if (draft != null && mounted) setState(() => _changes.add(draft));
  }

  Future<void> _refresh() => ref.read(appRefresherProvider).refresh({RefreshScope.earnings});

  @override
  Widget build(BuildContext context) {
    final base = ref.watch(whatIfBaselineProvider);
    final result = WhatIfCalculator.apply(
      baselineMonthly: base.monthly,
      baselineAnnual: base.annual,
      changes: [for (final d in _changes) d.change],
    );
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What if…'),
        actions: [
          if (_changes.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(_changes.clear),
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              label: const Text('Reset'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnalyticsBody(onRefresh: _refresh, children: [
        Semantics(
          liveRegion: false,
          child: EarnCard(
            tint: c.accentSoft,
            elevated: false,
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(children: [
              IconBadge(Icons.visibility_outlined, color: AppColors.white, background: c.accentText, size: 40),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Preview only', style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Nothing on this screen is saved, and your income and history stay exactly as they are.',
                    style: AppType.bodySmall.copyWith(color: c.ink),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpace.xl - 4),
        CardGrid(children: [
          EntranceScale(child: _ResultCard(result: result, hasChanges: _changes.isNotEmpty)),
          EntranceScale(
            delay: const Duration(milliseconds: 80),
            child: _ChangesCard(
              changes: _changes,
              onAdd: () => _add(base),
              onRemove: (d) => setState(() => _changes.remove(d)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.result, required this.hasChanges});
  final WhatIfResult result;
  final bool hasChanges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final muted = AppColors.white.withValues(alpha: 0.72);

    Widget block(String title, String subtitle, int before, int after, int delta) => Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: AppSpace.sm),
                Flexible(child: Text('· $subtitle', style: AppType.caption.copyWith(color: muted), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: AppSpace.md),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Now', style: AppType.caption.copyWith(color: muted)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AmountText(f.minor(before),
                          style: AppType.section.copyWith(color: muted, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, 4),
                  child: Icon(Icons.arrow_forward_rounded, size: AppIconSize.sm, color: muted),
                ),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('With changes', style: AppType.caption.copyWith(color: muted)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedAmount(
                        minor: after,
                        formatter: f,
                        style: AppType.amountLarge.copyWith(color: AppColors.white),
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.md),
              Wrap(spacing: AppSpace.sm, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                AmountText(
                  f.signed(delta),
                  style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: signedColor(context, delta)),
                ),
                ChangeBadge(delta: delta, percent: percentChange(before, after)),
              ]),
            ],
          ),
        );

    return EarnCard(
      accent: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(
          'Before and after',
          trailing: EstimatePill(),
          info: (
            'How this is calculated',
            '“Now” is the forecast for this month, and the sum of forecasts for this month and the next eleven '
                'for the year. Your changes are added on top for twelve months. Monthly changes apply from now; '
                'a one-time bonus only affects the annual total.',
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        block('Monthly', 'This month', result.baselineMonthly, result.newMonthly, result.monthlyDelta),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
          child: Divider(color: AppColors.white.withValues(alpha: 0.18)),
        ),
        block('Annual', 'Next 12 months', result.baselineAnnual, result.newAnnual, result.annualDelta),
        if (!hasChanges) ...[
          const SizedBox(height: AppSpace.lg),
          Text('Add a change to see how it would affect your earnings.', style: AppType.bodySmall.copyWith(color: muted)),
        ],
      ]),
    );
  }
}

class _ChangesCard extends ConsumerWidget {
  const _ChangesCard({required this.changes, required this.onAdd, required this.onRemove});
  final List<WhatIfDraft> changes;
  final VoidCallback onAdd;
  final ValueChanged<WhatIfDraft> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardTitle('Your changes', subtitle: changes.isEmpty ? null : '${changes.length} in this preview'),
        const SizedBox(height: AppSpace.md),
        if (changes.isEmpty)
          Text('Try a salary hike, a new monthly income, a one-time bonus or a change in weekly hours.',
              style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        for (final (i, d) in changes.indexed) ...[
          Builder(builder: (context) {
            final effect = WhatIfCalculator.apply(baselineMonthly: 0, baselineAnnual: 0, changes: [d.change]);
            final (bg, fg) = pastelAt(context, i);
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpace.md),
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, 4, AppSpace.sm),
              decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconBadge(d.icon, color: fg, background: bg, size: 40),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.title, style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Wrap(spacing: AppSpace.sm, runSpacing: 4, children: [
                        if (effect.monthlyDelta != 0) _DeltaChip('${f.signed(effect.monthlyDelta)} a month', effect.monthlyDelta),
                        _DeltaChip('${f.signed(effect.annualDelta)} over 12 months', effect.annualDelta),
                      ]),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Remove this change',
                    icon: Icon(Icons.close_rounded, color: c.inkMuted),
                    onPressed: () => onRemove(d),
                  ),
                ]),
                if (d.revisionSourceId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: TextButton.icon(
                      onPressed: () => context.push('/income/${d.revisionSourceId}/revision'),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Apply as real revision…'),
                    ),
                  ),
              ]),
            );
          }),
        ],
        const SizedBox(height: AppSpace.md),
        GradientButton(
          onPressed: onAdd,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded),
            SizedBox(width: AppSpace.sm),
            Text('Add a change'),
          ]),
        ),
      ]),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip(this.text, this.delta);
  final String text;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = delta > 0 ? c.positive : (delta < 0 ? c.overdue : c.inkMuted);
    final bg = delta > 0 ? c.positiveSoft : (delta < 0 ? c.errorSoft : c.card);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: AmountText(text, style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
