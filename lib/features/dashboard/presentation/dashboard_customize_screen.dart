import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/services/dashboard_preferences.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';

/// Choose earning units, primary rate, cards (order, size, source filter),
/// precision and density. Every change is saved immediately.
class DashboardCustomizeScreen extends ConsumerWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(dashboardConfigProvider);
    final save = ref.read(settingsControllerProvider).saveDashboard;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize dashboard'),
        actions: [
          TextButton(
            onPressed: () async {
              if (await confirmDialog(
                context,
                title: 'Restore defaults?',
                message: 'Your card order, rates and display options will be reset.',
                confirm: 'Restore',
              )) {
                await save(DashboardConfig.defaults());
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: EarnPageList(
        children: [
          SectionHeader('Earning rates'),
          EarnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shown on the dashboard. At least one rate always stays selected.',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final u in EarningUnit.values)
                      FilterChip(
                        label: Text(u.label),
                        selected: cfg.units.contains(u),
                        labelStyle: AppType.label.copyWith(
                          color: cfg.units.contains(u) ? c.accentText : c.ink,
                          fontWeight: cfg.units.contains(u) ? FontWeight.w700 : FontWeight.w500,
                        ),
                        tooltip: cfg.units.length == 1 && cfg.units.contains(u)
                            ? 'At least one rate must remain'
                            : null,
                        onSelected: (_) => save(DashboardPreferences.toggleUnit(cfg, u)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => save(DashboardPreferences.selectAll(cfg)),
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => save(DashboardPreferences.deselectAll(cfg)),
                      child: const Text('Keep only main rate'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Order (drag to reorder)', style: AppType.label),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (o, n) => save(DashboardPreferences.reorderUnits(cfg, o, n)),
                  children: [
                    for (final (i, u) in cfg.units.indexed)
                      ListTile(
                        key: ValueKey(u),
                        contentPadding: EdgeInsets.zero,
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_indicator_rounded),
                        ),
                        title: Text(u.label),
                        trailing: u == cfg.primaryUnit
                            ? Pill('Main rate', color: c.accentSoft, textColor: c.accentText, icon: Icons.star_rounded)
                            : TextButton(
                                onPressed: () => save(DashboardPreferences.setPrimary(cfg, u)),
                                child: const Text('Make main'),
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader('Display'),
          EarnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live counter shows', style: AppType.label),
                const SizedBox(height: 8),
                ChoicePills<CounterRange>(
                  values: CounterRange.values,
                  selected: cfg.counterRange,
                  label: (r) => r.label,
                  onSelected: (r) => save(cfg.copyWith(counterRange: r)),
                ),
                const SizedBox(height: 16),
                Text('Decimal places for small rates: ${cfg.precision}', style: AppType.label),
                Slider(
                  value: cfg.precision.toDouble(),
                  min: 0,
                  max: 6,
                  divisions: 6,
                  label: '${cfg.precision}',
                  onChanged: (v) => save(DashboardPreferences.setPrecision(cfg, v.round())),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact numbers'),
                  subtitle: const Text('Hide paise on monthly and yearly rates'),
                  value: cfg.compact,
                  onChanged: (v) => save(cfg.copyWith(compact: v)),
                ),
                const SizedBox(height: 4),
                Text('Hourly, minute and second rates', style: AppType.label),
                const SizedBox(height: 8),
                ChoicePills<RateBasis>(
                  values: RateBasis.values,
                  selected: cfg.rateBasis,
                  label: (b) => b.label,
                  onSelected: (b) => save(cfg.copyWith(rateBasis: b)),
                ),
              ],
            ),
          ),
          SectionHeader('Cards'),
          Text(
            'Drag to reorder. Tap a card to choose its size and which income it includes.',
            style: AppType.bodySmall.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (o, n) => save(DashboardPreferences.reorderCards(cfg, o, n)),
            children: [
              for (final (i, card) in cfg.cards.indexed)
                Padding(
                  key: ValueKey(card.type),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EarnCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator_rounded)),
                      title: Text(card.type.label),
                      subtitle: Text(
                        [
                          card.size == CardSize.compact ? 'Compact' : 'Large',
                          card.sourceIds == null ? 'All income' : '${card.sourceIds!.length} selected',
                        ].join(' · '),
                      ),
                      onTap: () => _editCard(context, ref, card),
                      trailing: Switch(
                        value: card.visible,
                        onChanged: (v) => save(DashboardPreferences.updateCard(cfg, card.copyWith(visible: v))),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editCard(BuildContext context, WidgetRef ref, DashboardCardConfig card) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final cfg = ref.watch(dashboardConfigProvider);
          final current = cfg.cards.firstWhere((x) => x.type == card.type);
          final sources = ref.watch(sourcesProvider);
          final save = ref.read(settingsControllerProvider).saveDashboard;
          void update(DashboardCardConfig next) => save(DashboardPreferences.updateCard(cfg, next));
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Text(current.type.label, style: AppType.title),
                const SizedBox(height: 16),
                Text('Size', style: AppType.label),
                const SizedBox(height: 8),
                ChoicePills<CardSize>(
                  values: CardSize.values,
                  selected: current.size,
                  label: (s) => s == CardSize.compact ? 'Compact' : 'Large',
                  onSelected: (s) => update(current.copyWith(size: s)),
                ),
                if (current.type.supportsSourceFilter) ...[
                  const SizedBox(height: 20),
                  Text('Includes', style: AppType.label),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('All income sources'),
                    value: current.sourceIds == null,
                    onChanged: (all) => update(
                      all
                          ? current.copyWith(allSources: true)
                          : current.copyWith(sourceIds: sources.map((s) => s.id).toSet()),
                    ),
                  ),
                  if (current.sourceIds != null)
                    for (final s in sources)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        value: current.sourceIds!.contains(s.id),
                        onChanged: (v) {
                          final ids = {...current.sourceIds!};
                          v == true ? ids.add(s.id) : ids.remove(s.id);
                          update(current.copyWith(sourceIds: ids));
                        },
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
