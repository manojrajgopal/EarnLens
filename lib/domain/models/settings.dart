import '../calculation/rate_calculator.dart';
import 'enums.dart';
import 'income_source.dart';

/// Preferences are persisted per section as JSON (see SettingsRepository).
/// Every `fromJson` tolerates missing keys so older backups still load.

enum CounterRange {
  today,
  month,
  year;

  String get label => switch (this) {
        today => 'Today',
        month => 'This month',
        year => 'This year',
      };
}

enum DashboardCardType {
  liveCounter,
  lifetime,
  rates,
  monthToDate,
  today,
  expectedVsActual,
  sources,
  trend,
  breakdown,
  upcomingPayments,
  outstanding,
  forecast,
  bonuses,
  yearly,
  growth,
  recentTransactions,
  calendarPreview;

  String get label => switch (this) {
        liveCounter => 'Live earnings counter',
        lifetime => 'Lifetime earnings',
        rates => 'Earning rates',
        monthToDate => 'Month to date',
        today => "Today's earnings",
        expectedVsActual => 'Expected vs actual',
        sources => 'Income sources',
        trend => 'Monthly trend',
        breakdown => 'Income breakdown',
        upcomingPayments => 'Upcoming payments',
        outstanding => 'Outstanding income',
        forecast => 'Forecast',
        bonuses => 'Bonuses',
        yearly => 'Yearly comparison',
        growth => 'Income growth',
        recentTransactions => 'Recent transactions',
        calendarPreview => 'This week',
      };

  /// Cards that can be filtered to specific income sources.
  bool get supportsSourceFilter => this != recentTransactions && this != calendarPreview;
}

enum CardSize { compact, large }

class DashboardCardConfig {
  const DashboardCardConfig({
    required this.type,
    this.visible = true,
    this.size = CardSize.large,
    this.sourceIds,
  });

  factory DashboardCardConfig.fromJson(Map<String, dynamic> j) => DashboardCardConfig(
        type: enumByName(DashboardCardType.values, j['type'] as String?, DashboardCardType.liveCounter),
        visible: j['visible'] as bool? ?? true,
        size: enumByName(CardSize.values, j['size'] as String?, CardSize.large),
        sourceIds: (j['sourceIds'] as List?)?.cast<String>().toSet(),
      );

  final DashboardCardType type;
  final bool visible;
  final CardSize size;

  /// Null means all sources.
  final Set<String>? sourceIds;

  DashboardCardConfig copyWith({bool? visible, CardSize? size, Set<String>? sourceIds, bool allSources = false}) =>
      DashboardCardConfig(
        type: type,
        visible: visible ?? this.visible,
        size: size ?? this.size,
        sourceIds: allSources ? null : (sourceIds ?? this.sourceIds),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'visible': visible,
        'size': size.name,
        if (sourceIds != null) 'sourceIds': sourceIds!.toList(),
      };
}

class DashboardConfig {
  const DashboardConfig({
    required this.units,
    required this.primaryUnit,
    required this.cards,
    this.precision = 2,
    this.compact = false,
    this.rateBasis = RateBasis.calendarTime,
    this.counterRange = CounterRange.month,
  });

  factory DashboardConfig.defaults() => DashboardConfig(
        units: const [EarningUnit.second, EarningUnit.day, EarningUnit.month],
        // Per second is the main rate until the user picks another one.
        primaryUnit: EarningUnit.second,
        cards: [
          for (final t in DashboardCardType.values)
            DashboardCardConfig(
              type: t,
              visible: const {
                DashboardCardType.liveCounter,
                DashboardCardType.lifetime,
                DashboardCardType.rates,
                DashboardCardType.expectedVsActual,
                DashboardCardType.sources,
                DashboardCardType.trend,
                DashboardCardType.upcomingPayments,
                DashboardCardType.recentTransactions,
              }.contains(t),
            ),
        ],
      );

