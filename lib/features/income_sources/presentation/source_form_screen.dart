import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/money_parser.dart';
import '../../../domain/services/validators.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import 'widgets/income_common.dart';
import 'widgets/schedule_editor.dart';

/// Create or edit an income source. Fields adapt to the [IncomeKind].
class SourceFormScreen extends ConsumerStatefulWidget {
  const SourceFormScreen({super.key, this.kind, this.sourceId});

  final IncomeKind? kind;
  final String? sourceId;

  @override
  ConsumerState<SourceFormScreen> createState() => _SourceFormScreenState();
}

class _SourceFormScreenState extends ConsumerState<SourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _employer = TextEditingController();
  final _customCategory = TextEditingController();
  final _notes = TextEditingController();
  final _amount = TextEditingController();
  final _takeHome = TextEditingController();

  bool _ready = false;
  IncomeSource? _existing;

  IncomeKind _kind = IncomeKind.salary;
  IncomeCategory _category = IncomeCategory.salary;
  Currency _currency = Currency.inr;
  late LocalDate _start;
  LocalDate? _end;
  AccrualPolicy _policy = AccrualPolicy.calendarDay;
  WorkSchedule _schedule = const WorkSchedule();
  PayRule _payRule = PayRule.dayOfMonth;
  int _payDay = 1;
  int _payOffset = 1;
  WeekendAdjust _weekend = WeekendAdjust.none;
  LocalDate? _expectedPayDate;
  RatePeriod _period = RatePeriod.month;
  bool _useFixedTotal = false;
  FixedTotalAccrual _fixedAccrual = FixedTotalAccrual.spreadCalendarDays;
  ForecastMethod _forecast = ForecastMethod.estimate;
  int _colorIndex = 0;
  bool _alreadyReceived = false;

  bool get _isEdit => widget.sourceId != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) {
      final settings = ref.read(calculationSettingsProvider);
      _kind = widget.kind ?? IncomeKind.salary;
      _currency = ref.read(currencyProvider);
      _start = currentDate(ref);
      _policy = settings.defaultPolicy;
      _schedule = settings.defaultSchedule;
      _colorIndex = ref.read(sourcesProvider).length % AppColors.series.length;
      _applyKindDefaults(_kind);
      _ready = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _employer, _customCategory, _notes, _amount, _takeHome]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyKindDefaults(IncomeKind k) {
    _category = switch (k) {
      IncomeKind.salary => IncomeCategory.salary,
      IncomeKind.recurring => IncomeCategory.rental,
      IncomeKind.temporary => IncomeCategory.partTime,
      IncomeKind.variable => IncomeCategory.freelance,
      IncomeKind.oneTime => IncomeCategory.other,
    };
    _period = k == IncomeKind.temporary ? RatePeriod.day : RatePeriod.month;
    _payRule = k == IncomeKind.temporary ? PayRule.manual : PayRule.dayOfMonth;
    _payOffset = k == IncomeKind.salary ? 1 : 0;
    _useFixedTotal = false;
    if (k != IncomeKind.temporary) _end = null;
  }

  void _loadExisting(IncomeSource s) {
    _existing = s;
    _kind = s.kind;
    _name.text = s.name;
    _employer.text = s.employer ?? '';
    _customCategory.text = s.customCategory ?? '';
    _notes.text = s.notes ?? '';
    _category = s.category;
    _currency = Currency.byCode(s.currencyCode);
    _start = s.startDate;
    _end = s.endDate;
    _policy = s.accrualPolicy;
    _schedule = s.schedule;
    _payRule = s.payRule;
    _payDay = s.payDay;
    _payOffset = s.payOffsetMonths;
    _weekend = s.weekendAdjust;
    _expectedPayDate = s.expectedPayDate;
    _useFixedTotal = s.usesFixedTotal;
    _fixedAccrual = s.fixedTotalAccrual;
    _forecast = s.forecastMethod;
    _colorIndex = s.colorIndex;
    if (s.fixedTotalMinor != null) _amount.text = MoneyParser.toInput(s.fixedTotalMinor!, _currency);
    if (s.takeHomeMinor != null) _takeHome.text = MoneyParser.toInput(s.takeHomeMinor!, _currency);
    // Hourly-rate sources must stay on working days.
    final revs = ref.read(snapshotProvider).rules[s.id]?.revisions ?? const <RateRevision>[];
    if (revs.isNotEmpty) _period = revs.last.period;
    _ready = true;
  }

  // ---- Derived flags ------------------------------------------------------

  bool get _isRuleBased => _kind.accruesContinuously;
  bool get _showPolicy => _isRuleBased && !(_kind == IncomeKind.temporary && _useFixedTotal);
  bool get _showSchedule =>
      (_showPolicy && _policy == AccrualPolicy.workingDay) ||
      (_kind == IncomeKind.temporary && _useFixedTotal && _fixedAccrual == FixedTotalAccrual.spreadWorkingDays);

  /// Pay amount fields that create a rate revision are only shown on create.
  bool get _editsRateHere => !_isEdit;

  List<RatePeriod> get _periodChoices => switch (_kind) {
    IncomeKind.recurring => const [RatePeriod.day, RatePeriod.week, RatePeriod.month, RatePeriod.year],
    IncomeKind.temporary => const [RatePeriod.hour, RatePeriod.day],
    _ => const [RatePeriod.month],
  };

  String get _startLabel => switch (_kind) {
    IncomeKind.salary => 'Joining date',
    IncomeKind.oneTime => 'Expected date',
    _ => 'Start date',
  };

  String get _endLabel => switch (_kind) {
    IncomeKind.salary => 'Last working day',
    IncomeKind.temporary => 'End date',
    _ => 'End date',
  };

  String get _amountLabel => switch (_kind) {
    IncomeKind.salary => 'Monthly gross salary',
    IncomeKind.recurring => 'Amount',
    IncomeKind.temporary => _useFixedTotal ? 'Total for the whole job' : 'Rate',
    IncomeKind.variable => 'Typical monthly income (estimate)',
    IncomeKind.oneTime => 'Amount',
  };

  void _setPeriod(RatePeriod p) {
    setState(() {
      _period = p;
      if (p == RatePeriod.hour) _policy = AccrualPolicy.workingDay;
    });
  }

  void _setPolicy(AccrualPolicy p) {
    if (p == AccrualPolicy.calendarDay && _period == RatePeriod.hour && _kind == IncomeKind.temporary) {
      showMessage(
        context,
        'Hourly pay needs "Working days only" so EarnLens knows your hours. Switch to a daily rate first.',
      );
      return;
    }
    setState(() => _policy = p);
  }

  // ---- Save ---------------------------------------------------------------

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showMessage(context, 'Please fix the highlighted fields.');
      return;
    }
    final clock = ref.read(clockProvider);
    final ids = ref.read(idProvider);
    final now = clock.now();
    final existing = _existing;
    final amount = parseMoney(_amount, _currency);
    final takeHome = parseMoney(_takeHome, _currency);
    final usesFixed = _kind == IncomeKind.temporary && _useFixedTotal;
    final id = existing?.id ?? ids.newId();
    final oneTime = _kind == IncomeKind.oneTime;
    final effectivePolicy = usesFixed
        ? (_fixedAccrual == FixedTotalAccrual.spreadWorkingDays ? AccrualPolicy.workingDay : AccrualPolicy.calendarDay)
        : _policy;

    final source = IncomeSource(
      id: id,
      name: _name.text.trim(),
      kind: _kind,
      category: _category,
      customCategory: _category == IncomeCategory.custom ? _customCategory.text.trim() : null,
      status: existing?.status ?? SourceStatus.active,
      currencyCode: _currency.code,
      startDate: _start,
      endDate: oneTime ? null : _end,
      accrualPolicy: effectivePolicy,
      schedule: _schedule,
      payRule: oneTime ? PayRule.manual : _payRule,
      payDay: _payDay,
      payOffsetMonths: _payOffset,
      weekendAdjust: _payRule == PayRule.manual ? WeekendAdjust.none : _weekend,
      expectedPayDate: oneTime ? _start : (_payRule == PayRule.manual ? _expectedPayDate : null),
      fixedTotalMinor: usesFixed ? amount : null,
      fixedTotalAccrual: _fixedAccrual,
      forecastMethod: _forecast,
      employer: _kind == IncomeKind.salary && _employer.text.trim().isNotEmpty ? _employer.text.trim() : null,
      takeHomeMinor: _kind == IncomeKind.salary ? takeHome : null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      colorIndex: _colorIndex,
      isSample: existing?.isSample ?? false,
      sortOrder: existing?.sortOrder ?? 0,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    RateRevision? initialRate;
    if (!_isEdit && !usesFixed && !oneTime && amount != null) {
      initialRate = RateRevision(
        id: ids.newId(),
        sourceId: id,
        effectiveFrom: _start,
        amountMinor: amount,
        period: _period,
        changeType: _kind == IncomeKind.variable ? RevisionChangeType.estimateUpdate : RevisionChangeType.initial,
        createdAt: now,
      );
    }

    try {
      Validators.source(source);
      if (initialRate != null) Validators.revision(initialRate, source);
      if (_isEdit) {
        final revs = ref.read(snapshotProvider).rules[id]?.revisions ?? const <RateRevision>[];
        for (final r in revs) {
          Validators.revision(r, source);
        }
      }
    } on ValidationException catch (e) {
      showMessage(context, e.message);
      return;
    }

    final incomeRepo = ref.read(incomeRepositoryProvider);
    if (_isEdit) {
      final ok = await runGuarded(context, () => incomeRepo.updateSource(source), success: 'Changes saved');
      if (ok && mounted) context.pop();
      return;
    }

    final records = ref.read(recordsRepositoryProvider);
    final ok = await runGuarded(context, () async {
      if (oneTime) {
        // Validate the item before writing anything so nothing is half-saved.
        final item = CompensationItem(
          id: ids.newId(),
          sourceId: id,
          type: CompensationType.oneTimeIncome,
          title: source.name,
          currencyCode: _currency.code,
          expectedMinor: amount,
          expectedDate: _start,
          actualMinor: _alreadyReceived ? amount : null,
          earnedDate: _alreadyReceived ? _start : null,
          createdAt: now,
          updatedAt: now,
        );
        Validators.item(item);
        await incomeRepo.createSource(source);
        await records.saveItem(item);
        if (_alreadyReceived && amount != null) {
          await records.addLedgerEntry(
            LedgerEntry(
              id: ids.newId(),
              sourceId: id,
              itemId: item.id,
              type: LedgerType.received,
              amountMinor: amount,
              currencyCode: _currency.code,
              periodMonth: _start.yearMonth,
              date: _start,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      } else {
        await incomeRepo.createSource(source, initialRate: initialRate);
      }
    }, success: 'Income added');
    if (ok && mounted) context.go('/income/$id');
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      final s = ref.watch(sourceProvider(widget.sourceId!));
      if (s == null) return const MissingSourceScaffold(title: 'Edit income');
      _loadExisting(s);
    }
    final c = context.colors;
    final title = _isEdit ? 'Edit income' : 'Add ${_kind.label.toLowerCase()}';

    final payFields = _payFields(context);
    final schedule = ScheduleEditor(schedule: _schedule, onChanged: (s) => setState(() => _schedule = s));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: PageList(
          children: [
            _KindHeader(kind: _kind, isEdit: _isEdit),
            FormSection(
              title: 'Basics',
              subtitle: 'Name, category and currency',
              icon: Icons.badge_outlined,
              children: [
                if (!_isEdit) ...[
                  SelectField<IncomeKind>(
                    label: 'Type of income',
                    value: _kind,
                    values: IncomeKind.values,
                    itemLabel: (k) => k.label,
                    helper: _kind.description,
                    onChanged: (k) => setState(() {
                      _kind = k;
                      _applyKindDefaults(k);
                    }),
                  ),
                  vGap,
                ],
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    helperText: switch (_kind) {
                      IncomeKind.salary => 'For example "Salary – Acme"',
                      IncomeKind.recurring => 'For example "Flat rent" or "Retainer – Studio X"',
                      IncomeKind.temporary => 'For example "Weekend tutoring"',
                      IncomeKind.variable => 'For example "Design studio" or "Etsy shop"',
                      IncomeKind.oneTime => 'For example "Tax refund" or "Prize money"',
                    },
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                if (_kind == IncomeKind.salary) ...[
                  vGapSmall,
                  TextFormField(
                    controller: _employer,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Employer (optional)'),
                  ),
                ],
                vGap,
                SelectField<IncomeCategory>(
                  key: ValueKey('category-$_kind-$_category'),
                  label: 'Category',
                  value: _category,
                  values: IncomeCategory.values,
                  itemLabel: (cat) => cat.label,
                  onChanged: (cat) => setState(() => _category = cat),
                ),
                if (_category == IncomeCategory.custom) ...[
                  vGap,
                  TextFormField(
                    controller: _customCategory,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Custom category name'),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a category name' : null,
                  ),
                ],
                vGap,
                if (_isEdit)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      helperText: 'The currency cannot be changed because existing amounts are stored in it.',
                      helperMaxLines: 2,
                    ),
                    child: Text('${_currency.code} · ${_currency.name}', style: AppType.body),
                  )
                else
                  SelectField<Currency>(
                    label: 'Currency',
                    value: _currency,
                    values: Currency.supported,
                    itemLabel: (cur) => '${cur.code} · ${cur.name}',
                    helper: 'Totals only add up income in your main currency.',
                    onChanged: (cur) => setState(() => _currency = cur),
                  ),
              ],
            ),
            FormSection(
              title: 'Dates',
              icon: Icons.event_rounded,
              color: AppColors.sky,
              children: [
                DateField(
                  key: ValueKey('start-$_kind'),
                  label: _startLabel,
                  initial: _start,
                  helper: _kind == IncomeKind.salary ? 'Earnings start on this day.' : null,
                  onChanged: (d) => setState(() => _start = d ?? _start),
                ),
                if (_kind != IncomeKind.oneTime) ...[
                  vGap,
                  DateField(
                    key: ValueKey('end-$_kind'),
                    label: _kind == IncomeKind.temporary ? _endLabel : '$_endLabel (optional)',
                    initial: _end,
                    optional: _kind != IncomeKind.temporary,
                    helper: _kind == IncomeKind.salary
                        ? 'Leave empty while you still work here.'
                        : _kind == IncomeKind.temporary
                        ? 'Temporary work needs an end date.'
                        : 'Leave empty if it continues.',
                    onChanged: (d) => setState(() => _end = d),
                    validator: (d) {
                      if (_kind == IncomeKind.temporary && d == null) return 'Choose the end date';
                      if (d != null && d.isBefore(_start)) return 'End date cannot be before the start date';
                      return null;
                    },
                  ),
                ],
              ],
            ),
            if (payFields.isNotEmpty)
              FormSection(title: 'Pay', icon: Icons.payments_outlined, color: AppColors.mint, children: payFields),
            if (_showPolicy)
              FormSection(
                title: 'How it is earned',
                icon: Icons.speed_rounded,
                color: AppColors.orchid,
                trailing: const InfoTip(
                  title: 'Accrual',
                  message:
                      'Accrual is how your pay builds up over time. "Every calendar day" spreads the month\'s '
                      'pay evenly across every day and second, including weekends. "Working days only" earns only on '
                      'your working days and during your working hours, and lets you mark holidays and unpaid leave.',
                ),
                children: [
                  ..._policyFields(context),
                  if (_showSchedule) ...[vGap, schedule],
                ],
              )
            else if (_showSchedule)
              FormSection(
                title: 'Working days',
                icon: Icons.work_history_outlined,
                color: AppColors.orchid,
                children: [schedule],
              ),
            if (_isRuleBased)
              FormSection(
                title: 'When you get paid',
                icon: Icons.account_balance_outlined,
                color: AppColors.peach,
                children: _paymentRuleFields(context),
              ),
            ExpandableCard(
              title: 'More options',
              subtitle: _kind == IncomeKind.variable ? 'Forecast, colour and notes' : 'Colour and notes',
              icon: Icons.tune_rounded,
              children: [
                if (_kind == IncomeKind.variable) ...[
                  SelectField<ForecastMethod>(
                    label: 'How to forecast future months',
                    value: _forecast,
                    values: ForecastMethod.values,
                    itemLabel: (m) => m.label,
                    helper: 'Used for months where you have not entered an estimate.',
                    onChanged: (m) => setState(() => _forecast = m),
                  ),
                  vGap,
                ],
                Text('Colour', style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                vGapSmall,
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (var i = 0; i < AppColors.series.length; i++)
                      Semantics(
                        button: true,
                        selected: i == _colorIndex,
                        label: 'Colour ${i + 1}',
                        excludeSemantics: true,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _colorIndex = i),
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.fast,
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.series[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i == _colorIndex ? c.accentText : c.line,
                                width: i == _colorIndex ? 3 : 1,
                              ),
                            ),
                            child: i == _colorIndex
                                ? Icon(
                                    Icons.check_rounded,
                                    color: ThemeData.estimateBrightnessForColor(AppColors.series[i]) == Brightness.dark
                                        ? AppColors.white
                                        : AppColors.ink,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                vGap,
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            BusyButton(label: _isEdit ? 'Save changes' : 'Add income', accent: true, onPressed: _save),
          ],
        ),
      ),
    );
  }

  List<Widget> _payFields(BuildContext context) {
    final out = <Widget>[];

    if (_kind == IncomeKind.temporary && !_isEdit) {
      out.addAll([
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Rate'), icon: Icon(Icons.schedule_rounded)),
            ButtonSegment(value: true, label: Text('Fixed total'), icon: Icon(Icons.payments_outlined)),
          ],
          selected: {_useFixedTotal},
          onSelectionChanged: (s) => setState(() => _useFixedTotal = s.first),
        ),
        vGap,
      ]);
    }

    final fixedTotalEditable = _kind == IncomeKind.temporary && _useFixedTotal;
    final oneTimeCreate = _kind == IncomeKind.oneTime && !_isEdit;

    if (_editsRateHere || fixedTotalEditable) {
      if (!(_kind == IncomeKind.oneTime && _isEdit)) {
        out.add(
          MoneyField(
            controller: _amount,
            currency: _currency,
            label: _amountLabel,
            helper: switch (_kind) {
              IncomeKind.salary => 'Before tax and deductions. Pay changes are added later as revisions.',
              IncomeKind.variable => 'A starting estimate. You can record actual figures each month.',
              _ => null,
            },
          ),
        );
      }
      if (!_useFixedTotal && _periodChoices.length > 1 && _editsRateHere) {
        out.addAll([
          vGapSmall,
          ChoicePills<RatePeriod>(
            values: _periodChoices,
            selected: _period,
            label: (p) => p.label,
            onSelected: _setPeriod,
          ),
          if (_period == RatePeriod.hour) ...[
            vGapSmall,
            Text(
              'Hourly pay is earned only during your working hours, set below.',
              style: AppType.bodySmall.copyWith(color: context.colors.inkMuted),
            ),
          ],
        ]);
      }
      if (fixedTotalEditable) {
        out.addAll([
          vGap,
          Text('How the total is earned', style: AppType.label),
          vGapSmall,
          ChoicePills<FixedTotalAccrual>(
            values: FixedTotalAccrual.values,
            selected: _fixedAccrual,
            label: (a) => a.label,
            onSelected: (a) => setState(() => _fixedAccrual = a),
          ),
          vGapSmall,
          Text(switch (_fixedAccrual) {
            FixedTotalAccrual.spreadCalendarDays => 'The total is divided evenly over every day from start to end.',
            FixedTotalAccrual.spreadWorkingDays => 'The total is divided over your working days only.',
            FixedTotalAccrual.onCompletion => 'Nothing counts as earned until the last day is finished.',
          }, style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
        ]);
      }
    } else if (_kind != IncomeKind.oneTime) {
      out.add(
        InfoBanner(
          _kind == IncomeKind.variable
              ? 'To change your default monthly estimate, use "Update estimate" in Rate history on the income page.'
              : 'To change your pay, add a revision from Rate history on the income page. '
                    'This keeps past months correct.',
        ),
      );
    }

    if (_kind == IncomeKind.oneTime) {
      if (oneTimeCreate) {
        out.addAll([
          vGap,
          ToggleTile(
            title: 'I have already received it',
            subtitle: 'Marks it as earned and records the payment on the expected date.',
            value: _alreadyReceived,
            onChanged: (v) => setState(() => _alreadyReceived = v),
          ),
        ]);
      } else {
        out.add(const InfoBanner('The amount is kept under Bonuses & benefits on the income page. Edit it there.'));
      }
    }

    if (_kind == IncomeKind.salary) {
      out.addAll([
        vGap,
        MoneyField(
          controller: _takeHome,
          currency: _currency,
          label: 'Monthly take-home (optional)',
          helper: 'What usually reaches your bank after deductions. Used for reference only.',
          required: false,
        ),
      ]);
    }
    return out;
  }

  List<Widget> _policyFields(BuildContext context) => [
    ChoicePills<AccrualPolicy>(
      values: AccrualPolicy.values,
      selected: _policy,
      label: (p) => p.label,
      onSelected: _setPolicy,
    ),
    vGapSmall,
    Text(
      _policy == AccrualPolicy.calendarDay
          ? 'Your pay builds up evenly every day of the month, weekends included.'
          : 'Your pay builds up only on working days, during working hours.',
      style: AppType.bodySmall.copyWith(color: context.colors.inkMuted),
    ),
  ];

  List<Widget> _paymentRuleFields(BuildContext context) {
    final out = <Widget>[
      SelectField<PayRule>(
        key: ValueKey('rule-$_kind-$_payRule'),
        label: 'Payment day',
        value: _payRule,
        values: PayRule.values,
        itemLabel: (r) => r.label,
        helper: 'Earnings belong to the month they are earned, even when paid later.',
        onChanged: (r) => setState(() => _payRule = r),
      ),
    ];
    switch (_payRule) {
      case PayRule.dayOfMonth:
        out.addAll([
          vGap,
          SelectField<int>(
            label: 'Day of the month',
            value: _payDay,
            values: [for (var d = 1; d <= 31; d++) d],
            itemLabel: (d) => d >= 29 ? '$d (or the last day in shorter months)' : '$d',
            onChanged: (d) => setState(() => _payDay = d),
          ),
          vGap,
          _offsetField(),
        ]);
      case PayRule.lastDayOfMonth:
        out.addAll([vGap, _offsetField()]);
      case PayRule.manual:
        out.addAll([
          vGap,
          DateField(
            label: 'Expected payment date (optional)',
            initial: _expectedPayDate,
            optional: true,
            helper: _kind == IncomeKind.temporary ? 'Usually shortly after the end date.' : null,
            onChanged: (d) => setState(() => _expectedPayDate = d),
          ),
        ]);
    }
    if (_payRule != PayRule.manual) {
      out.addAll([
        vGap,
        SelectField<WeekendAdjust>(
          label: 'If payday is not a working day',
          value: _weekend,
          values: WeekendAdjust.values,
          itemLabel: (w) => w.label,
          onChanged: (w) => setState(() => _weekend = w),
        ),
      ]);
    }
    return out;
  }

  Widget _offsetField() => SelectField<int>(
    key: ValueKey('offset-$_kind-$_payOffset'),
    label: 'Which month is it paid in?',
    value: _payOffset,
    values: [for (var i = 0; i <= 12; i++) i],
    itemLabel: payOffsetLabel,
    helper: 'For example, October salary paid in November is "the following month".',
    onChanged: (v) => setState(() => _payOffset = v),
  );
}

/// Banner naming the kind of income being added or edited.
class _KindHeader extends StatelessWidget {
  const _KindHeader({required this.kind, required this.isEdit});
  final IncomeKind kind;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.orb,
            boxShadow: AppShadows.glow,
          ),
          child: Icon(IncomeVisuals.kindIcon(kind), color: AppColors.white, size: AppIconSize.md),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kind.label, style: AppType.title.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                isEdit ? 'The type cannot be changed after creation.' : 'Fill in the details below. You can edit them later.',
                style: AppType.bodySmall.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
