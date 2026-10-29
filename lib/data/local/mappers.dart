import 'package:drift/drift.dart';

import '../../core/date_time/local_date.dart';
import '../../database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/income_source.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/records.dart';

int ts(DateTime t) => t.toUtc().microsecondsSinceEpoch;
DateTime fromTs(int v) => DateTime.fromMicrosecondsSinceEpoch(v, isUtc: true);

extension ProfileRowX on ProfileRow {
  UserProfile toDomain() => UserProfile(
        displayName: displayName,
        currencyCode: currencyCode,
        locale: locale,
        timezone: timezone,
        dateOfBirth: LocalDate.tryParse(dateOfBirth),
        onboardingComplete: onboardingComplete,
        createdAt: fromTs(createdAt),
        updatedAt: fromTs(updatedAt),
      );
}

ProfilesCompanion profileToRow(UserProfile p) => ProfilesCompanion.insert(
      id: const Value(1),
      displayName: p.displayName,
      currencyCode: p.currencyCode,
      locale: p.locale,
      timezone: p.timezone,
      dateOfBirth: Value(p.dateOfBirth?.toIso()),
      onboardingComplete: Value(p.onboardingComplete),
      createdAt: ts(p.createdAt),
      updatedAt: ts(p.updatedAt),
    );

extension IncomeSourceRowX on IncomeSourceRow {
  IncomeSource toDomain() => IncomeSource(
        id: id,
        name: name,
        kind: enumByName(IncomeKind.values, kind, IncomeKind.salary),
        category: enumByName(IncomeCategory.values, category, IncomeCategory.other),
        customCategory: customCategory,
        status: enumByName(SourceStatus.values, status, SourceStatus.active),
        currencyCode: currencyCode,
        startDate: LocalDate.parse(startDate),
        endDate: LocalDate.tryParse(endDate),
        accrualPolicy: enumByName(AccrualPolicy.values, accrualPolicy, AccrualPolicy.calendarDay),
        schedule: WorkSchedule(
          weekdays: WorkSchedule.weekdaysFromMask(workWeekdayMask),
          startMinute: workStartMinute,
          endMinute: workEndMinute,
        ),
        payRule: enumByName(PayRule.values, payRule, PayRule.dayOfMonth),
        payDay: payDay,
        payOffsetMonths: payOffsetMonths,
        weekendAdjust: enumByName(WeekendAdjust.values, weekendAdjust, WeekendAdjust.none),
        expectedPayDate: LocalDate.tryParse(expectedPayDate),
        fixedTotalMinor: fixedTotalMinor,
        fixedTotalAccrual:
            enumByName(FixedTotalAccrual.values, fixedTotalAccrual, FixedTotalAccrual.spreadCalendarDays),
        forecastMethod: enumByName(ForecastMethod.values, forecastMethod, ForecastMethod.estimate),
        employer: employer,
        takeHomeMinor: takeHomeMinor,
        notes: notes,
        colorIndex: colorIndex,
        isSample: isSample,
        sortOrder: sortOrder,
        createdAt: fromTs(createdAt),
        updatedAt: fromTs(updatedAt),
      );
}

IncomeSourceRow sourceToRow(IncomeSource s) => IncomeSourceRow(
      id: s.id,
      name: s.name,
      kind: s.kind.name,
      category: s.category.name,
      customCategory: s.customCategory,
      status: s.status.name,
      currencyCode: s.currencyCode,
      startDate: s.startDate.toIso(),
      endDate: s.endDate?.toIso(),
      accrualPolicy: s.accrualPolicy.name,
      workWeekdayMask: s.schedule.weekdayMask,
      workStartMinute: s.schedule.startMinute,
      workEndMinute: s.schedule.endMinute,
      payRule: s.payRule.name,
      payDay: s.payDay,
      payOffsetMonths: s.payOffsetMonths,
      weekendAdjust: s.weekendAdjust.name,
      expectedPayDate: s.expectedPayDate?.toIso(),
      fixedTotalMinor: s.fixedTotalMinor,
      fixedTotalAccrual: s.fixedTotalAccrual.name,
      forecastMethod: s.forecastMethod.name,
      employer: s.employer,
      takeHomeMinor: s.takeHomeMinor,
      notes: s.notes,
      colorIndex: s.colorIndex,
      isSample: s.isSample,
      sortOrder: s.sortOrder,
      createdAt: ts(s.createdAt),
      updatedAt: ts(s.updatedAt),
    );

extension RateRevisionRowX on RateRevisionRow {
  RateRevision toDomain() => RateRevision(
        id: id,
        sourceId: sourceId,
        effectiveFrom: LocalDate.parse(effectiveFrom),
        amountMinor: amountMinor,
        period: enumByName(RatePeriod.values, period, RatePeriod.month),
        changeType: enumByName(RevisionChangeType.values, changeType, RevisionChangeType.initial),
        percentBps: percentBps,
        note: note,
        createdAt: fromTs(createdAt),
      );
}

RateRevisionRow revisionToRow(RateRevision r) => RateRevisionRow(
      id: r.id,
      sourceId: r.sourceId,
      effectiveFrom: r.effectiveFrom.toIso(),
      amountMinor: r.amountMinor,
      period: r.period.name,
      changeType: r.changeType.name,
      percentBps: r.percentBps,
      note: r.note,
      createdAt: ts(r.createdAt),
    );

extension SourcePauseRowX on SourcePauseRow {
  SourcePause toDomain() => SourcePause(
        id: id,
        sourceId: sourceId,
        start: LocalDate.parse(start),
        endExclusive: LocalDate.tryParse(endExclusive),
      );
}

