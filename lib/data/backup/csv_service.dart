import '../../core/clock.dart';
import '../../core/date_time/local_date.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/calculation/earnings_calculator.dart';
import '../../domain/calculation/earnings_snapshot.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/records.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money_parser.dart';
import '../../domain/repositories/repositories.dart';

class CsvImportReport {
  const CsvImportReport({required this.imported, required this.duplicates, required this.errors});
  final int imported;
  final int duplicates;

  /// One message per rejected line ("Line 4: unknown income source 'X'").
  final List<String> errors;
}

/// CSV export of transactions and monthly summaries, and validated import of
/// transactions. Amounts are written as plain decimals in major units.
class CsvService {
  CsvService(this.clock, this.ids);

  final Clock clock;
  final IdGenerator ids;

  static const ledgerHeader = ['date', 'period_month', 'source', 'type', 'amount', 'currency', 'status', 'notes'];

  String exportLedger(EarningsSnapshot snap, {Set<String>? sourceIds, DateRange? range}) {
    final rows = <List<String>>[ledgerHeader];
    final entries = [...snap.ledger]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in entries) {
      if (sourceIds != null && !sourceIds.contains(e.sourceId)) continue;
      if (range != null && !range.contains(e.date)) continue;
      final c = Currency.byCode(e.currencyCode);
      rows.add([
        e.date.toIso(),
        e.periodMonth.toIso(),
        snap.source(e.sourceId)?.name ?? e.sourceId,
        e.type.name,
        MoneyParser.toInput(e.amountMinor, c),
        e.currencyCode,
        e.status.name,
        e.notes ?? '',
      ]);
    }
    return encode(rows);
  }

  String exportMonthlySummary(
    EarningsSnapshot snap,
    EarningsCalculator calc,
    YearMonth from,
    YearMonth to,
    int nowMicros,
    String currencyCode, {
    Set<String>? sourceIds,
  }) {
    final c = Currency.byCode(currencyCode);
    String money(int v) => MoneyParser.toInput(v, c);
    final rows = <List<String>>[
      ['month', 'source', 'expected', 'actual', 'received', 'deductions', 'outstanding', 'variance', 'currency'],
    ];
    for (var m = from; !m.isAfter(to); m = m.next) {
      final s = calc.summarize(snap, DateRange.month(m), nowMicros, currencyCode: currencyCode, sourceIds: sourceIds);
      for (final x in s.sources) {
        if (x.expected == 0 && x.actual == 0 && x.received == 0) continue;
        rows.add([
          m.toIso(),
          x.source.name,
          money(x.expected),
          money(x.actual),
          money(x.received),
          money(x.deductions),
          money(x.outstanding),
          money(x.variance),
          currencyCode,
        ]);
      }
    }
    return encode(rows);
  }

  /// Validates every line before importing anything. Lines with errors are
  /// reported, never silently skipped; exact duplicates are reported as such.
  Future<CsvImportReport> importLedger(String csv, EarningsSnapshot snap, RecordsRepository repo) async {
    final rows = decode(csv);
    if (rows.isEmpty) throw const ValidationException('The file is empty.');
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final idx = {for (final h in ledgerHeader) h: header.indexOf(h)};
    for (final required in ['date', 'source', 'type', 'amount']) {
      if (idx[required]! < 0) throw ValidationException('Missing column "$required".');
    }
    final byName = {for (final s in snap.sources) s.name.trim().toLowerCase(): s};
    final valid = <LedgerEntry>[];
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.every((c) => c.trim().isEmpty)) continue;
      String col(String name) => idx[name]! >= 0 && idx[name]! < r.length ? r[idx[name]!].trim() : '';
      final line = i + 1;
      final source = byName[col('source').toLowerCase()];
      if (source == null) {
        errors.add('Line $line: unknown income source "${col('source')}"');
        continue;
      }
      final date = LocalDate.tryParse(col('date'));
      if (date == null) {
        errors.add('Line $line: date must be yyyy-mm-dd');
        continue;
      }
      final type = LedgerType.values.where((t) => t.name == col('type')).firstOrNull;
      if (type == null) {
        errors.add('Line $line: type must be one of ${LedgerType.values.map((t) => t.name).join(', ')}');
        continue;
      }
      final currencyCode = col('currency').isEmpty ? source.currencyCode : col('currency').toUpperCase();
      if (currencyCode != source.currencyCode) {
        errors.add('Line $line: currency $currencyCode does not match ${source.name} (${source.currencyCode})');
        continue;
      }
      final amount = MoneyParser.parseMinor(col('amount'), Currency.byCode(currencyCode),
          allowNegative: type == LedgerType.adjustment);
      if (amount == null || amount == 0) {
        errors.add('Line $line: invalid amount "${col('amount')}"');
        continue;
      }
      YearMonth period;
      try {
        period = col('period_month').isEmpty ? date.yearMonth : YearMonth.parse(col('period_month'));
      } on FormatException {
        errors.add('Line $line: period_month must be yyyy-mm');
        continue;
      }
      final status = LedgerStatus.values.where((s) => s.name == col('status')).firstOrNull ?? LedgerStatus.completed;
      final now = clock.now();
      valid.add(LedgerEntry(
        id: ids.newId(),
        sourceId: source.id,
        type: type,
        amountMinor: amount,
        currencyCode: currencyCode,
        periodMonth: period,
        date: date,
        status: status,
        notes: col('notes').isEmpty ? null : col('notes'),
        createdAt: now,
        updatedAt: now,
      ));
    }
    if (errors.isNotEmpty) {
      return CsvImportReport(imported: 0, duplicates: 0, errors: errors);
    }
    var imported = 0;
    var duplicates = 0;
    for (final e in valid) {
      try {
        await repo.addLedgerEntry(e);
        imported++;
      } on DuplicateEntryException {
        duplicates++;
      }
    }
    return CsvImportReport(imported: imported, duplicates: duplicates, errors: const []);
  }

  // RFC 4180 encoding with formula-injection protection for spreadsheet apps.
  static String encode(List<List<String>> rows) => rows.map((r) => r.map(_cell).join(',')).join('\r\n');

  static String _cell(String v) {
    var s = v;
    if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) s = "'$s";
    if (s.contains(RegExp(r'[",\r\n]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }

  static List<List<String>> decode(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    final text = input.startsWith('﻿') ? input.substring(1) : input;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }
}
