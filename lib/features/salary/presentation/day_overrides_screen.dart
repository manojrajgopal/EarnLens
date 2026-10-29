import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../income_sources/presentation/widgets/income_common.dart';
import '../../refresh/application/app_refresher.dart';

/// Paid holidays and unpaid leave days.
class DayOverridesScreen extends ConsumerWidget {
  const DayOverridesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(overridesProvider);
    final sources = ref.watch(sourcesProvider);
    final names = {for (final s in sources) s.id: s.name};
    final hasWorkingDaySources = sources.any(_usesWorkingDays);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays & leave'),
        actions: [
          IconButton(
            tooltip: 'Add a day',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSheet(context),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: PageList(
        onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.sourceDetails}),
        children: [
          const InfoBanner(
            'Paid holidays only matter for income set to "Working days only": the day is skipped and your monthly '
            'pay is spread over the remaining working days. Unpaid leave is a day you are not paid for — it removes '
            'that day\'s pay from salary and rate-based income it applies to.',
          ),
          if (!hasWorkingDaySources) ...[
            vGapSmall,
            const InfoBanner(
              'None of your income uses "Working days only" yet, so paid holidays will not change any figures. '
              'You can switch an income to working days from its Edit screen.',
              tone: BannerTone.warning,
              icon: Icons.info_outline_rounded,
            ),
          ],
          vGap,
          GradientButton(
            onPressed: () => _showAddSheet(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: AppIconSize.md),
                SizedBox(width: AppSpace.sm),
                Flexible(child: Text('Add holiday or leave', maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          overrides.when(
            loading: () => const LoadingState(label: 'Loading holidays'),
            error: (e, _) =>
                ErrorState(message: 'Holidays could not be loaded.', onRetry: () => ref.invalidate(overridesProvider)),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.beach_access_outlined,
                  title: 'No days added',
                  message:
                      'Add public holidays, company holidays or unpaid leave so working-day earnings stay accurate.',
                );
              }
              final sorted = [...list]..sort((a, b) => b.date.compareTo(a.date));
              final groups = <YearMonth, List<DayOverride>>{};
              for (final o in sorted) {
                groups.putIfAbsent(o.date.yearMonth, () => []).add(o);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 4, AppSpace.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                formatMonth(entry.key),
                                style: AppType.section.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          Pill(
                            entry.value.length == 1 ? '1 day' : '${entry.value.length} days',
                            color: c.accentSoft,
                            textColor: c.accentText,
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      children: [
                        for (final o in entry.value)
                          ListTile(
                            minVerticalPadding: AppSpace.md,
                            contentPadding: const EdgeInsets.only(left: AppSpace.lg, right: AppSpace.xs),
                            leading: _DayBadge(date: o.date, holiday: o.type == DayOverrideType.holiday),
                            title: Text(
                              '${weekdayName(o.date)}, ${formatDate(o.date)}',
                              style: AppType.label.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Pill(
                                    o.type.label,
                                    color: o.type == DayOverrideType.holiday ? c.accentSoft : c.warningSoft,
                                    textColor: o.type == DayOverrideType.holiday ? c.accentText : c.warning,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      o.sourceId == null
                                          ? 'All working-day income'
                                          : (names[o.sourceId] ?? 'Removed income'),
                                      if (o.note != null && o.note!.isNotEmpty) o.note!,
                                    ].join(' · '),
                                    style: AppType.bodySmall.copyWith(color: c.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove',
                              icon: Icon(Icons.delete_outline_rounded, color: c.inkMuted),
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'Remove this day?',
                                  message:
                                      '${o.type.label} on ${formatDate(o.date)} will be removed and earnings '
                                      'recalculated. The change is recorded in history.',
                                  confirm: 'Remove',
                                  destructive: true,
                                );
                                if (ok && context.mounted) {
                                  await runGuarded(
                                    context,
                                    () => ref.read(incomeRepositoryProvider).deleteOverride(o.id),
                                    success: 'Removed',
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static bool _usesWorkingDays(IncomeSource s) =>
      s.kind.accruesContinuously &&
      (s.accrualPolicy == AccrualPolicy.workingDay ||
          (s.usesFixedTotal && s.fixedTotalAccrual == FixedTotalAccrual.spreadWorkingDays));

  static Future<void> _showAddSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _AddOverrideSheet(),
  );
}

class _AddOverrideSheet extends ConsumerStatefulWidget {
  const _AddOverrideSheet();

  @override
  ConsumerState<_AddOverrideSheet> createState() => _AddOverrideSheetState();
}

class _AddOverrideSheetState extends ConsumerState<_AddOverrideSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  LocalDate? _date;
  DayOverrideType _type = DayOverrideType.holiday;
  String? _sourceId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final date = _date!;
    final existing = ref.read(overridesProvider).value ?? const <DayOverride>[];
    if (existing.any((o) => o.date == date && o.sourceId == _sourceId)) {
      showMessage(context, 'That day is already added. Remove it first to change it.');
      return;
    }
    final o = DayOverride(
      id: ref.read(idProvider).newId(),
      date: date,
      type: _type,
      sourceId: _sourceId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final ok = await runGuarded(
      context,
      () => ref.read(incomeRepositoryProvider).addOverride(o),
      success: '${_type.label} added',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref
        .watch(sourcesProvider)
        .where((s) => s.kind.accruesContinuously && s.status != SourceStatus.archived)
        .toList();
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add holiday or leave', style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
                vGap,
                ChoicePills<DayOverrideType>(
                  values: DayOverrideType.values,
                  selected: _type,
                  label: (t) => t.label,
                  onSelected: (t) => setState(() => _type = t),
                ),
                vGapSmall,
                Text(
                  _type == DayOverrideType.holiday
                      ? 'A paid day off. It is not counted as a working day, so your pay is spread over the other days.'
                      : 'A day you are not paid for. That day earns nothing.',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
                vGap,
                DateField(
                  label: 'Date',
                  initial: _date,
                  onChanged: (d) => setState(() => _date = d),
                  validator: (d) => d == null ? 'Choose the date' : null,
                ),
                vGap,
                // SelectField ignores null selections, so '' stands for "all".
                SelectField<String>(
                  label: 'Applies to',
                  value: _sourceId ?? '',
                  values: ['', ...sources.map((s) => s.id)],
                  itemLabel: (id) => id.isEmpty ? 'All working-day income' : sources.firstWhere((s) => s.id == id).name,
                  onChanged: (id) => setState(() => _sourceId = id.isEmpty ? null : id),
                ),
                vGap,
                TextFormField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Diwali'),
                ),
                const SizedBox(height: AppSpace.xl),
                BusyButton(label: 'Add', accent: true, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Calendar-style badge: weekday over day number.
class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.date, required this.holiday});
  final LocalDate date;
  final bool holiday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = holiday ? c.accentText : c.warning;
    return Container(
      width: 46,
      height: 50,
      decoration: BoxDecoration(
        color: holiday ? c.accentSoft : c.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(weekdayName(date), style: AppType.caption.copyWith(color: fg, fontSize: 10, height: 1.1)),
          Text(
            '${date.day}',
            style: AppType.section.copyWith(color: fg, fontWeight: FontWeight.w700, height: 1.1),
          ),
        ],
      ),
    );
  }
}