  factory DashboardConfig.fromJson(Map<String, dynamic> j) {
    final d = DashboardConfig.defaults();
    final units = [
      for (final n in (j['units'] as List? ?? const []))
        if (EarningUnit.values.any((u) => u.name == n)) EarningUnit.values.byName(n as String),
    ];
    final cards = [
      for (final c in (j['cards'] as List? ?? const [])) DashboardCardConfig.fromJson((c as Map).cast()),
    ];
    // Card types added in newer versions: lifetime earnings (2.0.1) is shown
    // right after the live counter; any others are appended hidden.
    for (final t in DashboardCardType.values) {
      if (cards.any((c) => c.type == t)) continue;
      if (t == DashboardCardType.lifetime) {
        cards.insert(cards.indexWhere((c) => c.type == DashboardCardType.liveCounter) + 1, DashboardCardConfig(type: t));
      } else {
        cards.add(DashboardCardConfig(type: t, visible: false));
      }
    }
    final effectiveUnits = units.isEmpty ? d.units : units;
    final primary = enumByName(EarningUnit.values, j['primaryUnit'] as String?, d.primaryUnit);
    return DashboardConfig(
      units: effectiveUnits,
      primaryUnit: effectiveUnits.contains(primary) ? primary : effectiveUnits.first,
      cards: cards,
      precision: (j['precision'] as int? ?? d.precision).clamp(0, 6),
      compact: j['compact'] as bool? ?? false,
      rateBasis: enumByName(RateBasis.values, j['rateBasis'] as String?, d.rateBasis),
      counterRange: enumByName(CounterRange.values, j['counterRange'] as String?, d.counterRange),
    );
  }

  /// Visible earning units in display order. Never empty.
  final List<EarningUnit> units;
  final EarningUnit primaryUnit;
  final List<DashboardCardConfig> cards;

  /// Decimal places for sub-day rates and the live counter.
  final int precision;
  final bool compact;
  final RateBasis rateBasis;
  final CounterRange counterRange;

  DashboardConfig copyWith({
    List<EarningUnit>? units,
    EarningUnit? primaryUnit,
    List<DashboardCardConfig>? cards,
    int? precision,
    bool? compact,
    RateBasis? rateBasis,
    CounterRange? counterRange,
  }) =>
      DashboardConfig(
        units: units ?? this.units,
        primaryUnit: primaryUnit ?? this.primaryUnit,
        cards: cards ?? this.cards,
        precision: precision ?? this.precision,
        compact: compact ?? this.compact,
        rateBasis: rateBasis ?? this.rateBasis,
        counterRange: counterRange ?? this.counterRange,
      );

  Map<String, dynamic> toJson() => {
        'units': units.map((u) => u.name).toList(),
        'primaryUnit': primaryUnit.name,
        'cards': cards.map((c) => c.toJson()).toList(),
        'precision': precision,
        'compact': compact,
        'rateBasis': rateBasis.name,
        'counterRange': counterRange.name,
      };
}

enum AppThemeMode { system, light, dark }

class AppearanceSettings {
  const AppearanceSettings({this.themeMode = AppThemeMode.system, this.reduceMotion = false});

  factory AppearanceSettings.fromJson(Map<String, dynamic> j) => AppearanceSettings(
        themeMode: enumByName(AppThemeMode.values, j['themeMode'] as String?, AppThemeMode.system),
        reduceMotion: j['reduceMotion'] as bool? ?? false,
      );

  final AppThemeMode themeMode;

  /// Forces reduced motion in addition to the OS accessibility setting.
  final bool reduceMotion;

  AppearanceSettings copyWith({AppThemeMode? themeMode, bool? reduceMotion}) => AppearanceSettings(
        themeMode: themeMode ?? this.themeMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  Map<String, dynamic> toJson() => {'themeMode': themeMode.name, 'reduceMotion': reduceMotion};
}

enum AutoLock {
  immediately(Duration.zero),
  after1Minute(Duration(minutes: 1)),
  after5Minutes(Duration(minutes: 5)),
  after15Minutes(Duration(minutes: 15)),
  onRestartOnly(null);

  const AutoLock(this.delay);
  final Duration? delay;

