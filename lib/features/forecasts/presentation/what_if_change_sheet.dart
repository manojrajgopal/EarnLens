import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/what_if.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../application/what_if_data.dart';

/// One hypothetical change as shown in the list.
class WhatIfDraft {
  WhatIfDraft({required this.title, required this.icon, required this.change, this.revisionSourceId});
  final String title;
  final IconData icon;
  final WhatIfChange change;

  /// Set for salary hikes: the source a real revision could be added to.
  final String? revisionSourceId;
}

enum _Kind {
  hike,
  monthly,
  oneTime,
  hours;

  String get label => switch (this) {
        hike => 'Salary hike',
        monthly => 'New monthly income',
        oneTime => 'One-time bonus',
        hours => 'Weekly hours',
      };
}

Future<WhatIfDraft?> showWhatIfChangeSheet(BuildContext context, WhatIfBaseline base) =>
    showModalBottomSheet<WhatIfDraft>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _ChangeSheet(base: base),
    );

class _ChangeSheet extends ConsumerStatefulWidget {
  const _ChangeSheet({required this.base});
  final WhatIfBaseline base;

  @override
  ConsumerState<_ChangeSheet> createState() => _ChangeSheetState();
}

class _ChangeSheetState extends ConsumerState<_ChangeSheet> {
  final _form = GlobalKey<FormState>();
  late _Kind _kind = widget.base.salarySources.isNotEmpty ? _Kind.hike : _Kind.monthly;
  late String? _salaryId = widget.base.salarySources.firstOrNull?.source.id;
  late String? _hourlyId = widget.base.hourlySources.firstOrNull?.source.id;
  final _percent = TextEditingController();
  final _amount = TextEditingController();
  final _hours = TextEditingController();

  @override
  void dispose() {
    _percent.dispose();
    _amount.dispose();
    _hours.dispose();
    super.dispose();
  }

