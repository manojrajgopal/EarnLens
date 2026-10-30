import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/financial_calendar.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../authentication/application/session_controller.dart';
import '../../authentication/presentation/pin_pad.dart';
import '../../notifications/domain/notification_models.dart';
import '../../settings/presentation/settings_widgets.dart';

const supportedLocales = {
  'en_IN': 'English (India) — 1,00,000.00',
  'en_US': 'English (US) — 100,000.00',
  'en_GB': 'English (UK) — 100,000.00',
  'hi_IN': 'हिन्दी (भारत)',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.withSampleData = false});
  final bool withSampleData;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  // Profile
  final _profileForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  Currency _currency = Currency.inr;
  String _locale = 'en_IN';
  late String _timezone = ref.read(deviceTimezoneProvider);
  LocalDate? _dob;

  // Units
  var _dashboard = DashboardConfig.defaults();

  // First income
  final _incomeForm = GlobalKey<FormState>();
  bool _addIncome = true;
  final _employer = TextEditingController();
  final _salary = TextEditingController();
  late LocalDate _joining = LocalDate(ref.read(todayProvider).year, ref.read(todayProvider).month, 1);
  int _payDay = 1;
  bool _paidNextMonth = true;

  // Security & extras
  bool _pinSet = false;
  bool _biometricAvailable = false;
  bool _biometrics = false;
  bool _notifications = false;

  static const _titles = ['About you', 'How you see earnings', 'Your first income', 'Protect EarnLens', 'Finishing touches'];

  @override
  void initState() {
    super.initState();
    _addIncome = !widget.withSampleData;
    ref.read(biometricServiceProvider).isAvailable().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _employer.dispose();
    _salary.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && !(_profileForm.currentState?.validate() ?? false)) return;
    if (_step == 2 && _addIncome && !(_incomeForm.currentState?.validate() ?? false)) return;
    if (_step == _titles.length - 1) return;
    // Close the keyboard: the next page has no field that wants it, and an
    // open keyboard would cover that page's content.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step++);
    _page.animateToPage(_step,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
        curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_step == 0) {
      context.go('/welcome');
      return;
    }
    setState(() => _step--);
    _page.animateToPage(_step,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
        curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    final clock = ref.read(clockProvider);
    final ids = ref.read(idProvider);
    final now = clock.now();
    final settings = ref.read(settingsControllerProvider);
    final calendar = FinancialCalendar(tz.getLocation(_timezone));
    final today = calendar.today(now);

    // Everything entered here belongs to the first account.
    final accounts = ref.read(accountRepositoryProvider);
    var account = (await accounts.accounts()).firstOrNull;
    if (account == null) {
      account = Account(
        id: ids.newId(),
        name: AccountType.personal.label,
        type: AccountType.personal,
        currencyCode: _currency.code,
        createdAt: now,
        updatedAt: now,
      );
      await accounts.createAccount(account);
    }
    final accountId = account.id;
    ref.read(selectedViewProvider.notifier).select(IndividualView(accountId));
    await ref.read(settingsRepositoryProvider).write(SettingsKeys.activeView, IndividualView(accountId).toJson());
    final accountSettings = ref.read(accountSettingsControllerProvider(accountId));

    await accountSettings.saveDashboard(_dashboard);
    await settings.saveSecurity(SecuritySettings(biometricsEnabled: _biometrics && _pinSet));
    await accountSettings.saveNotifications(NotificationSettings(masterEnabled: _notifications));

    if (_addIncome) {
      final minor = parseMoney(_salary, _currency)!;
      final source = IncomeSource(
        id: ids.newId(),
        name: _employer.text.trim(),
        employer: _employer.text.trim(),
        kind: IncomeKind.salary,
        category: IncomeCategory.salary,
        currencyCode: _currency.code,
        startDate: _joining,
        payDay: _payDay,
        payOffsetMonths: _paidNextMonth ? 1 : 0,
        schedule: ref.read(accountCalculationSettingsProvider(accountId)).defaultSchedule,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(accountIncomeRepositoryProvider(accountId)).createSource(
            source,
            initialRate: RateRevision(
              id: ids.newId(),
              sourceId: source.id,
              effectiveFrom: _joining,
              amountMinor: minor,
              period: RatePeriod.month,
              changeType: RevisionChangeType.initial,
              createdAt: now,
            ),
          );
    }
    if (widget.withSampleData) {
      await ref.read(accountSampleDataServiceProvider(accountId)).insert(currencyCode: _currency.code, today: today);
    }

    // Saving the completed profile last makes the router leave onboarding.
    ref.read(sessionProvider.notifier).unlock();
    await ref.read(profileRepositoryProvider).save(UserProfile(
          displayName: _name.text.trim(),
          currencyCode: _currency.code,
          locale: _locale,
          timezone: _timezone,
          dateOfBirth: _dob,
          onboardingComplete: true,
          createdAt: now,
          updatedAt: now,
        ));
  }

  static const _icons = [
    (Icons.person_outline_rounded, SettingsTone.violet),
    (Icons.speed_rounded, SettingsTone.sky),
    (Icons.work_outline_rounded, SettingsTone.mint),
    (Icons.lock_outline_rounded, SettingsTone.violet),
    (Icons.auto_awesome_outlined, SettingsTone.peach),
  ];

  Future<void> _skipPin() async {
    final ok = await confirmDialog(
      context,
      title: 'Skip the PIN?',
      message: 'Anyone with your unlocked device could open EarnLens. You can add a PIN later in Settings › Security.',
      confirm: 'Skip',
    );
    if (ok) _next();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EarnBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(children: [
                    IconButton(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(backgroundColor: c.card, minimumSize: const Size(48, 48)),
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _back,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Semantics(
                        label: 'Step ${_step + 1} of ${_titles.length}',
                        excludeSemantics: true,
                        child: Row(children: [
                          for (var i = 0; i < _titles.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedContainer(
                                duration: reduce ? Duration.zero : AppDurations.medium,
                                curve: AppCurves.emphasized,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: i <= _step ? AppGradients.orb : null,
                                  color: i <= _step ? null : c.accentSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ExcludeSemantics(
                      child: Text('${_step + 1}/${_titles.length}',
                          style: AppType.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                Expanded(
                  child: PageView(
                    controller: _page,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_profileStep(), _unitsStep(), _incomeStep(), _pinStep(), _extrasStep()],
                  ),
                ),
                // Pinned outside the scrolling step so the primary action stays
                // visible above the keyboard.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, AppSpace.sm, 24, AppSpace.lg),
                  child: _footer(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    Widget primary(String label) => GradientButton(
          onPressed: _next,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ]),
        );
    return switch (_step) {
      2 when !widget.withSampleData && !_addIncome => SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: _next, child: const Text('Skip for now')),
        ),
      3 when !_pinSet => SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: _skipPin,
            child: const Text('Skip for now'),
          ),
        ),
      4 => BusyButton(label: 'Open my dashboard', accent: true, onPressed: _finish),
      _ => SizedBox(width: double.infinity, child: primary('Continue')),
    };
  }

  Widget _stepScaffold({required int step, required String subtitle, required List<Widget> children}) {
    final c = context.colors;
    final (icon, tone) = _icons[step];
    // Not lazy: every field of the step is built so validation sees it.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerLeft, child: SettingsIcon(icon, tone: tone)),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(_titles[step], style: AppType.headlineLight.copyWith(color: c.ink)),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppType.body.copyWith(color: c.inkMuted)),
        const SizedBox(height: 24),
        ...children,
      ]),
    );
  }

  Widget _profileStep() {
    final zones = tz.timeZoneDatabase.locations.keys.toList()..sort();
    return Form(
      key: _profileForm,
      child: _stepScaffold(
        step: 0,
        subtitle: 'Only what is useful. You can change all of this later in Settings.',
        children: [
          EarnCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'What should we call you?'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              SelectField<Currency>(
                label: 'Currency',
                value: _currency,
                values: Currency.supported,
                itemLabel: (c) => '${c.symbol}  ${c.name} (${c.code})',
                onChanged: (v) => setState(() => _currency = v),
              ),
              const SizedBox(height: 16),
              SelectField<String>(
                label: 'Number format',
                value: _locale,
                values: supportedLocales.keys.toList(),
                itemLabel: (l) => supportedLocales[l]!,
                onChanged: (v) => setState(() => _locale = v),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _timezone),
                optionsBuilder: (v) => v.text.isEmpty
                    ? zones.take(50)
                    : zones.where((z) => z.toLowerCase().contains(v.text.toLowerCase())).take(50),
                onSelected: (z) => setState(() => _timezone = z),
                fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
                  controller: controller,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    labelText: 'Financial timezone',
                    helperText: 'Used to decide when each day starts for your earnings.',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                  validator: (v) => zones.contains(v) ? null : 'Pick a timezone from the list',
                  onChanged: (v) {
                    if (zones.contains(v)) _timezone = v;
                  },
                ),
              ),
              const SizedBox(height: 16),
              DateField(
                label: 'Date of birth (optional)',
                helper: 'Only stored on this device. Leave empty if you prefer.',
                optional: true,
                initial: _dob,
                lastDate: ref.read(todayProvider),
                onChanged: (d) => _dob = d,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _unitsStep() {
    final c = context.colors;
    return _stepScaffold(
      step: 1,
      subtitle: 'Pick the earning rates you want on your dashboard. At least one is always shown.',
      children: [
        EarnCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Show these rates', style: AppType.section.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final u in EarningUnit.values)
                FilterChip(
                  label: Text(u.label),
                  selected: _dashboard.units.contains(u),
                  avatar: _dashboard.units.contains(u)
                      ? Icon(Icons.check_rounded, size: 16, color: c.accentText)
                      : null,
                  labelStyle: AppType.label.copyWith(
                    color: _dashboard.units.contains(u) ? c.accentText : c.ink,
                    fontWeight: _dashboard.units.contains(u) ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                      color: _dashboard.units.contains(u) ? c.accentText.withValues(alpha: 0.4) : c.line),
                  onSelected: (_) => setState(() {
                    final units = [..._dashboard.units];
                    if (units.contains(u)) {
                      if (units.length > 1) units.remove(u);
                    } else {
                      units.add(u);
                    }
                    units.sort((a, b) => a.index.compareTo(b.index));
                    _dashboard = _dashboard.copyWith(
                      units: units,
                      primaryUnit: units.contains(_dashboard.primaryUnit) ? _dashboard.primaryUnit : units.first,
                    );
                  }),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        EarnCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Main rate', style: AppType.section.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Shown largest on your dashboard.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            const SizedBox(height: 12),
            ChoicePills<EarningUnit>(
              values: _dashboard.units,
              selected: _dashboard.primaryUnit,
              label: (u) => u.label,
              onSelected: (u) => setState(() => _dashboard = _dashboard.copyWith(primaryUnit: u)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _incomeStep() {
    if (widget.withSampleData) {
      return _stepScaffold(
        step: 2,
        subtitle: 'You chose to explore with sample data. Sample sources are marked "Sample" and can be removed '
            'from Settings › Data. You can add your real income at any time.',
        children: const [],
      );
    }
    return Form(
      key: _incomeForm,
      child: _stepScaffold(
        step: 2,
        subtitle: 'Add your salary now, or skip and add any kind of income later — freelance, business, rent and more.',
        children: [
          EarnCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SettingsSwitch(
              icon: Icons.account_balance_wallet_outlined,
              tone: SettingsTone.mint,
              title: 'Add my salary',
              value: _addIncome,
              onChanged: (v) => setState(() => _addIncome = v),
            ),
          ),
          if (_addIncome) ...[
            const SizedBox(height: 16),
            EarnCard(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(
                  controller: _employer,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Employer'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the employer name' : null,
                ),
                const SizedBox(height: 16),
                MoneyField(controller: _salary, currency: _currency, label: 'Monthly gross salary'),
                const SizedBox(height: 16),
                DateField(
                  label: 'Joining date',
                  initial: _joining,
                  helper: 'Earnings are counted from this date.',
                  onChanged: (d) => setState(() => _joining = d ?? _joining),
                ),
                const SizedBox(height: 16),
                SelectField<int>(
                  label: 'Salary is paid on day',
                  value: _payDay,
                  values: [for (var i = 1; i <= 31; i++) i],
                  itemLabel: (d) => '$d',
                  helper: 'Short months use their last day.',
                  onChanged: (v) => setState(() => _payDay = v),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text('Paid in the following month',
                      style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('e.g. October salary arrives in November. It still counts as October earnings.'),
                  value: _paidNextMonth,
                  onChanged: (v) => setState(() => _paidNextMonth = v),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pinStep() => _stepScaffold(
        step: 3,
        subtitle: 'A PIN keeps others from opening EarnLens on this device. It is stored only as a salted hash.',
        children: [
          if (_pinSet)
            EntranceScale(
              child: EarnCard(
                accent: true,
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PIN created',
                          style: AppType.section.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('You will enter it each time you open EarnLens.',
                          style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                    ]),
                  ),
                ]),
              ),
            )
          else
            PinSetupFlow(
              keySize: 64,
              dense: true,
              onCreated: (pin) async {
                await ref.read(pinServiceProvider).setPin(pin);
                ref.read(pinConfiguredProvider.notifier).set(true);
                if (mounted) setState(() => _pinSet = true);
              },
            ),
        ],
      );

  Widget _extrasStep() {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _stepScaffold(
      step: 4,
      subtitle: 'Optional. Everything here can be changed later.',
      children: [
        EarnCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            if (_biometricAvailable && _pinSet) ...[
              SettingsSwitch(
                icon: Icons.fingerprint_rounded,
                tone: SettingsTone.mint,
                title: 'Unlock with biometrics',
                subtitle: 'Use your fingerprint or face instead of typing the PIN.',
                value: _biometrics,
                onChanged: (v) async {
                  if (v && !await ref.read(biometricServiceProvider).authenticate('Enable biometric unlock')) return;
                  setState(() => _biometrics = v);
                },
              ),
              Divider(height: 1, indent: 18, endIndent: 18, color: c.line),
            ],
            SettingsSwitch(
              icon: Icons.notifications_active_outlined,
              tone: SettingsTone.peach,
              title: 'Payment reminders',
              subtitle: 'Paydays, overdue payments and month-end reviews, as local notifications.',
              value: _notifications,
              onChanged: (v) async {
                if (!v) return setState(() => _notifications = false);
                final p = await ref.read(notificationProviderProvider).requestPermission();
                if (!mounted) return;
                if (p == NotificationPermission.granted) {
                  setState(() => _notifications = true);
                } else {
                  showMessage(context, p == NotificationPermission.unsupported
                      ? 'Notifications are not supported on this platform.'
                      : 'Permission was not granted. You can enable it later in Settings.');
                }
              },
            ),
          ]),
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: dark ? AppColors.sky.withValues(alpha: 0.14) : AppColors.skySoft,
              shape: BlobBorder(BlobShapes.cloud(23, radius: 24, wobble: 0.45)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SettingsIcon(Icons.widgets_outlined, tone: SettingsTone.sky),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Home-screen widget: long-press your home screen, choose Widgets, and add "EarnLens". '
                  'It shows your earnings and refreshes about every 30 minutes.',
                  style: AppType.bodySmall.copyWith(color: c.ink),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
