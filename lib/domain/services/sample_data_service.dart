import '../../core/clock.dart';
import '../../core/date_time/local_date.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../models/records.dart';
import '../repositories/repositories.dart';

/// Optional, clearly-labelled sample data for exploring the app. It is only
/// inserted when the user explicitly asks for it, every source is flagged
/// `isSample`, and [remove] deletes exactly those records.
class SampleDataService {
  SampleDataService(this.sources, this.records, this.clock, this.ids);

  final IncomeSourceRepository sources;
  final RecordsRepository records;
  final Clock clock;
  final IdGenerator ids;

  Future<void> insert({required String currencyCode, required LocalDate today}) async {
    final now = clock.now();
    final salaryStart = LocalDate(today.year - 2, today.month, 1);
    final salary = IncomeSource(
      id: ids.newId(),
      name: 'Sample: Northwind Labs',
      kind: IncomeKind.salary,
      category: IncomeCategory.salary,
      currencyCode: currencyCode,
      startDate: salaryStart,
      employer: 'Northwind Labs (sample)',
      payDay: 1,
      payOffsetMonths: 1,
      weekendAdjust: WeekendAdjust.previousBusinessDay,
      notes: 'Sample data — remove it from Settings › Data.',
      colorIndex: 0,
      isSample: true,
      createdAt: now,
      updatedAt: now,
    );
    await sources.createSource(salary, initialRate: _rev(salary.id, salaryStart, 6500000, RevisionChangeType.initial));
    await sources.addRevision(_rev(salary.id, LocalDate(today.year, 4, 1).isAfter(today)
        ? LocalDate(today.year - 1, 4, 1)
        : LocalDate(today.year, 4, 1), 7500000, RevisionChangeType.hike, percentBps: 1538));

    // Payments for the last three completed salary periods.
    for (var i = 2; i <= 4; i++) {
      final period = today.yearMonth.addMonths(-i);
      await records.addLedgerEntry(LedgerEntry(
        id: ids.newId(),
        sourceId: salary.id,
        type: LedgerType.received,
        amountMinor: 6500000,
        currencyCode: currencyCode,
        periodMonth: period,
        date: period.next.firstDay,
        notes: 'Sample payment',
        createdAt: now,
        updatedAt: now,
      ));
    }

    final bonusDate = LocalDate(today.year, 3, 31).isAfter(today) ? LocalDate(today.year - 1, 3, 31) : LocalDate(today.year, 3, 31);
    await records.saveItem(CompensationItem(
      id: ids.newId(),
      sourceId: salary.id,
      type: CompensationType.annualBonus,
      title: 'Sample annual bonus',
      currencyCode: currencyCode,
      expectedMinor: 10000000,
      expectedDate: bonusDate,
      actualMinor: 11000000,
      earnedDate: bonusDate,
      recurrence: Recurrence.yearly,
      createdAt: now,
      updatedAt: now,
    ));

    final freelance = IncomeSource(
      id: ids.newId(),
      name: 'Sample: Freelance design',
      kind: IncomeKind.variable,
      category: IncomeCategory.freelance,
      currencyCode: currencyCode,
      startDate: today.yearMonth.addMonths(-6).firstDay,
      payRule: PayRule.manual,
      colorIndex: 1,
      isSample: true,
      createdAt: now,
      updatedAt: now,
    );
    await sources.createSource(
      freelance,
      initialRate: _rev(freelance.id, freelance.startDate, 2000000, RevisionChangeType.estimateUpdate),
    );
    const actuals = [1850000, 2450000, 1700000, 2900000, 2200000];
    for (var i = 0; i < actuals.length; i++) {
      final m = today.yearMonth.addMonths(-(actuals.length - i));
      await records.finalizeMonth(freelance.id, m, actuals[i]);
    }
  }

  RateRevision _rev(String sourceId, LocalDate from, int amount, RevisionChangeType type, {int? percentBps}) =>
      RateRevision(
        id: ids.newId(),
        sourceId: sourceId,
        effectiveFrom: from,
        amountMinor: amount,
        period: RatePeriod.month,
        changeType: type,
        percentBps: percentBps,
        createdAt: clock.now(),
      );

  Future<int> remove() async {
    final all = await sources.sources();
    var removed = 0;
    for (final s in all.where((s) => s.isSample)) {
      await sources.deleteSourceIfUnused(s.id);
      removed++;
    }
    return removed;
  }
}