  String get label => switch (this) {
        immediately => 'Immediately',
        after1Minute => 'After 1 minute',
        after5Minutes => 'After 5 minutes',
        after15Minutes => 'After 15 minutes',
        onRestartOnly => 'Only when the app restarts',
      };
}

class SecuritySettings {
  const SecuritySettings({
    this.autoLock = AutoLock.after1Minute,
    this.biometricsEnabled = false,
    this.privacyMode = false,
    this.hideAmountsOnWidget = false,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> j) => SecuritySettings(
        autoLock: enumByName(AutoLock.values, j['autoLock'] as String?, AutoLock.after1Minute),
        biometricsEnabled: j['biometricsEnabled'] as bool? ?? false,
        privacyMode: j['privacyMode'] as bool? ?? false,
        hideAmountsOnWidget: j['hideAmountsOnWidget'] as bool? ?? false,
      );

  final AutoLock autoLock;
  final bool biometricsEnabled;

  /// Hides amounts until tapped and obscures the app-switcher preview.
  final bool privacyMode;
  final bool hideAmountsOnWidget;

  SecuritySettings copyWith({
    AutoLock? autoLock,
    bool? biometricsEnabled,
    bool? privacyMode,
    bool? hideAmountsOnWidget,
  }) =>
      SecuritySettings(
        autoLock: autoLock ?? this.autoLock,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
        privacyMode: privacyMode ?? this.privacyMode,
        hideAmountsOnWidget: hideAmountsOnWidget ?? this.hideAmountsOnWidget,
      );

  Map<String, dynamic> toJson() => {
        'autoLock': autoLock.name,
        'biometricsEnabled': biometricsEnabled,
        'privacyMode': privacyMode,
        'hideAmountsOnWidget': hideAmountsOnWidget,
      };
}

enum NotificationCategory {
  upcomingSalary,
  salaryPayday,
  upcomingBonus,
  outstandingPayment,
  temporaryJobEnd,
  monthlyActualUpdate,
  monthEndReview,
  backupReminder,
  earningsSummary,
  calendarReminder;

  String get label => switch (this) {
        upcomingSalary => 'Upcoming salary',
        salaryPayday => 'Salary payday',
        upcomingBonus => 'Upcoming bonus',
        outstandingPayment => 'Overdue payments',
        temporaryJobEnd => 'Temporary job ending',
        monthlyActualUpdate => 'Update variable income',
        monthEndReview => 'Month-end review',
        backupReminder => 'Backup reminder',
        earningsSummary => 'Earnings summary',
        calendarReminder => 'Calendar reminders',
      };

