import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/backup/csv_service.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../settings/presentation/settings_widgets.dart';

enum _ExportKind { transactions, monthly }

String _pad(int v) => v.toString().padLeft(2, '0');

Future<void> showCsvExportSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CsvExportSheet(),
    );

class _CsvExportSheet extends ConsumerStatefulWidget {
  const _CsvExportSheet();

  @override
  ConsumerState<_CsvExportSheet> createState() => _CsvExportSheetState();
}

class _CsvExportSheetState extends ConsumerState<_CsvExportSheet> {
  _ExportKind _kind = _ExportKind.transactions;
  String? _sourceId; // null = all sources
  LocalDate? _from;
  LocalDate? _to;
  late YearMonth _monthFrom;
  late YearMonth _monthTo;

  @override
  void initState() {
    super.initState();
    final now = ref.read(todayProvider).yearMonth;
    _monthTo = now;
    _monthFrom = now.addMonths(-11);
  }

  List<YearMonth> _months() {
    final today = ref.read(todayProvider);
    final sources = ref.read(sourcesProvider);
    var earliest = today.yearMonth.addMonths(-23);
    for (final s in sources) {
      if (s.startDate.yearMonth.isBefore(earliest)) earliest = s.startDate.yearMonth;
    }
    final list = <YearMonth>[];
    for (var m = today.yearMonth.addMonths(12); !m.isBefore(earliest); m = m.previous) {
      list.add(m);
    }
    return list;
  }

