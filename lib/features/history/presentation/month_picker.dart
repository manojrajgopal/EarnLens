import 'package:flutter/material.dart';

import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/income_source.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';

/// Dialog for choosing a month and year.
Future<YearMonth?> showMonthPicker(BuildContext context, {required YearMonth initial}) =>
    showDialog<YearMonth>(context: context, builder: (_) => _MonthPickerDialog(initial: initial));

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final YearMonth initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Row(children: [
        IconButton(
          tooltip: 'Previous year',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _year > 1970 ? () => setState(() => _year--) : null,
        ),
        Expanded(child: Text('$_year', textAlign: TextAlign.center, style: AppType.title.copyWith(fontWeight: FontWeight.w700))),
        IconButton(
          tooltip: 'Next year',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _year < 2100 ? () => setState(() => _year++) : null,
        ),
      ]),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2,
          children: [
            for (var m = 1; m <= 12; m++)
              Builder(builder: (context) {
                final ym = YearMonth(_year, m);
                final selected = ym == widget.initial;
                return Semantics(
                  selected: selected,
                  button: true,
                  label: formatMonth(ym),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: selected ? AppGradients.orb : null,
                      color: selected ? null : c.cardHigh,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => Navigator.pop(context, ym),
                        child: Center(
                          child: ExcludeSemantics(
                            child: Text(formatMonthShort(ym),
                                style: AppType.label.copyWith(
                                  color: selected ? AppColors.white : c.ink,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

/// Bottom sheet listing [sources]; returns the chosen one.
Future<IncomeSource?> pickSource(BuildContext context, List<IncomeSource> sources, {required String title}) =>
    showModalBottomSheet<IncomeSource>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: AppType.title),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
                for (final s in sources)
                  ListTile(
                    minTileHeight: 56,
                    leading: SourceAvatar(s, size: 36),
                    title: Text(s.name),
                    subtitle: Text(s.kind.label),
                    onTap: () => Navigator.pop(ctx, s),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
