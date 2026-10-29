import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../authentication/application/session_controller.dart';
import 'settings_widgets.dart';

// ============================================================================
// Profile
// ============================================================================

const _locales = <String, String>{
  'en_IN': 'English (India)',
  'en_US': 'English (United States)',
  'en_GB': 'English (United Kingdom)',
  'hi_IN': 'Hindi (India)',
  'en_AU': 'English (Australia)',
  'en_CA': 'English (Canada)',
  'en_SG': 'English (Singapore)',
  'de_DE': 'German (Germany)',
  'fr_FR': 'French (France)',
};

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileStreamProvider);
    final profile = async.value;
    if (profile == null) {
      return SettingsPage(
        title: 'Profile',
        children: [
          if (async.hasError)
            ErrorState(message: 'Your profile could not be loaded.', onRetry: () => ref.invalidate(profileStreamProvider))
          else
            const LoadingState(label: 'Loading profile'),
        ],
      );
    }
    return _ProfileForm(profile: profile);
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.profile.displayName);
  late String _currency = widget.profile.currencyCode;
  late String _locale = widget.profile.locale;
  late String _timezone = widget.profile.timezone;
  late LocalDate? _dob = widget.profile.dateOfBirth;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != widget.profile.displayName ||
      _currency != widget.profile.currencyCode ||
      _locale != widget.profile.locale ||
      _timezone != widget.profile.timezone ||
      _dob != widget.profile.dateOfBirth;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = ref.read(profileStreamProvider).value ?? widget.profile;
    final ok = await runGuarded(
      context,
      () => ref.read(profileRepositoryProvider).save(current.copyWith(
            displayName: _name.text.trim(),
            currencyCode: _currency,
            locale: _locale,
            timezone: _timezone,
            dateOfBirth: _dob,
            clearDateOfBirth: _dob == null,
            updatedAt: ref.read(clockProvider).now(),
          )),
      success: 'Profile saved',
    );
    if (ok && mounted) setState(() {});
  }

  Future<void> _pickTimezone() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TimezonePicker(selected: _timezone),
    );
    if (picked != null) setState(() => _timezone = picked);
  }

  Future<void> _useDeviceTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final id = info.identifier;
      if (!mounted) return;
      if (!tz.timeZoneDatabase.locations.containsKey(id)) {
        showMessage(context, 'Your device reported "$id", which is not a recognised timezone. Choose one from the list.');
        return;
      }
      setState(() => _timezone = id);
      showMessage(context, 'Device timezone: $id');
    } on Object {
      if (mounted) showMessage(context, 'Could not read the device timezone. Choose one from the list.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currency = Currency.byCode(_currency);
    final sample = MoneyFormatter(_locale, currency).minor(123456789);
    final currencies = [
      ...Currency.supported,
      if (!Currency.supported.any((x) => x.code == _currency)) Currency.byCode(_currency),
    ];
    final locales = {..._locales, if (!_locales.containsKey(_locale)) _locale: _locale};
    final today = ref.watch(todayProvider);

    return SettingsPage(
      title: 'Profile',
      children: [
        Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SettingsGroup(title: 'You', children: [
              SettingsBlock(
                child: Column(children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Display name', counterText: ''),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  DateField(
                    label: 'Date of birth (optional)',
                    initial: _dob,
                    optional: true,
                    lastDate: today,
                    helper: 'Only used to show your age on yearly insights. Never leaves this device.',
                    onChanged: (d) => setState(() => _dob = d),
                  ),
                ]),
              ),
            ]),
            SettingsGroup(title: 'Money & region', children: [
              SettingsBlock(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SelectField<String>(
                    label: 'Currency',
                    value: _currency,
                    values: [for (final x in currencies) x.code],
                    itemLabel: (code) {
                      final x = Currency.byCode(code);
                      return '${x.code} · ${x.name} (${x.symbol})';
                    },
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                  if (_currency != widget.profile.currencyCode)
                    const NoteCard(
                      warning: true,
                      icon: Icons.warning_amber_rounded,
                      message: 'Existing income sources keep their own currency — nothing is converted. '
                          'Totals, the dashboard and forecasts only include sources in your profile currency, '
                          'so sources in the old currency will stop appearing in totals until you switch back.',
                    ),
                  const SizedBox(height: AppSpace.lg),
                  SelectField<String>(
                    label: 'Number format',
                    value: _locale,
                    values: locales.keys.toList(),
                    itemLabel: (l) => locales[l]!,
                    helper: 'Example: $sample',
                    onChanged: (v) => setState(() => _locale = v),
                  ),
                ]),
              ),
            ]),
            SettingsGroup(
              title: 'Financial timezone',
              footer: 'Historical earnings are stored as calendar dates and are never rewritten when you change '
                  'this. Only the live "earned so far today" counter and what counts as "today" use this zone.',
              children: [
                SettingsTile(
                  icon: Icons.public_rounded,
                  tone: SettingsTone.sky,
                  title: _timezone.replaceAll('_', ' '),
                  subtitle: 'Tap to choose a timezone',
                  onTap: _pickTimezone,
                ),
                SettingsTile(
                  icon: Icons.my_location_rounded,
                  tone: SettingsTone.mint,
                  title: 'Use device timezone',
                  chevron: false,
                  onTap: _useDeviceTimezone,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            BusyButton(label: 'Save profile', accent: true, onPressed: _dirty ? _save : null),
            if (!_dirty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Text('No unsaved changes',
                    textAlign: TextAlign.center, style: AppType.caption.copyWith(color: c.inkMuted)),
              ),
          ]),
        ),
      ],
    );
  }
}

