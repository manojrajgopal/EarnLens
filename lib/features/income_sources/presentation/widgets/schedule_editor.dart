import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../domain/models/income_source.dart';
import '../../../../shared/widgets/form_fields.dart';

/// Edits working weekdays and the daily working window.
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({super.key, required this.schedule, required this.onChanged});

  final WorkSchedule schedule;
  final ValueChanged<WorkSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = schedule;
    final hours = s.workingMinutesPerDay > 0 ? s.workingMinutesPerDay / 60 : 0;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Working days', style: AppType.label),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(weekdayShort[d - 1]),
                  selected: s.weekdays.contains(d),
                  tooltip: s.weekdays.contains(d) ? 'Working day' : 'Day off',
                  onSelected: (on) {
                    final next = {...s.weekdays};
                    on ? next.add(d) : next.remove(d);
                    onChanged(s.copyWith(weekdays: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Working hours', style: AppType.label),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Starts',
                  minute: s.startMinute,
                  onPick: (m) => onChanged(s.copyWith(startMinute: m)),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _TimeButton(
                  label: 'Ends',
                  minute: s.endMinute,
                  onPick: (m) => onChanged(s.copyWith(endMinute: m == 0 ? 24 * 60 : m)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (!s.isValid)
            Text(
              s.weekdays.isEmpty ? 'Pick at least one working day.' : 'The end time must be after the start time.',
              style: AppType.bodySmall.copyWith(color: c.error),
            )
          else
            Text(
              '${s.weekdays.length} days a week, ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} hours a day.',
              style: AppType.bodySmall.copyWith(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.minute, required this.onPick});
  final String label;
  final int minute;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () async {
      final m = await pickMinuteOfDay(context, minute >= 24 * 60 ? 0 : minute);
      if (m != null) onPick(m);
    },
    child: Text('$label ${minute >= 24 * 60 ? '24:00' : formatMinuteOfDay(minute)}'),
  );
}