  Future<void> _run({required bool share}) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_kind == _ExportKind.transactions && _from != null && _to != null && _to!.isBefore(_from!)) {
      messenger.showSnackBar(const SnackBar(content: Text('The end date must be on or after the start date.')));
      return;
    }
    if (_kind == _ExportKind.monthly && _monthTo.isBefore(_monthFrom)) {
      messenger.showSnackBar(const SnackBar(content: Text('The last month must be on or after the first month.')));
      return;
    }
    try {
      final csvService = ref.read(csvServiceProvider);
      final snap = ref.read(snapshotProvider);
      final ids = _sourceId == null ? null : {_sourceId!};
      final today = ref.read(todayProvider);
      final stamp = '${today.year}-${_pad(today.month)}-${_pad(today.day)}';
      final String csv;
      final String name;
      if (_kind == _ExportKind.transactions) {
        DateRange? range;
        if (_from != null || _to != null) {
          range = DateRange(_from ?? LocalDate(1900, 1, 1), (_to ?? LocalDate(9999, 12, 30)).addDays(1));
        }
        csv = csvService.exportLedger(snap, sourceIds: ids, range: range);
        name = 'earnlens-transactions-$stamp.csv';
      } else {
        csv = csvService.exportMonthlySummary(
          snap,
          ref.read(earningsCalculatorProvider),
          _monthFrom,
          _monthTo,
          ref.read(clockProvider).now().microsecondsSinceEpoch,
          ref.read(currencyProvider).code,
          sourceIds: ids,
        );
        name = 'earnlens-monthly-${_monthFrom.toIso()}-to-${_monthTo.toIso()}.csv';
      }
      // A BOM lets spreadsheet apps detect UTF-8 (currency symbols, names).
      final bytes = Uint8List.fromList(utf8.encode('﻿$csv'));
      final files = ref.read(fileServiceProvider);
      if (share) {
        await files.share(name, bytes, 'text/csv');
      } else if (!await files.save(name, bytes, 'text/csv')) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(share ? 'Export ready to share' : 'Saved $name')));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('The export could not be created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sources = ref.watch(sourcesProvider);
    final today = ref.watch(todayProvider);
    final months = _months();
    final currency = ref.watch(currencyProvider).code;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHeader(
              icon: Icons.file_download_outlined,
              tone: SettingsTone.sky,
              title: 'Export CSV',
              subtitle: 'Open the file in any spreadsheet app.',
            ),
            const SizedBox(height: AppSpace.lg),
            ChoicePills<_ExportKind>(
              values: _ExportKind.values,
              selected: _kind,
              label: (k) => k == _ExportKind.transactions ? 'Transactions' : 'Monthly summary',
              onSelected: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: AppSpace.lg),
            SelectField<String?>(
              label: 'Income sources',
              value: sources.any((s) => s.id == _sourceId) ? _sourceId : null,
              values: [null, for (final s in sources) s.id],
              itemLabel: (id) => id == null ? 'All sources' : sources.firstWhere((s) => s.id == id).name,
              onChanged: (v) => setState(() => _sourceId = v),
            ),
            const SizedBox(height: AppSpace.lg),
            if (_kind == _ExportKind.transactions) ...[
              DateField(
                label: 'From (optional)',
                initial: _from,
                optional: true,
                lastDate: today.addDays(3660),
                onChanged: (d) => setState(() => _from = d),
              ),
              const SizedBox(height: AppSpace.md),
              DateField(
                label: 'To (optional)',
                initial: _to,
                optional: true,
                lastDate: today.addDays(3660),
                onChanged: (d) => setState(() => _to = d),
              ),
              const SizedBox(height: AppSpace.sm),
              Text('Leave both empty to export every transaction. Amounts are in major units (e.g. 1250.50).',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            ] else ...[
              SelectField<YearMonth>(
                label: 'First month',
                value: months.contains(_monthFrom) ? _monthFrom : months.last,
                values: months,
                itemLabel: formatMonth,
                onChanged: (v) => setState(() => _monthFrom = v),
              ),
              const SizedBox(height: AppSpace.md),
              SelectField<YearMonth>(
                label: 'Last month',
                value: months.contains(_monthTo) ? _monthTo : months.first,
                values: months,
                itemLabel: formatMonth,
                onChanged: (v) => setState(() => _monthTo = v),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'One row per source and month: expected, actual, received, deductions, outstanding and variance. '
                'Only sources in your profile currency ($currency) are included.',
                style: AppType.bodySmall.copyWith(color: c.inkMuted),
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            BusyButton(label: 'Save CSV', accent: true, onPressed: () => _run(share: false)),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  foregroundColor: c.accentText,
                  side: BorderSide(color: c.accentText.withValues(alpha: 0.3), width: 1.2),
                ),
                onPressed: () => _run(share: true),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share…'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Picks a CSV file, imports it and shows the full report.
Future<void> runCsvImport(BuildContext context, WidgetRef ref) async {
  final picked = await ref.read(fileServiceProvider).pick(extensions: const ['csv', 'txt']);
  if (picked == null || !context.mounted) return;
  CsvImportReport? report;
  String? error;
  try {
    final text = utf8.decode(picked.bytes, allowMalformed: true);
    report = await ref
        .read(csvServiceProvider)
        .importLedger(text, ref.read(snapshotProvider), ref.read(recordsRepositoryProvider));
  } on AppException catch (e) {
    error = e.message;
  } on Object {
    error = 'This file could not be read as CSV.';
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ImportReportSheet(fileName: picked.name, report: report, error: error),
  );
}

class _ImportReportSheet extends StatelessWidget {
  const _ImportReportSheet({required this.fileName, this.report, this.error});
  final String fileName;
  final CsvImportReport? report;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    final failed = r == null || r.errors.isNotEmpty;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BlobBadge(
                size: 42,
                seed: failed ? 3 : 4,
                color: failed ? c.errorSoft : c.positiveSoft,
                child: Icon(failed ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: failed ? c.error : c.positive),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(failed ? 'Nothing was imported' : 'Import complete', style: AppType.title),
                  const SizedBox(height: 4),
                  Text(fileName, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                ]),
              ),
            ]),
            const SizedBox(height: AppSpace.lg),
            if (r == null)
              Text(error ?? 'The file could not be imported.', style: AppType.body)
            else if (r.errors.isEmpty) ...[
              Text('${r.imported} transaction${r.imported == 1 ? '' : 's'} imported.', style: AppType.body),
              if (r.duplicates > 0)
                Text('${r.duplicates} duplicate${r.duplicates == 1 ? ' was' : 's were'} already recorded and skipped.',
                    style: AppType.body),
            ] else ...[
              Text(
                '${r.errors.length} line${r.errors.length == 1 ? ' has a problem' : 's have problems'}. '
                'To keep your records consistent, nothing is imported until every line is valid. '
                'Fix these lines and import the file again:',
                style: AppType.body,
              ),
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: ShapeDecoration(
                  color: c.errorSoft,
                  shape: BlobBorder(BlobShapes.cloud(5, radius: 18, wobble: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in r.errors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• $e', style: AppType.bodySmall.copyWith(color: c.error)),
                    ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

/// Explains the expected CSV columns.
class CsvFormatHelp extends StatelessWidget {
  const CsvFormatHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mono = AppType.bodySmall.copyWith(fontFamily: 'monospace', color: c.ink);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Expected columns (first row must be the header):', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
      const SizedBox(height: AppSpace.sm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: ShapeDecoration(
          color: c.cardHigh,
          shape: BlobBorder(BlobShapes.cloud(6, radius: 18, wobble: 0.4)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            '${CsvService.ledgerHeader.join(',')}\n2026-11-01,2026-10,Acme Corp,received,85000.00,INR,completed,October pay',
            style: mono,
          ),
        ),
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        'Required: date (yyyy-mm-dd), source (exact income source name), type '
        '(received, earned, adjustment, deduction or reversal), amount. '
        'Optional: period_month (yyyy-mm, defaults to the date\'s month), currency (must match the source), '
        'status (pending, completed or cancelled; defaults to completed), notes. Exporting transactions produces exactly this format.',
        style: AppType.bodySmall.copyWith(color: c.inkMuted),
      ),
    ]);
  }
}

/// Wrapper kept small so the data screen can show the CSV section compactly.
class CsvSectionTiles extends ConsumerWidget {
  const CsvSectionTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsGroup(
        title: 'Spreadsheets (CSV)',
        footer: ref.watch(isReadOnlyViewProvider)
            ? 'Exports cover every member of this combined account. Import into an individual account.'
            : 'Exports and imports cover the open account only.',
        children: [
          SettingsTile(
            icon: Icons.file_download_outlined,
            tone: SettingsTone.sky,
            title: 'Export CSV',
            subtitle: 'Transactions or monthly summaries',
            onTap: () => showCsvExportSheet(context),
          ),
          if (!ref.watch(isReadOnlyViewProvider))
            SettingsTile(
              icon: Icons.file_upload_outlined,
              tone: SettingsTone.peach,
              title: 'Import transactions from CSV',
              subtitle: 'Every line is checked before anything is added',
              onTap: () => runCsvImport(context, ref),
            ),
          const SettingsBlock(child: CsvFormatHelp()),
        ],
      );
}
