import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/income_source.dart';

/// Icon and colour conventions for income sources.
abstract final class IncomeVisuals {
  static IconData categoryIcon(IncomeCategory c) => switch (c) {
        IncomeCategory.salary => Icons.work_outline_rounded,
        IncomeCategory.freelance => Icons.brush_outlined,
        IncomeCategory.partTime => Icons.schedule_rounded,
        IncomeCategory.business => Icons.storefront_outlined,
        IncomeCategory.rental => Icons.home_work_outlined,
        IncomeCategory.consulting => Icons.forum_outlined,
        IncomeCategory.commission => Icons.percent_rounded,
        IncomeCategory.investment => Icons.trending_up_rounded,
        IncomeCategory.other => Icons.payments_outlined,
        IncomeCategory.custom => Icons.label_outline_rounded,
      };

  static IconData kindIcon(IncomeKind k) => switch (k) {
        IncomeKind.salary => Icons.work_outline_rounded,
        IncomeKind.recurring => Icons.autorenew_rounded,
        IncomeKind.temporary => Icons.timelapse_rounded,
        IncomeKind.variable => Icons.show_chart_rounded,
        IncomeKind.oneTime => Icons.redeem_outlined,
      };

  static Color color(IncomeSource s) => AppColors.seriesAt(s.colorIndex);

  /// Readable foreground on top of [color].
  static Color onColor(IncomeSource s) =>
      ThemeData.estimateBrightnessForColor(color(s)) == Brightness.dark ? Colors.white : Colors.black;
}

class SourceAvatar extends StatelessWidget {
  const SourceAvatar(this.source, {super.key, this.size = 44});
  final IncomeSource source;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: IncomeVisuals.color(source), shape: BoxShape.circle),
        child: Icon(IncomeVisuals.categoryIcon(source.category), size: size * 0.48, color: IncomeVisuals.onColor(source)),
      );
}
