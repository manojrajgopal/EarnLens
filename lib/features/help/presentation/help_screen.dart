import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/components.dart';
import '../../settings/presentation/settings_widgets.dart';

class _Topic {
  const _Topic(this.icon, this.question, this.paragraphs);
  final IconData icon;
  final String question;
  final List<String> paragraphs;
}

const _understanding = <_Topic>[
  _Topic(Icons.savings_outlined, 'What does "money earned so far" mean?', [
    'It is the pay you have earned for the work done up to this moment, worked out from your income rules — '
        'whether or not it has reached your bank account yet.',
    '"Received" is money you have recorded as actually paid to you. The difference between the two is what '
        'is still owed to you (outstanding).',
  ]),
  _Topic(Icons.compare_arrows_rounded, 'Expected vs actual', [
    'Expected is what your rules say you should earn or be paid for a period. Actual is what really happened: '
        'the amounts you recorded for variable income, bonuses, adjustments and deductions.',
    'The variance shows the gap, so you can spot an underpayment or a better-than-expected month.',
  ]),
  _Topic(Icons.calendar_month_outlined, 'Calendar-day vs working-day pay', [
    'Calendar-day: a monthly salary is spread evenly over every day of the month, weekends and holidays '
        'included. In a 30-day month you earn 1/30 of your salary each day — this is how most employers pro-rate.',
    'Working-day: pay is spread only over your working hours on working days. Nothing accrues at night, '
        'on weekends or on days marked as holidays or unpaid leave.',
    'Hourly and per-second figures use 24-hour days unless you choose "Working hours only" in Earnings '
        'calculation, so a calendar-day salary is never accidentally divided by an 8-hour day.',
  ]),
  _Topic(Icons.event_repeat_rounded, 'Why does October\'s salary paid in November count in October?', [
    'EarnLens records earnings in the month the work was done, not the month the money arrived. '
        'Your October salary is earned during October, even if it is paid on 1 November.',
    'The payment itself appears as "received" on its real date, and October shows as fully paid once it '
        'arrives. Set the pay day and "paid the following month" on the income source to match your employer.',
  ]),
  _Topic(Icons.trending_up_rounded, 'Salary hikes and retroactive adjustments', [
    'Add a pay revision with the date the new salary takes effect. Earlier months keep the old rate; '
        'history is never rewritten.',
    'If a hike is applied retroactively (arrears), record the effective date as the original date. '
        'Any extra amount actually paid later can be recorded as an adjustment for the month it belongs to.',
  ]),
  _Topic(Icons.storefront_outlined, 'Variable income at month end', [
    'Business, freelance and commission income is not known in advance. During the month EarnLens uses your '
        'estimate; at month end, enter the actual figure for the month and it replaces the estimate.',
    'A month-end reminder can prompt you — set it in Notifications and Earnings calculation.',
  ]),
  _Topic(Icons.speed_rounded, 'How the live counter works', [
    'The live counter is calculated from your rules and the current time every time it is shown. It is not a '
        'running counter, so nothing is lost when you close the app, restart your phone or are offline.',
    'Today\'s live amount uses the financial timezone in your profile. Past days are stored as dates and never '
        'change if you travel or change timezone.',
  ]),
];

const _troubleshooting = <_Topic>[
  _Topic(Icons.widgets_outlined, 'The home-screen widget is not up to date', [
    'Android limits how often widgets can refresh to save battery, so the widget may lag by up to about 30 '
        'minutes. Opening EarnLens updates it immediately.',
    'The home-screen widget is currently available on Android only.',
  ]),
  _Topic(Icons.notifications_off_outlined, 'A reminder arrived late or not at all', [
    'Android may deliver reminders a few minutes after the scheduled time unless exact alarms are allowed. '
        'Battery savers, Do Not Disturb and quiet hours can also hold them back.',
    'In the browser, reminders only appear while EarnLens is open in a tab.',
    'Check Settings › Notifications: the master switch and the system permission must both be on.',
  ]),
  _Topic(Icons.backup_outlined, 'Backups and browser storage', [
    'EarnLens keeps your data only on this device. A backup is a file you save somewhere safe — another '
        'drive, cloud storage you choose, or email to yourself. Protect it with a password.',
    'In the web version, data lives in this browser only. Clearing site data or using a private window can '
        'erase it, and other browsers or devices will not see it. Back up regularly.',
    'Restoring can either replace everything on the device or merge in only missing records.',
  ]),
  _Topic(Icons.pin_outlined, 'I forgot my PIN', [
    'There is no online account, so nobody can reset your PIN remotely.',
    'If biometric unlock is available, tap "Forgot PIN?" on the lock screen and verify with your fingerprint '
        'or face to set a new PIN — your data is kept.',
    'Otherwise choose "Erase EarnLens on this device" from the same screen, then restore your latest backup. '
        'Encrypted backups use their own password, not your PIN.',
  ]),
  _Topic(Icons.currency_exchange_rounded, 'A source is missing from my totals', [
    'Totals only include income sources in your profile currency. Sources in other currencies are kept and '
        'shown on their own, but EarnLens does not convert between currencies.',
    'Paused, ended or archived sources stop accruing from their pause or end date.',
  ]),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'Help',
        children: [
          const SizedBox(height: AppSpace.sm),
          EntranceScale(
            child: EarnCard(
              accent: true,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_rounded, color: AppColors.white),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('How can we help?',
                        style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Plain-language answers about how EarnLens works out your numbers, and fixes for common '
                      'hiccups. Tap a question to open it.',
                      style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SettingsGroupHeader('Understanding your numbers'),
          const _TopicCard(topics: _understanding),
          const SettingsGroupHeader('Troubleshooting'),
          const _TopicCard(topics: _troubleshooting, toneOffset: 2),
          SettingsGroup(title: 'More', children: [
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              tone: SettingsTone.mint,
              title: 'Privacy',
              subtitle: 'Where your data is stored',
              onTap: () => context.go('/settings/privacy'),
            ),
            SettingsTile(
              icon: Icons.storage_rounded,
              tone: SettingsTone.sky,
              title: 'Backup & restore',
              subtitle: 'Create a backup now',
              onTap: () => context.go('/settings/data'),
            ),
          ]),
        ],
      );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topics, this.toneOffset = 0});
  final List<_Topic> topics;
  final int toneOffset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return EarnCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(children: [
          for (final (i, t) in topics.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 18, endIndent: 18, color: c.line),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(72, 0, 20, AppSpace.lg),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              leading: SettingsIcon(t.icon, tone: SettingsTone.values[(i + toneOffset) % SettingsTone.values.length]),
              title: Text(t.question, style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
              children: [
                for (final p in t.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Text(p, style: AppType.body.copyWith(color: c.ink)),
                  ),
              ],
            ),
          ],
        ]),
      ),
    );
  }
}