  bool get _available => switch (_kind) {
        _Kind.hike => widget.base.salarySources.isNotEmpty,
        _Kind.hours => widget.base.hourlySources.isNotEmpty,
        _ => true,
      };

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final currency = ref.read(currencyProvider);
    final f = ref.read(moneyFormatterProvider);
    WhatIfDraft draft;
    switch (_kind) {
      case _Kind.hike:
        final src = widget.base.salarySources.firstWhere((s) => s.source.id == _salaryId);
        final bps = parseHundredths(_percent.text, allowNegative: true)!;
        draft = WhatIfDraft(
          title: '${_percent.text.trim()}% ${bps < 0 ? 'cut' : 'hike'} on ${src.source.name}',
          icon: Icons.trending_up_rounded,
          change: HikePercent(currentMonthlyMinor: src.rateMinor, percentBps: bps),
          revisionSourceId: src.source.id,
        );
      case _Kind.monthly:
        final v = parseMoney(_amount, currency)!;
        draft = WhatIfDraft(
          title: 'New income of ${f.minor(v)} a month',
          icon: Icons.add_card_rounded,
          change: ExtraMonthly(monthlyMinor: v),
        );
      case _Kind.oneTime:
        final v = parseMoney(_amount, currency)!;
        draft = WhatIfDraft(
          title: 'One-time bonus of ${f.minor(v)}',
          icon: Icons.redeem_outlined,
          change: OneTimeAmount(v),
        );
      case _Kind.hours:
        final src = widget.base.hourlySources.firstWhere((s) => s.source.id == _hourlyId);
        final h = parseHundredths(_hours.text, allowNegative: true)!;
        final hoursText = _hours.text.trim().replaceAll('−', '-');
        draft = WhatIfDraft(
          title: '${h > 0 && !hoursText.startsWith('+') ? '+' : ''}$hoursText hours a week at ${src.source.name}',
          icon: Icons.schedule_rounded,
          change: HoursChange(hourlyRateMinor: src.rateMinor, weeklyHoursDelta: h),
        );
    }
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currency = ref.watch(currencyProvider);
    final f = ref.watch(moneyFormatterProvider);
    final base = widget.base;
    final signedDecimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,+\-−]'))];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  width: AppIconSize.badge,
                  height: AppIconSize.badge,
                  decoration: const ShapeDecoration(
                    gradient: AppGradients.orb,
                    shape: BlobBorder(BlobSpec(seed: 17, radius: AppIconSize.badge * 0.42, wobble: 0.5, wave: 1.2)),
                    shadows: AppShadows.glow,
                  ),
                  child: const Icon(Icons.science_outlined, color: AppColors.white),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Semantics(
                      header: true,
                      child: Text('Add a change', style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Text('Preview only — nothing is saved', style: AppType.caption.copyWith(color: c.inkMuted)),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.xl),
              ChoicePills<_Kind>(
                values: _Kind.values,
                selected: _kind,
                label: (k) => k.label,
                onSelected: (k) => setState(() => _kind = k),
              ),
              const SizedBox(height: AppSpace.xl),
              if (!_available)
                Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: ShapeDecoration(
                    color: c.cardHigh,
                    shape: BlobBorder(BlobShapes.cloud(18, radius: 22, wobble: 0.45)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: c.accentText),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        _kind == _Kind.hike
                            ? 'You have no active salary source yet. Add one under Income to try a hike.'
                            : 'You have no active income paid by the hour. Weekly hours apply to sources with an hourly rate.',
                        style: AppType.bodySmall.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ]),
                )
              else
                ...switch (_kind) {
                  _Kind.hike => [
                      SelectField<String>(
                        label: 'Salary',
                        value: _salaryId!,
                        values: [for (final s in base.salarySources) s.source.id],
                        itemLabel: (id) {
                          final s = base.salarySources.firstWhere((x) => x.source.id == id);
                          return '${s.source.name} · ${f.minor(s.rateMinor, showMinor: false)}/mo';
                        },
                        onChanged: (v) => setState(() => _salaryId = v),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      TextFormField(
                        controller: _percent,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: signedDecimal,
                        decoration: const InputDecoration(
                          labelText: 'Hike',
                          suffixText: '%',
                          helperMaxLines: 2,
                          helperText: 'For example 10 or 12.5. Use a minus sign for a pay cut.',
                        ),
                        validator: (v) {
                          final bps = parseHundredths(v ?? '', allowNegative: true);
                          if (bps == null) return 'Enter a percentage with up to 2 decimals';
                          if (bps == 0) return 'Enter a non-zero percentage';
                          if (bps < -10000) return 'A cut cannot be more than 100%';
                          return null;
                        },
                      ),
                    ],
                  _Kind.monthly || _Kind.oneTime => [
                      MoneyField(
                        controller: _amount,
                        currency: currency,
                        label: _kind == _Kind.monthly ? 'Amount per month' : 'Bonus amount',
                        helper: _kind == _Kind.monthly
                            ? 'Like a part-time job or extra business income.'
                            : 'Counted once in the annual total.',
                      ),
                    ],
                  _Kind.hours => [
                      SelectField<String>(
                        label: 'Hourly income',
                        value: _hourlyId!,
                        values: [for (final s in base.hourlySources) s.source.id],
                        itemLabel: (id) {
                          final s = base.hourlySources.firstWhere((x) => x.source.id == id);
                          return '${s.source.name} · ${f.minor(s.rateMinor)}/hr';
                        },
                        onChanged: (v) => setState(() => _hourlyId = v),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      TextFormField(
                        controller: _hours,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: signedDecimal,
                        decoration: const InputDecoration(
                          labelText: 'Change in hours per week',
                          helperMaxLines: 2,
                          helperText: 'For example 5 for five more hours, or -4 for four fewer.',
                        ),
                        validator: (v) {
                          final h = parseHundredths(v ?? '', allowNegative: true);
                          if (h == null) return 'Enter hours with up to 2 decimals';
                          if (h == 0) return 'Enter a non-zero number of hours';
                          if (h.abs() > 168 * 100) return 'A week has only 168 hours';
                          return null;
                        },
                      ),
                    ],
                },
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: GradientButton(onPressed: _available ? _submit : null, child: const Text('Preview change')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