class _TimezonePicker extends StatefulWidget {
  const _TimezonePicker({required this.selected});
  final String selected;

  @override
  State<_TimezonePicker> createState() => _TimezonePickerState();
}

class _TimezonePickerState extends State<_TimezonePicker> {
  late final List<String> _all = tz.timeZoneDatabase.locations.keys.toList()..sort();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase().replaceAll(' ', '_');
    final list = q.isEmpty ? _all : _all.where((z) => z.toLowerCase().contains(q)).toList();
    final c = context.colors;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.md),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search timezones',
                hintText: 'e.g. Kolkata, London, New_York',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('No matching timezone', style: AppType.body.copyWith(color: c.inkMuted)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final z = list[i];
                      final loc = tz.getLocation(z);
                      final offset = tz.TZDateTime.now(loc).timeZoneOffset;
                      return ListTile(
                        minTileHeight: 52,
                        title: Text(z.replaceAll('_', ' '), style: AppType.label),
                        subtitle: Text(_formatOffset(offset), style: AppType.bodySmall),
                        trailing: z == widget.selected ? Icon(Icons.check_circle_rounded, color: c.accentText) : null,
                        onTap: () => Navigator.pop(context, z),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  static String _formatOffset(Duration d) {
    final sign = d.isNegative ? '−' : '+';
    final m = d.inMinutes.abs();
    return 'UTC$sign${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// Appearance
// ============================================================================

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appearanceProvider);
    Future<void> save(AppearanceSettings next) =>
        runGuarded(context, () => ref.read(settingsControllerProvider).saveAppearance(next));
    final osReduced = MediaQuery.disableAnimationsOf(context);

    return SettingsPage(
      title: 'Appearance',
      children: [
        SettingsGroup(title: 'Theme', children: [
          SettingsBlock(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final (i, m) in AppThemeMode.values.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.sm + 2),
                Expanded(
                  child: _ThemeOption(
                    mode: m,
                    selected: s.themeMode == m,
                    onTap: () => save(s.copyWith(themeMode: m)),
                  ),
                ),
              ],
            ]),
          ),
        ]),
        SettingsGroup(
          title: 'Motion',
          footer: osReduced
              ? 'Your device already asks apps to reduce motion, so animations are minimised regardless of this switch.'
              : 'EarnLens also respects the "remove animations" setting of your device.',
          children: [
            SettingsSwitch(
              icon: Icons.motion_photos_off_outlined,
              tone: SettingsTone.sky,
              title: 'Reduce motion',
              subtitle: 'Turn off chart and counter animations',
              value: s.reduceMotion,
              onChanged: (v) => save(s.copyWith(reduceMotion: v)),
            ),
          ],
        ),
        SettingsGroup(title: 'Text size', children: [
          SettingsBlock(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SettingsIcon(Icons.format_size_rounded, tone: SettingsTone.mint),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Text size follows your device\'s font size setting. Change it in your system accessibility '
                  'settings and EarnLens will adapt.',
                  style: AppType.body.copyWith(color: context.colors.ink),
                ),
              ),
            ]),
          ),
        ]),
      ],
    );
  }
}

