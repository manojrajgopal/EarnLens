import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../../shared/widgets/organic.dart';
import '../../accounts/presentation/account_gate.dart';
import '../../accounts/presentation/account_switcher_sheet.dart';
import '../../refresh/application/app_refresher.dart';
import 'widgets/income_common.dart';

/// All income sources with this month's progress and status filters.
class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  // Kept in State so it survives pull-to-refresh.
  final Set<SourceStatus> _filter = {SourceStatus.active, SourceStatus.paused, SourceStatus.ended};

  Future<void> _refresh() => ref.read(appRefresherProvider).refresh({RefreshScope.earnings});

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(snapshotStreamProvider);
    final sources = ref.watch(sourcesProvider);
    final readOnly = ref.watch(isReadOnlyViewProvider);
    final mq = MediaQuery.paddingOf(context);
    final top = mq.top + AppSpace.md;

    Widget body;
    if (snapAsync.isLoading && !snapAsync.hasValue) {
      body = const LoadingState(label: 'Loading income sources');
    } else if (snapAsync.hasError && !snapAsync.hasValue) {
      body = ErrorState(
        message: 'Your income sources could not be loaded.',
        onRetry: () => ref.invalidate(scopedSnapshotProvider),
      );
    } else if (sources.isEmpty) {
      body = PageList(
        top: top,
        refreshEdgeOffset: mq.top,
        onRefresh: _refresh,
        children: [
          const PageHeadline(title: 'Your income', subtitle: 'Everything you earn, in one place.'),
          const SizedBox(height: AppSpace.xl),
          if (readOnly)
            EmptyState(
              icon: Icons.groups_2_outlined,
              title: 'No income in these accounts yet',
              message: 'Combined accounts are read-only. Open one of the member accounts to add income.',
              action: 'Switch account',
              onAction: () => showAccountSwitcher(context),
            )
          else
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Add your first income',
              message:
                  'Add a salary, rent, freelance work or a one-off payment. '
                  'EarnLens then shows what you have earned so far, what is due and what has been paid.',
              action: 'Add income',
              onAction: () => showAddIncomeSheet(context),
            ),
        ],
      );
    } else {
      final visible = sources.where((s) => _filter.contains(s.status)).toList();
      final counts = {for (final st in SourceStatus.values) st: sources.where((s) => s.status == st).length};
      final active = counts[SourceStatus.active] ?? 0;
      body = PageList(
        top: top,
        refreshEdgeOffset: mq.top,
        onRefresh: _refresh,
        extraBottom: readOnly ? 0 : 72, // room for the floating "Add income" pill
        children: [
          PageHeadline(
            title: 'Your income',
            subtitle:
                '${sources.length} ${sources.length == 1 ? 'source' : 'sources'} · $active active. '
                'Tap a source for details, payments and history.',
          ),
          const SizedBox(height: AppSpace.lg),
          const ReadOnlyBanner(),
          // One scrollable row of filters (wraps nothing, never overflows).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final (i, st) in SourceStatus.values.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.sm),
                  _FilterPill(
                    label: st.label,
                    count: counts[st] ?? 0,
                    selected: _filter.contains(st),
                    onTap: () => setState(() => _filter.contains(st) ? _filter.remove(st) : _filter.add(st)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.filter_alt_off_outlined,
              title: 'Nothing to show',
              message: 'No income sources match the selected filters.',
              action: 'Show all',
              onAction: () => setState(() => _filter.addAll(SourceStatus.values)),
            )
          else
            for (final (i, s) in visible.indexed) ...[
              EntranceScale(
                delay: Duration(milliseconds: 60 * i.clamp(0, 6)),
                child: _SourceTile(source: s),
              ),
              const SizedBox(height: AppSpace.md),
            ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (sources.isNotEmpty && !readOnly)
            Positioned(
              right: AppSpace.gutter + mq.right,
              bottom: mq.bottom + AppSpace.lg,
              child: Semantics(
                button: true,
                label: 'Add income',
                excludeSemantics: true,
                child: GradientButton(
                  onPressed: () => showAddIncomeSheet(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: AppIconSize.md),
                      SizedBox(width: AppSpace.sm),
                      Text('Add income'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill toggle for a status filter, with its count.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.count, required this.selected, required this.onTap});
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.accentText : c.ink;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : AppDurations.fast,
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? c.accentText.withValues(alpha: 0.35) : c.line),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: reduce ? Duration.zero : AppDurations.fast,
                      child: selected
                          ? Padding(
                              key: const ValueKey('on'),
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_rounded, size: 16, color: fg),
                            )
                          : const SizedBox(key: ValueKey('off'), width: 4),
                    ),
                    Text(
                      label,
                      style: AppType.label.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.violet : c.cardHigh,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: AppType.caption.copyWith(color: selected ? AppColors.white : c.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing each [IncomeKind] with its description.
Future<void> showAddIncomeSheet(BuildContext context) async {
  const tones = [AppColors.violet, AppColors.peach, AppColors.mint, AppColors.sky, AppColors.orchid];
  const softs = [AppColors.lilacSoft, AppColors.peachSoft, AppColors.mintSoft, AppColors.skySoft, AppColors.blush];
  final kind = await showModalBottomSheet<IncomeKind>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final c = ctx.colors;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('What kind of income?', style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpace.xs),
              Text(
                'This decides how EarnLens works out what you have earned.',
                style: AppType.bodySmall.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              for (final (i, k) in IncomeKind.values.indexed) ...[
                OrganicTile(
                  seed: i + 2,
                  color: dark
                      ? Color.alphaBlend(tones[i % tones.length].withValues(alpha: 0.2), c.card)
                      : softs[i % softs.length],
                  semanticLabel: '${k.label}. ${k.description}',
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  onTap: () => Navigator.pop(ctx, k),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: tones[i % tones.length]),
                        child: Icon(IncomeVisuals.kindIcon(k), color: AppColors.white, size: AppIconSize.md),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.label,
                              style: AppType.section.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(k.description, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: tones[i % tones.length]),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (kind != null && context.mounted) context.push('/income/new?kind=${kind.name}');
}

class _SourceTile extends ConsumerWidget {
  const _SourceTile({required this.source});
  final IncomeSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final snap = ref.watch(snapshotProvider);
    final calc = ref.watch(earningsCalculatorProvider);
    final fmt = moneyFormatterFor(ref, source.currencyCode);
    final (today, now) = liveNow(ref);
    final s = source;
    final summary = snap.rules.containsKey(s.id)
        ? calc.summarizeSource(snap, s, DateRange.month(today.yearMonth), now, today)
        : null;

    final String earnedLabel;
    final String? earnedValue;
    if (summary == null) {
      earnedLabel = 'This month';
      earnedValue = null;
    } else if (!summary.hasActual) {
      earnedLabel = 'No actual recorded yet';
      earnedValue = null;
    } else {
      earnedLabel = 'Earned so far this month';
      earnedValue = fmt.minor(summary.actual);
    }
    final progress = summary != null && summary.expected > 0 && summary.hasActual
        ? (summary.actual / summary.expected).clamp(0.0, 1.0)
        : null;

    return EarnCard(
      onTap: () => context.push('/income/${s.id}'),
      semanticLabel: '${s.name}, ${s.kind.label}, ${s.status.label}',
      radius: AppRadius.xl - 4,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SourceAvatar(s, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: AppType.section.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        s.kind.label,
                        s.categoryLabel,
                        // In a combined view, whose income this is.
                        if (ref.watch(isReadOnlyViewProvider)) ?ref.watch(accountByIdProvider(s.accountId))?.name,
                      ].join(' · '),
                      style: AppType.bodySmall.copyWith(color: c.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SourceStatusPill(s.status),
                        if (s.isSample)
                          Pill('Sample', color: c.accentSoft, textColor: c.accentText, icon: Icons.science_outlined),
                        if (s.currencyCode != ref.watch(currencyProvider).code) Pill(s.currencyCode),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.accentText),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(earnedLabel, style: AppType.caption.copyWith(color: c.inkMuted)),
                        const SizedBox(height: 2),
                        if (earnedValue != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AmountText(earnedValue, style: AppType.amountMedium),
                          )
                        else
                          Text('—', style: AppType.amountMedium.copyWith(color: c.inkMuted)),
                      ],
                    ),
                  ),
                  if (summary.expected > 0) ...[
                    const SizedBox(width: AppSpace.md),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Expected', style: AppType.caption.copyWith(color: c.inkMuted)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: AmountText(
                              fmt.minor(summary.expected),
                              style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.md),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GradientProgress(value: progress, height: 8, semanticsLabel: 'Progress this month'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