SourcePauseRow pauseToRow(SourcePause p) => SourcePauseRow(
      id: p.id,
      sourceId: p.sourceId,
      start: p.start.toIso(),
      endExclusive: p.endExclusive?.toIso(),
    );

extension DayOverrideRowX on DayOverrideRow {
  DayOverride toDomain() => DayOverride(
        id: id,
        sourceId: sourceId,
        date: LocalDate.parse(date),
        type: enumByName(DayOverrideType.values, type, DayOverrideType.holiday),
        note: note,
      );
}

DayOverrideRow overrideToRow(DayOverride o) => DayOverrideRow(
      id: o.id,
      sourceId: o.sourceId,
      date: o.date.toIso(),
      type: o.type.name,
      note: o.note,
    );

extension CompensationItemRowX on CompensationItemRow {
  CompensationItem toDomain() => CompensationItem(
        id: id,
        sourceId: sourceId,
        type: enumByName(CompensationType.values, type, CompensationType.other),
        title: title,
        currencyCode: currencyCode,
        expectedMinor: expectedMinor,
        expectedDate: LocalDate.tryParse(expectedDate),
        actualMinor: actualMinor,
        earnedDate: LocalDate.tryParse(earnedDate),
        recurrence: enumByName(Recurrence.values, recurrence, Recurrence.none),
        nonCash: nonCash,
        countsAsEarnings: countsAsEarnings,
        includeInForecast: includeInForecast,
        taxNote: taxNote,
        notes: notes,
        cancelled: cancelled,
        createdAt: fromTs(createdAt),
        updatedAt: fromTs(updatedAt),
      );
}

CompensationItemRow itemToRow(CompensationItem i) => CompensationItemRow(
      id: i.id,
      sourceId: i.sourceId,
      type: i.type.name,
      title: i.title,
      currencyCode: i.currencyCode,
      expectedMinor: i.expectedMinor,
      expectedDate: i.expectedDate?.toIso(),
      actualMinor: i.actualMinor,
      earnedDate: i.earnedDate?.toIso(),
      recurrence: i.recurrence.name,
      nonCash: i.nonCash,
      countsAsEarnings: i.countsAsEarnings,
      includeInForecast: i.includeInForecast,
      taxNote: i.taxNote,
      notes: i.notes,
      cancelled: i.cancelled,
      createdAt: ts(i.createdAt),
      updatedAt: ts(i.updatedAt),
    );

extension MonthlyRecordRowX on MonthlyRecordRow {
  MonthlyRecord toDomain() => MonthlyRecord(
        id: id,
        sourceId: sourceId,
        month: YearMonth.parse(month),
        originalEstimateMinor: originalEstimateMinor,
        revisedEstimateMinor: revisedEstimateMinor,
        actualMinor: actualMinor,
        finalized: finalized,
        finalizedAt: finalizedAt == null ? null : fromTs(finalizedAt!),
        notes: notes,
        updatedAt: fromTs(updatedAt),
      );
}

MonthlyRecordRow recordToRow(MonthlyRecord r) => MonthlyRecordRow(
      id: r.id,
      sourceId: r.sourceId,
      month: r.month.toIso(),
      originalEstimateMinor: r.originalEstimateMinor,
      revisedEstimateMinor: r.revisedEstimateMinor,
      actualMinor: r.actualMinor,
      finalized: r.finalized,
      finalizedAt: r.finalizedAt == null ? null : ts(r.finalizedAt!),
      notes: r.notes,
      updatedAt: ts(r.updatedAt),
    );

extension LedgerEntryRowX on LedgerEntryRow {
  LedgerEntry toDomain() => LedgerEntry(
        id: id,
        sourceId: sourceId,
        itemId: itemId,
        type: enumByName(LedgerType.values, type, LedgerType.received),
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        periodMonth: YearMonth.parse(periodMonth),
        date: LocalDate.parse(date),
        status: enumByName(LedgerStatus.values, status, LedgerStatus.completed),
        dedupeKey: dedupeKey,
        notes: notes,
        createdAt: fromTs(createdAt),
        updatedAt: fromTs(updatedAt),
      );
}

LedgerEntryRow ledgerToRow(LedgerEntry e) => LedgerEntryRow(
      id: e.id,
      sourceId: e.sourceId,
      itemId: e.itemId,
      type: e.type.name,
      amountMinor: e.amountMinor,
      currencyCode: e.currencyCode,
      periodMonth: e.periodMonth.toIso(),
      date: e.date.toIso(),
      status: e.status.name,
      dedupeKey: e.dedupeKey,
      notes: e.notes,
      createdAt: ts(e.createdAt),
      updatedAt: ts(e.updatedAt),
    );

extension CalendarEventRowX on CalendarEventRow {
  CalendarEvent toDomain() => CalendarEvent(
        id: id,
        title: title,
        date: LocalDate.parse(date),
        type: enumByName(CalendarEventType.values, type, CalendarEventType.note),
        sourceId: sourceId,
        amountMinor: amountMinor,
        notes: notes,
        remind: remind,
        cancelled: cancelled,
        createdAt: fromTs(createdAt),
      );
}

CalendarEventRow eventToRow(CalendarEvent e) => CalendarEventRow(
      id: e.id,
      title: e.title,
      date: e.date.toIso(),
      type: e.type.name,
      sourceId: e.sourceId,
      amountMinor: e.amountMinor,
      notes: e.notes,
      remind: e.remind,
      cancelled: e.cancelled,
      createdAt: ts(e.createdAt),
    );

extension AuditRowX on AuditRow {
  AuditEntry toDomain() => AuditEntry(
        id: id,
        entityType: entityType,
        entityId: entityId,
        action: action,
        summary: summary,
        beforeJson: beforeJson,
        afterJson: afterJson,
        at: fromTs(at),
      );
}