/// Theme choice with a miniature preview of the app in that theme.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.mode, required this.selected, required this.onTap});
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
    final icon = switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_rounded,
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: mode == AppThemeMode.system ? 'Match system theme' : '$label theme',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          AnimatedContainer(
            duration: reduce ? Duration.zero : AppDurations.medium,
            curve: AppCurves.emphasized,
            padding: const EdgeInsets.all(5),
            decoration: ShapeDecoration(
              shape: BlobBorder(
                BlobSpec(seed: 60 + mode.index, radius: 26, wobble: 0.4, wave: 1.4),
                side: BorderSide(color: selected ? c.accentText : c.line, width: selected ? 2 : 1),
              ),
              shadows: selected ? AppShadows.card(Theme.of(context).brightness) : null,
            ),
            child: ClipPath(
              // A calmer inner silhouette so the preview never pokes past the outline.
              clipper: ShapeBorderClipper(
                shape: BlobBorder(BlobSpec(seed: 60 + mode.index, radius: 20, wobble: 0.25, wave: 1)),
              ),
              child: AspectRatio(
                aspectRatio: 0.82,
                child: switch (mode) {
                  AppThemeMode.light => const _MiniPreview(dark: false),
                  AppThemeMode.dark => const _MiniPreview(dark: true),
                  AppThemeMode.system => const Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: _MiniPreview(dark: false, half: true)),
                      Expanded(child: _MiniPreview(dark: true, half: true)),
                    ]),
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm + 2),
          AnimatedContainer(
            duration: reduce ? Duration.zero : AppDurations.medium,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? c.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? Icons.check_circle_rounded : icon, size: 16, color: selected ? c.accentText : c.inkMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(
                    color: selected ? c.accentText : c.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Tiny abstract rendering of the dashboard: background, hero, two cards.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.dark, this.half = false});
  final bool dark;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkBackground : AppColors.pageLight;
    final card = dark ? AppColors.darkSurfaceHigh : AppColors.white;
    final line = dark ? AppColors.darkLine : AppColors.line;
    Widget bar(double w, Color color) => FractionallySizedBox(
          widthFactor: w,
          alignment: Alignment.centerLeft,
          child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        );
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(half ? 5 : 8, 8, half ? 5 : 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          bar(0.5, line),
          const SizedBox(height: 6),
          Expanded(
            flex: 5,
            child: Container(
              decoration: const ShapeDecoration(
                gradient: AppGradients.hero,
                shape: BlobBorder(BlobSpec(seed: 1, radius: 9, wobble: 0.5, wave: 1)),
              ),
              padding: const EdgeInsets.all(5),
              alignment: Alignment.bottomLeft,
              child: bar(0.6, AppColors.white.withValues(alpha: 0.85)),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            flex: 3,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Container(
                  decoration: ShapeDecoration(
                    color: dark ? AppColors.violet.withValues(alpha: 0.3) : AppColors.lilacSoft,
                    shape: const BlobBorder(BlobSpec(seed: 2, radius: 7, wobble: 0.5, wave: 0.8)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  decoration: ShapeDecoration(
                    color: dark ? AppColors.peach.withValues(alpha: 0.3) : AppColors.peachSoft,
                    shape: const BlobBorder(BlobSpec(seed: 3, radius: 7, wobble: 0.5, wave: 0.8)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 5),
          Expanded(
            flex: 2,
            child: Container(
              decoration: ShapeDecoration(
                color: card,
                shape: const BlobBorder(BlobSpec(seed: 4, radius: 7, wobble: 0.5, wave: 0.8)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================================
// Calculation
// ============================================================================

class CalculationSettingsScreen extends ConsumerWidget {
  const CalculationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculationSettingsProvider);
    final dash = ref.watch(dashboardConfigProvider);
    final c = context.colors;
    final schedule = calc.defaultSchedule;
    final controller = ref.read(settingsControllerProvider);

    Future<void> saveCalc(CalculationSettings next) => runGuarded(context, () => controller.saveCalculation(next));
    Future<void> saveDash(DashboardConfig next) => runGuarded(context, () => controller.saveDashboard(next));

    Future<void> saveSchedule(WorkSchedule next) async {
      if (next.weekdays.isEmpty) {
        showMessage(context, 'Choose at least one working day.');
        return;
      }
      if (next.endMinute <= next.startMinute) {
        showMessage(context, 'The working day must end after it starts.');
        return;
      }
      await saveCalc(calc.copyWith(defaultSchedule: next));
    }

    final hours = schedule.workingMinutesPerDay / 60;
    final hoursLabel = hours == hours.roundToDouble() ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);

    return SettingsPage(
      title: 'Earnings calculation',
      children: [
        const NoteCard(
          message: 'These are defaults for new income sources and how rates are displayed. Each source keeps its '
              'own rules, which you can change on the source itself. Changing defaults never rewrites history.',
        ),
        SettingsGroup(
          title: 'Default pay spreading',
          footer: 'Every calendar day: a monthly salary is spread evenly over all days of the month, weekends '
              'included — this is how most employers pro-rate salary. Working days only: pay accrues only during '
              'your working hours on working days.',
          children: [
            SettingsBlock(
              child: ChoicePills<AccrualPolicy>(
                values: AccrualPolicy.values,
                selected: calc.defaultPolicy,
                label: (p) => p.label,
                onSelected: (p) => saveCalc(calc.copyWith(defaultPolicy: p)),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Default working week',
          footer: 'Used for working-day pay, hourly rates in "working hours only" mode and to pre-fill new sources. '
              '$hoursLabel hours a day.',
          children: [
            SettingsBlock(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(weekdayShort[d - 1]),
                    selected: schedule.weekdays.contains(d),
                    labelStyle: AppType.label.copyWith(
                      color: schedule.weekdays.contains(d) ? c.accentText : c.ink,
                      fontWeight: schedule.weekdays.contains(d) ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                        color: schedule.weekdays.contains(d) ? c.accentText.withValues(alpha: 0.4) : c.line),
                    onSelected: (on) {
                      final days = {...schedule.weekdays};
                      on ? days.add(d) : days.remove(d);
                      saveSchedule(schedule.copyWith(weekdays: days));
                    },
                  ),
              ]),
            ),
            SettingsTile(
              icon: Icons.login_rounded,
              tone: SettingsTone.mint,
              title: 'Work starts',
              value: formatMinuteOfDay(schedule.startMinute),
              onTap: () async {
                final m = await pickMinuteOfDay(context, schedule.startMinute);
                if (m != null) await saveSchedule(schedule.copyWith(startMinute: m));
              },
            ),
            SettingsTile(
              icon: Icons.logout_rounded,
              tone: SettingsTone.peach,
              title: 'Work ends',
              value: formatMinuteOfDay(schedule.endMinute),
              onTap: () async {
                final m = await pickMinuteOfDay(context, schedule.endMinute);
                if (m != null) await saveSchedule(schedule.copyWith(endMinute: m));
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Month-end reminder',
          footer: 'When to remind you to review the month and record actual variable income.',
          children: [
            SettingsTile(
              icon: Icons.event_note_outlined,
              tone: SettingsTone.sky,
              title: _monthEndLabel(calc.monthEndReminderDay),
              subtitle: 'Tap to change',
              onTap: () async {
                final v = await pickOption<int>(
                  context,
                  title: 'Remind me',
                  values: const [0, 1, 2, 3, 5, 7],
                  selected: calc.monthEndReminderDay,
                  label: _monthEndLabel,
                );
                if (v != null) await saveCalc(calc.copyWith(monthEndReminderDay: v));
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Hourly, per-minute and per-second rates',
          footer: dash.rateBasis == RateBasis.calendarTime
              ? 'Around the clock: weekly pay is divided by all 168 hours of the week, so per-hour figures match '
                  'the live counter for calendar-day salaries. A calendar-day salary is never mixed with an 8-hour day.'
              : 'Working hours only: weekly pay is divided by your scheduled working hours, so per-hour figures '
                  'show what an hour of work is worth. The live counter itself still follows each source\'s rules.',
          children: [
            SettingsBlock(
              child: ChoicePills<RateBasis>(
                values: RateBasis.values,
                selected: dash.rateBasis,
                label: (b) => b.label,
                onSelected: (b) => saveDash(dash.copyWith(rateBasis: b)),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Display precision',
          footer: 'Decimal places for small rates and the live counter. Stored amounts are always exact; '
              'this only affects display.',
          children: [
            SettingsBlock(
              child: Row(children: [
                Expanded(
                  child: Slider(
                    value: dash.precision.toDouble(),
                    min: 0,
                    max: 6,
                    divisions: 6,
                    label: '${dash.precision}',
                    semanticFormatterCallback: (v) => '${v.round()} decimal places',
                    onChanged: (v) {
                      if (v.round() != dash.precision) saveDash(dash.copyWith(precision: v.round()));
                    },
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    '0.${'0' * dash.precision}'.replaceAll(RegExp(r'\.$'), ''),
                    textAlign: TextAlign.end,
                    style: AppType.label,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  static String _monthEndLabel(int d) => switch (d) {
        0 => 'On the last day of the month',
        1 => '1 day before month end',
        _ => '$d days before month end',
      };
}

// ============================================================================
// Security
// ============================================================================

final _biometricAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (kIsWeb) return false;
  try {
    return await ref.watch(biometricServiceProvider).isAvailable();
  } on Object {
    return false;
  }
});

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(securitySettingsProvider);
    final pin = ref.watch(pinConfiguredProvider);
    final bio = ref.watch(_biometricAvailableProvider);
    final controller = ref.read(settingsControllerProvider);
    Future<void> save(SecuritySettings next) => runGuarded(context, () => controller.saveSecurity(next));

    Future<void> toggleBiometrics(bool on) async {
      if (!on) {
        await save(s.copyWith(biometricsEnabled: false));
        return;
      }
      bool ok;
      try {
        ok = await ref.read(biometricServiceProvider).authenticate('Confirm to enable biometric unlock');
      } on Object {
        ok = false;
      }
      if (!context.mounted) return;
      if (!ok) {
        showMessage(context, 'Biometric check did not succeed, so biometric unlock was not turned on.');
        return;
      }
      await save(s.copyWith(biometricsEnabled: true));
    }

    final bioAvailable = bio.value ?? false;
    final String bioSubtitle;
    if (kIsWeb) {
      bioSubtitle = 'Not available in the browser version';
    } else if (!pin) {
      bioSubtitle = 'Set up a PIN first';
    } else if (bio.isLoading) {
      bioSubtitle = 'Checking this device…';
    } else if (!bioAvailable) {
      bioSubtitle = 'No fingerprint or face unlock is set up on this device';
    } else {
      bioSubtitle = 'Unlock with fingerprint or face instead of your PIN';
    }

    return SettingsPage(
      title: 'Security',
      children: [
        const SizedBox(height: AppSpace.sm),
        EntranceScale(
          child: _SecurityStatus(
            protected: pin,
            biometrics: s.biometricsEnabled && bioAvailable && pin,
            privacy: s.privacyMode,
          ),
        ),
        SettingsGroup(title: 'App lock', children: [
          SettingsTile(
            icon: Icons.pin_outlined,
            title: pin ? 'Change PIN' : 'Set up a PIN',
            subtitle: pin ? 'A PIN is required to open EarnLens' : 'Anyone with your phone can open EarnLens',
            onTap: () => context.go('/settings/security/change-pin'),
          ),
          SettingsSwitch(
            icon: Icons.fingerprint_rounded,
            tone: SettingsTone.mint,
            title: 'Biometric unlock',
            subtitle: bioSubtitle,
            value: s.biometricsEnabled && bioAvailable && pin,
            onChanged: (!kIsWeb && pin && bioAvailable) ? toggleBiometrics : null,
          ),
          SettingsTile(
            icon: Icons.timer_outlined,
            tone: SettingsTone.sky,
            title: 'Auto-lock',
            subtitle: pin ? 'Ask for the PIN after leaving the app' : 'Needs a PIN',
            value: pin ? s.autoLock.label : null,
            onTap: pin
                ? () async {
                    final v = await pickOption<AutoLock>(
                      context,
                      title: 'Lock EarnLens',
                      values: AutoLock.values,
                      selected: s.autoLock,
                      label: (a) => a.label,
                    );
                    if (v != null) await save(s.copyWith(autoLock: v));
                  }
                : null,
          ),
          if (pin)
            SettingsTile(
              icon: Icons.lock_rounded,
              tone: SettingsTone.peach,
              title: 'Lock now',
              chevron: false,
              onTap: () => ref.read(sessionProvider.notifier).lock(),
            ),
        ]),
        SettingsGroup(title: 'Privacy', children: [
          SettingsSwitch(
            icon: Icons.visibility_off_outlined,
            title: 'Privacy mode',
            subtitle: 'Hide amounts until you tap to show them, and hide the app preview in recent apps',
            value: s.privacyMode,
            onChanged: (v) => save(s.copyWith(privacyMode: v)),
          ),
          SettingsSwitch(
            icon: Icons.widgets_outlined,
            tone: SettingsTone.sky,
            title: 'Hide amounts on home-screen widget',
            subtitle: 'The widget shows your progress without figures',
            value: s.hideAmountsOnWidget,
            onChanged: (v) => save(s.copyWith(hideAmountsOnWidget: v)),
          ),
        ]),
        const NoteCard(
          icon: Icons.shield_outlined,
          message: 'Your PIN protects access to the app, but it does not encrypt the database stored on this '
              'device. To protect copies of your data, create password-encrypted backups (AES-256) from '
              'Settings › Data management.',
        ),
      ],
    );
  }
}

/// Purple status card summarising how EarnLens is protected.
class _SecurityStatus extends StatelessWidget {
  const _SecurityStatus({required this.protected, required this.biometrics, required this.privacy});
  final bool protected;
  final bool biometrics;
  final bool privacy;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: on ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(on ? Icons.check_rounded : icon, size: 14, color: AppColors.white.withValues(alpha: on ? 1 : 0.7)),
            const SizedBox(width: 4),
            Text(label, style: AppType.caption.copyWith(color: AppColors.white.withValues(alpha: on ? 1 : 0.75))),
          ]),
        );
    return EarnCard(
      accent: protected,
      dark: !protected,
      semanticLabel: protected ? 'EarnLens is protected with a PIN' : 'EarnLens is not protected with a PIN',
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BlobBadge(
          size: 48,
          seed: 7,
          color: AppColors.white.withValues(alpha: 0.2),
          child: Icon(protected ? Icons.verified_user_rounded : Icons.gpp_maybe_outlined, color: AppColors.white),
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(protected ? 'Protected' : 'Not protected',
                style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              protected ? 'A PIN is needed to open EarnLens.' : 'Set up a PIN so only you can open EarnLens.',
              style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.md),
            Wrap(spacing: 6, runSpacing: 6, children: [
              chip(Icons.pin_outlined, 'PIN', protected),
              chip(Icons.fingerprint_rounded, 'Biometrics', biometrics),
              chip(Icons.visibility_off_outlined, 'Privacy mode', privacy),
            ]),
          ]),
        ),
      ]),
    );
  }
}
