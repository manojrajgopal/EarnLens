import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/settings.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../domain/notification_models.dart';

final _permissionProvider = FutureProvider.autoDispose<NotificationPermission>((ref) async {
  final p = ref.watch(notificationProviderProvider);
  if (!p.isSupported) return NotificationPermission.unsupported;
  try {
    return await p.permissionStatus();
  } on Object {
    return NotificationPermission.unsupported;
  }
});

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check the permission after the user returns from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(_permissionProvider);
  }

  Future<void> _save(NotificationSettings next) =>
      runGuarded(context, () => ref.read(settingsControllerProvider).saveNotifications(next));

  Future<void> _toggleMaster(NotificationSettings s, bool on) async {
    if (!on) {
      await _save(s.copyWith(masterEnabled: false));
      return;
    }
    final provider = ref.read(notificationProviderProvider);
    if (!provider.isSupported) {
      showMessage(context, 'Notifications are not supported on this device or browser.');
      return;
    }
    setState(() => _requesting = true);
    NotificationPermission result;
    try {
      result = await provider.requestPermission();
    } on Object {
      result = NotificationPermission.denied;
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    if (!mounted) return;
    ref.invalidate(_permissionProvider);
    switch (result) {
      case NotificationPermission.granted:
        await _save(s.copyWith(masterEnabled: true));
      case NotificationPermission.denied:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Notifications are blocked'),
            content: Text(_deniedHelp, style: AppType.body),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      case NotificationPermission.unsupported:
        showMessage(context, 'Notifications are not supported on this device or browser.');
    }
  }

  static String get _deniedHelp {
    if (kIsWeb) {
      return 'Your browser is blocking notifications for EarnLens. Click the icon next to the address bar, '
          'allow notifications for this site, then turn this switch on again.';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Open the Settings app › Notifications › EarnLens and turn on "Allow Notifications", '
          'then come back and turn this switch on again.';
    }
    return 'Open your phone\'s Settings › Apps › EarnLens › Notifications and allow notifications, '
        'then come back and turn this switch on again.';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(notificationSettingsProvider);
    final perm = ref.watch(_permissionProvider);
    final provider = ref.watch(notificationProviderProvider);
    final c = context.colors;
    final on = s.masterEnabled;

    final (String permLabel, Color permColor, Color permBg) = switch (perm.value) {
      NotificationPermission.granted => ('Allowed', c.positive, c.positiveSoft),
      NotificationPermission.denied => ('Blocked in system settings', c.error, c.errorSoft),
      NotificationPermission.unsupported => ('Not supported here', c.inkMuted, c.cardHigh),
      null => ('Checking…', c.inkMuted, c.cardHigh),
    };

    Future<void> pickTime(String title, int current, NotificationSettings Function(int) apply) async {
      final m = await pickMinuteOfDay(context, current);
      if (m != null) await _save(apply(m));
    }

    return SettingsPage(
      title: 'Notifications',
      children: [
        SettingsGroup(children: [
          SettingsSwitch(
            icon: Icons.notifications_active_outlined,
            tone: SettingsTone.peach,
            title: 'Allow reminders',
            subtitle: _requesting ? 'Asking for permission…' : 'Master switch for every EarnLens notification',
            value: on,
            onChanged: _requesting ? null : (v) => _toggleMaster(s, v),
          ),
          SettingsTile(
            icon: Icons.verified_user_outlined,
            tone: SettingsTone.mint,
            title: 'System permission',
            trailing: Flexible(child: Pill(permLabel, color: permBg, textColor: permColor)),
          ),
        ]),
        if (perm.value == NotificationPermission.denied)
          NoteCard(warning: true, icon: Icons.block_rounded, message: _deniedHelp),
        if (perm.value == NotificationPermission.unsupported)
          const NoteCard(
            warning: true,
            icon: Icons.notifications_off_outlined,
            message: 'This device or browser cannot show notifications from EarnLens. Your reminders still '
                'appear inside the app on the dashboard and calendar.',
          ),
        SettingsGroup(
          title: 'What to remind me about',
          footer: on ? null : 'Turn on "Allow reminders" to receive these.',
          children: [
            for (final cat in NotificationCategory.values)
              SettingsSwitch(
                title: cat.label,
                subtitle: cat.description,
                value: s.enabled.contains(cat),
                onChanged: on
                    ? (v) => _save(s.copyWith(enabled: v ? ({...s.enabled, cat}) : ({...s.enabled}..remove(cat))))
                    : null,
              ),
          ],
        ),
        SettingsGroup(title: 'Timing', children: [
          SettingsTile(
            icon: Icons.schedule_rounded,
            tone: SettingsTone.sky,
            title: 'Reminder time',
            subtitle: 'Time of day reminders are sent',
            value: formatMinuteOfDay(s.reminderMinute),
            onTap: on ? () => pickTime('Reminder time', s.reminderMinute, (m) => s.copyWith(reminderMinute: m)) : null,
          ),
          SettingsTile(
            icon: Icons.event_available_outlined,
            tone: SettingsTone.mint,
            title: 'Remind me before payments',
            subtitle: s.daysBefore == 0
                ? 'On the day only'
                : '${s.daysBefore} day${s.daysBefore == 1 ? '' : 's'} before',
            onTap: on
                ? () async {
                    final v = await pickOption<int>(
                      context,
                      title: 'Days before',
                      values: const [0, 1, 2, 3, 5, 7, 10, 14],
                      selected: s.daysBefore,
                      label: (d) => d == 0 ? 'On the day only' : '$d day${d == 1 ? '' : 's'} before',
                    );
                    if (v != null) await _save(s.copyWith(daysBefore: v));
                  }
                : null,
          ),
          SettingsTile(
            icon: Icons.bedtime_outlined,
            title: 'Quiet hours start',
            subtitle: 'No notifications from this time',
            value: formatMinuteOfDay(s.quietStartMinute),
            onTap: on
                ? () => pickTime('Quiet hours start', s.quietStartMinute, (m) => s.copyWith(quietStartMinute: m))
                : null,
          ),
          SettingsTile(
            icon: Icons.wb_twilight_rounded,
            tone: SettingsTone.peach,
            title: 'Quiet hours end',
            subtitle: 'Notifications resume at this time',
            value: formatMinuteOfDay(s.quietEndMinute),
            onTap: on
                ? () => pickTime('Quiet hours end', s.quietEndMinute, (m) => s.copyWith(quietEndMinute: m))
                : null,
          ),
          SettingsBlock(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earnings summary', style: AppType.label.copyWith(fontSize: 15)),
              const SizedBox(height: AppSpace.sm),
              IgnorePointer(
                ignoring: !on || !s.enabled.contains(NotificationCategory.earningsSummary),
                child: Opacity(
                  opacity: on && s.enabled.contains(NotificationCategory.earningsSummary) ? 1 : 0.5,
                  child: ChoicePills<SummaryFrequency>(
                    values: SummaryFrequency.values,
                    selected: s.summaryFrequency,
                    label: (f) => f == SummaryFrequency.daily ? 'Daily' : 'Weekly',
                    onSelected: (f) => _save(s.copyWith(summaryFrequency: f)),
                  ),
                ),
              ),
              if (!s.enabled.contains(NotificationCategory.earningsSummary))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Text('Turn on "Earnings summary" above to choose how often.',
                      style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                ),
            ]),
          ),
        ]),
        SettingsGroup(title: 'Good to know', children: [
          SettingsBlock(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Bullet(kIsWeb
                  ? 'In the browser, reminders only appear while EarnLens is open in a tab. Closed tabs cannot '
                      'show notifications.'
                  : provider.exactTiming
                      ? 'Reminders are scheduled for the exact time on this device.'
                      : 'Android may deliver reminders a few minutes after the chosen time to save battery, '
                          'unless EarnLens is allowed to schedule exact alarms.'),
              const _Bullet('A reminder being scheduled does not guarantee it is delivered — battery savers, '
                  'Do Not Disturb or system settings can hold it back.'),
              const _Bullet('Reminders are worked out from your income rules and rescheduled automatically when '
                  'you change your data or these settings.'),
              const _Bullet('When privacy mode is on, notifications leave out amounts so nothing sensitive shows on the lock screen.'),
            ]),
          ),
        ]),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text, style: AppType.body)),
        ]),
      );
}