  String get description => switch (this) {
        upcomingSalary => 'A few days before a salary is due',
        salaryPayday => 'On the expected payment day',
        upcomingBonus => 'Before an expected bonus date',
        outstandingPayment => 'When an expected payment is overdue',
        temporaryJobEnd => 'Before temporary work ends',
        monthlyActualUpdate => 'Reminder to enter actual business or freelance income',
        monthEndReview => 'Review the month on its last day',
        backupReminder => 'When your last backup is getting old',
        earningsSummary => 'A short daily or weekly summary',
        calendarReminder => 'Events you marked "remind me"',
      };
}

enum SummaryFrequency { daily, weekly }

class NotificationSettings {
  const NotificationSettings({
    this.enabled = const {
      NotificationCategory.upcomingSalary,
      NotificationCategory.salaryPayday,
      NotificationCategory.upcomingBonus,
      NotificationCategory.outstandingPayment,
      NotificationCategory.temporaryJobEnd,
      NotificationCategory.monthlyActualUpdate,
      NotificationCategory.monthEndReview,
      NotificationCategory.calendarReminder,
    },
    this.daysBefore = 2,
    this.reminderMinute = 9 * 60,
    this.quietStartMinute = 22 * 60,
    this.quietEndMinute = 8 * 60,
    this.summaryFrequency = SummaryFrequency.weekly,
    this.masterEnabled = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> j) => NotificationSettings(
        enabled: {
          for (final n in (j['enabled'] as List? ?? const []))
            if (NotificationCategory.values.any((c) => c.name == n)) NotificationCategory.values.byName(n as String),
        },
        daysBefore: (j['daysBefore'] as int? ?? 2).clamp(0, 14),
        reminderMinute: (j['reminderMinute'] as int? ?? 540).clamp(0, 1439),
        quietStartMinute: (j['quietStartMinute'] as int? ?? 1320).clamp(0, 1439),
        quietEndMinute: (j['quietEndMinute'] as int? ?? 480).clamp(0, 1439),
        summaryFrequency: enumByName(SummaryFrequency.values, j['summaryFrequency'] as String?, SummaryFrequency.weekly),
        masterEnabled: j['masterEnabled'] as bool? ?? false,
      );

  final Set<NotificationCategory> enabled;
  final int daysBefore;

  /// Local minute of day for reminders.
  final int reminderMinute;
  final int quietStartMinute;
  final int quietEndMinute;
  final SummaryFrequency summaryFrequency;

  /// Off until the user grants permission and opts in.
  final bool masterEnabled;

  bool isOn(NotificationCategory c) => masterEnabled && enabled.contains(c);

  NotificationSettings copyWith({
    Set<NotificationCategory>? enabled,
    int? daysBefore,
    int? reminderMinute,
    int? quietStartMinute,
    int? quietEndMinute,
    SummaryFrequency? summaryFrequency,
    bool? masterEnabled,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        daysBefore: daysBefore ?? this.daysBefore,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        quietStartMinute: quietStartMinute ?? this.quietStartMinute,
        quietEndMinute: quietEndMinute ?? this.quietEndMinute,
        summaryFrequency: summaryFrequency ?? this.summaryFrequency,
        masterEnabled: masterEnabled ?? this.masterEnabled,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled.map((e) => e.name).toList(),
        'daysBefore': daysBefore,
        'reminderMinute': reminderMinute,
        'quietStartMinute': quietStartMinute,
        'quietEndMinute': quietEndMinute,
        'summaryFrequency': summaryFrequency.name,
        'masterEnabled': masterEnabled,
      };
}

class CalculationSettings {
  const CalculationSettings({
    this.defaultSchedule = const WorkSchedule(),
    this.defaultPolicy = AccrualPolicy.calendarDay,
    this.monthEndReminderDay = 0,
  });

  factory CalculationSettings.fromJson(Map<String, dynamic> j) => CalculationSettings(
        defaultSchedule: WorkSchedule(
          weekdays: WorkSchedule.weekdaysFromMask(j['weekdayMask'] as int? ?? 31),
          startMinute: j['startMinute'] as int? ?? 540,
          endMinute: j['endMinute'] as int? ?? 1080,
        ),
        defaultPolicy: enumByName(AccrualPolicy.values, j['defaultPolicy'] as String?, AccrualPolicy.calendarDay),
        monthEndReminderDay: j['monthEndReminderDay'] as int? ?? 0,
      );

  /// Pre-filled into new income sources.
  final WorkSchedule defaultSchedule;
  final AccrualPolicy defaultPolicy;

  /// Days before month end for the reconciliation reminder (0 = last day).
  final int monthEndReminderDay;

  CalculationSettings copyWith({WorkSchedule? defaultSchedule, AccrualPolicy? defaultPolicy, int? monthEndReminderDay}) =>
      CalculationSettings(
        defaultSchedule: defaultSchedule ?? this.defaultSchedule,
        defaultPolicy: defaultPolicy ?? this.defaultPolicy,
        monthEndReminderDay: monthEndReminderDay ?? this.monthEndReminderDay,
      );

  Map<String, dynamic> toJson() => {
        'weekdayMask': defaultSchedule.weekdayMask,
        'startMinute': defaultSchedule.startMinute,
        'endMinute': defaultSchedule.endMinute,
        'defaultPolicy': defaultPolicy.name,
        'monthEndReminderDay': monthEndReminderDay,
      };
}

class BackupState {
  const BackupState({this.lastBackupAt, this.reminderDays = 30});

  factory BackupState.fromJson(Map<String, dynamic> j) => BackupState(
        lastBackupAt: j['lastBackupAt'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(j['lastBackupAt'] as int, isUtc: true),
        reminderDays: j['reminderDays'] as int? ?? 30,
      );

  final DateTime? lastBackupAt;
  final int reminderDays;

  Map<String, dynamic> toJson() => {
        if (lastBackupAt != null) 'lastBackupAt': lastBackupAt!.microsecondsSinceEpoch,
        'reminderDays': reminderDays,
      };
}
