import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/records.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../refresh/application/app_refresher.dart';

/// Searches income sources, bonuses/benefits, transactions and calendar
/// events stored on the device. With an empty query it lists all
/// transactions (newest first), so it doubles as the transaction history.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  String get _q => _controller.text.trim().toLowerCase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _match(Iterable<String?> fields) => _q.isEmpty || fields.any((f) => f != null && f.toLowerCase().contains(_q));

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(snapshotProvider);
    final events = ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[];
    final locale = ref.watch(moneyFormatterProvider).locale;
    final c = context.colors;
    MoneyFormatter fmt(String code) => MoneyFormatter(locale, Currency.byCode(code));

    final sources = _q.isEmpty
        ? const []
        : snap.sources.where((s) => _match([s.name, s.employer, s.categoryLabel, s.kind.label, s.notes])).toList();
    final items = _q.isEmpty
        ? const <CompensationItem>[]
        : snap.items.where((i) => _match([i.title, i.type.label, i.notes, i.taxNote])).toList();
    final ledger = [
      for (final e in snap.ledger)
        if (_match([
          snap.source(e.sourceId)?.name,
          e.type.label,
          e.notes,
          e.periodMonth.toIso(),
          formatMonth(e.periodMonth),
          MoneyParserText.plain(e.amountMinor, Currency.byCode(e.currencyCode)),
        ]))
          e,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final matchedEvents = _q.isEmpty
        ? const <CalendarEvent>[]
        : events.where((e) => !e.cancelled && _match([e.title, e.notes, e.type.label])).toList();
    final nothing = sources.isEmpty && items.isEmpty && ledger.isEmpty && matchedEvents.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: EarnPageList(
        onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.calendar}),
        children: [
          SearchBar(
            controller: _controller,
            autoFocus: widget.initialQuery.isEmpty,
            hintText: 'Sources, payments, bonuses, notes…',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(_controller.clear),
                ),
            ],
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(c.card),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(color: c.line),
            )),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.lg),
          if (nothing)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: _q.isEmpty ? 'No transactions yet' : 'No matches',
              message: _q.isEmpty
                  ? 'Payments, deductions and adjustments you record will be listed here.'
                  : 'Try a source name, an amount, a month such as "October", or a word from your notes.',
            ),
          if (sources.isNotEmpty) ...[
            const SectionHeader('Income sources'),
            for (final s in sources)
              _ResultCard(
                leading: SourceAvatar(s, size: 40),
                title: s.name,
                subtitle: '${s.kind.label} · ${s.status.label}',
                onTap: () => context.push('/income/${s.id}'),
              ),
          ],
          if (items.isNotEmpty) ...[
            const SectionHeader('Bonuses & benefits'),
            for (final i in items)
              _ResultCard(
                leading: const Icon(Icons.card_giftcard_rounded),
                title: i.title,
                subtitle: '${i.type.label}${i.planningDate == null ? '' : ' · ${formatDate(i.planningDate!)}'}',
                trailing: AmountText(fmt(i.currencyCode).minor(i.actualMinor ?? i.expectedMinor ?? 0), style: AppType.label),
                onTap: i.sourceId == null ? null : () => context.push('/income/${i.sourceId}/item?item=${i.id}'),
              ),
          ],
          if (ledger.isNotEmpty) ...[
            SectionHeader(_q.isEmpty ? 'All transactions' : 'Transactions'),
            for (final e in ledger.take(200))
              _ResultCard(
                leading: Icon(switch (e.type) {
                  LedgerType.received => Icons.south_west_rounded,
                  LedgerType.earned => Icons.trending_up_rounded,
                  LedgerType.adjustment => Icons.tune_rounded,
                  LedgerType.deduction => Icons.remove_circle_outline_rounded,
                  LedgerType.reversal => Icons.undo_rounded,
                }),
                title: snap.source(e.sourceId)?.name ?? 'Income',
                subtitle: '${e.type.label} · ${formatDate(e.date)} · for ${formatMonth(e.periodMonth)}'
                    '${e.status == LedgerStatus.completed ? '' : ' · ${e.status.label}'}',
                trailing: AmountText(fmt(e.currencyCode).minor(e.amountMinor), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/income/${e.sourceId}/entry?entry=${e.id}'),
              ),
          ],
          if (matchedEvents.isNotEmpty) ...[
            const SectionHeader('Calendar'),
            for (final e in matchedEvents)
              _ResultCard(
                leading: const Icon(Icons.event_note_rounded),
                title: e.title,
                subtitle: '${e.type.label} · ${formatDate(e.date)}',
                onTap: () => context.go('/calendar'),
              ),
          ],
        ],
      ),
    );
  }
}

/// Plain decimal text of an amount for matching searches like "31000".
abstract final class MoneyParserText {
  static String plain(int minor, Currency c) {
    final whole = minor.abs() ~/ c.minorPerMajor;
    return '$whole';
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.leading, required this.title, required this.subtitle, this.trailing, this.onTap});
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: EarnCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          radius: AppRadius.md,
          onTap: onTap,
          child: ListTile(
            leading: leading,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: trailing,
          ),
        ),
      );
}
