import '../calculation/rate_calculator.dart';
import '../models/settings.dart';

/// Pure rules for editing the dashboard configuration.
/// Invariant: at least one earning unit is always visible and the primary
/// unit is always one of the visible units.
class DashboardPreferences {
  const DashboardPreferences._();

  static DashboardConfig toggleUnit(DashboardConfig c, EarningUnit unit) {
    final units = [...c.units];
    if (units.contains(unit)) {
      if (units.length == 1) return c; // the last unit cannot be removed
      units.remove(unit);
    } else {
      // Insert in canonical order relative to existing units.
      units.add(unit);
    }
    final primary = units.contains(c.primaryUnit) ? c.primaryUnit : units.first;
    return c.copyWith(units: units, primaryUnit: primary);
  }

  static DashboardConfig selectAll(DashboardConfig c) {
    final units = [...c.units, ...EarningUnit.values.where((u) => !c.units.contains(u))];
    return c.copyWith(units: units);
  }

  /// Keeps only the primary unit (the last unit can never be removed).
  static DashboardConfig deselectAll(DashboardConfig c) => c.copyWith(units: [c.primaryUnit]);

  static DashboardConfig setPrimary(DashboardConfig c, EarningUnit unit) {
    final units = c.units.contains(unit) ? c.units : [...c.units, unit];
    return c.copyWith(units: units, primaryUnit: unit);
  }

  static DashboardConfig reorderUnits(DashboardConfig c, int oldIndex, int newIndex) {
    final units = [...c.units];
    final item = units.removeAt(oldIndex);
    units.insert(newIndex.clamp(0, units.length), item);
    return c.copyWith(units: units);
  }

  static DashboardConfig reorderCards(DashboardConfig c, int oldIndex, int newIndex) {
    final cards = [...c.cards];
    final item = cards.removeAt(oldIndex);
    cards.insert(newIndex.clamp(0, cards.length), item);
    return c.copyWith(cards: cards);
  }

  static DashboardConfig updateCard(DashboardConfig c, DashboardCardConfig card) => c.copyWith(
        cards: [for (final x in c.cards) x.type == card.type ? card : x],
      );

  static DashboardConfig setPrecision(DashboardConfig c, int precision) =>
      c.copyWith(precision: precision.clamp(0, 6));

  static bool isValid(DashboardConfig c) =>
      c.units.isNotEmpty && c.units.contains(c.primaryUnit) && c.units.toSet().length == c.units.length;
}
