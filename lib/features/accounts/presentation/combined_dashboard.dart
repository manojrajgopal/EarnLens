import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../../shared/widgets/organic.dart';
import '../../../domain/models/account.dart';
import '../application/combined_breakdown.dart';
import 'account_avatar.dart';
import 'account_switcher_sheet.dart';
import 'combined_form_screen.dart';

/// Dashboard card of a combined account: each member's share of this
/// month's earnings, plus income in other currencies (listed, never added).
/// Tapping a member opens their breakdown without switching accounts.
class CombinedMembersCard extends ConsumerWidget {
  const CombinedMembersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combined = ref.watch(activeCombinedProvider);
    if (combined == null) return const SizedBox.shrink();
    final c = context.colors;
    final rows = ref.watch(memberContributionsProvider);
    final money = ref.watch(moneyFormatterProvider);
    final locale = ref.watch(localeProvider);
    final others = [
      for (final r in rows)
        for (final e in r.otherCurrencies.entries)
          '${MoneyFormatter(locale, Currency.byCode(e.key)).fraction(e.value, decimals: 0)} (${r.account.name})',
    ];
    return EarnCard(
      seed: 77,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text('Members this month', style: AppType.sectionStrong.copyWith(color: c.ink)),
            ),
          ),
          LinkAction(
            label: 'Edit',
            icon: Icons.tune_rounded,
            compact: true,
            onTap: () => context.push('/settings/accounts/combined/${combined.id}'),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Added up live from each account\'s own records. Read-only here.',
          style: AppType.bodySmall.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AppSpace.md),
        for (final r in rows)
          _MemberRow(
            contribution: r,
            amount: money.fraction(r.earned, decimals: 0),
            onTap: () => context.push('/home/member/${r.account.id}'),
          ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            icon: Icons.currency_exchange_rounded,
            text: 'Not included in ${combined.currencyCode} totals: ${others.join(', ')}.',
          ),
        ],
      ]),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.contribution, required this.amount, required this.onTap});
  final MemberContribution contribution;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = contribution.account;
    final pct = (contribution.share * 100).round();
    return Semantics(
      button: true,
      label: '${a.name}, $pct percent. Open breakdown',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: ExcludeSemantics(
            child: Row(children: [
              AccountAvatar.of(a, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                      ),
                    ),
                    AmountText(amount, style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: GradientProgress(value: contribution.share)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text('$pct%', textAlign: TextAlign.end, style: AppType.caption.copyWith(color: c.inkMuted)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Read-only breakdown of one member inside the open combined account.
/// Changing anything requires explicitly opening the member's own account.
class MemberBreakdownScreen extends ConsumerWidget {
  const MemberBreakdownScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final combined = ref.watch(activeCombinedProvider);
    final rows = ref.watch(memberContributionsProvider);
    final row = rows.where((r) => r.account.id == accountId).firstOrNull;
    if (combined == null || row == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.groups_2_outlined,
          title: 'Not part of this view',
          message: 'Open a combined account that includes this member to see their breakdown.',
        ),
      );
    }
    final a = row.account;
    final money = ref.watch(moneyFormatterProvider);
    final calc = ref.watch(earningsCalculatorProvider);
    final today = ref.watch(todayProvider);
    final code = combined.currencyCode;
    String rate(EarningUnit unit) =>
        '${money.fraction(calc.combinedRate(row.snapshot, unit, today, currencyCode: code), decimals: 2)}${unit.shortLabel}';
    final sources = row.snapshot.sources.where((s) => s.status != SourceStatus.archived).toList();
    final recent = [...row.snapshot.ledger]..sort((x, y) => y.date.compareTo(x.date));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + AppSpace.xl),
        children: [
          EarnCard(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AccountAvatar.of(a, size: 52, ring: true),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.name, style: AppType.title.copyWith(color: AppColors.white)),
                    Text('${a.type.label} · in ${combined.name}',
                        style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.lg),
              Text('Earned this month', style: AppType.caption.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
              AmountText(money.fraction(row.earned), style: AppType.amountLarge.copyWith(color: AppColors.white)),
              const SizedBox(height: 4),
              Text('${(row.share * 100).round()}% of ${combined.name} this month',
                  style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
            ]),
          ),
          const SizedBox(height: AppSpace.md),
          Row(children: [
            Expanded(child: _Stat(label: 'Expected', value: money.minor(row.month.expected))),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: _Stat(label: 'Received', value: money.minor(row.month.received))),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: _Stat(label: 'Outstanding', value: money.minor(row.month.outstanding))),
          ]),
          const SectionHeader('Rates'),
          EarnCard(
            child: Wrap(spacing: AppSpace.lg, runSpacing: AppSpace.sm, children: [
              for (final u in const [EarningUnit.hour, EarningUnit.day, EarningUnit.month, EarningUnit.year])
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.label, style: AppType.caption.copyWith(color: c.inkMuted)),
                  AmountText(rate(u), style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                ]),
            ]),
          ),
          SectionHeader('Income sources (${sources.length})'),
          EarnCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(children: [
              if (sources.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Text('No income sources yet.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                ),
              for (final s in sources)
                ListTile(
                  leading: SourceAvatar(s, size: 40),
                  title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${s.kind.label} · ${s.currencyCode}'),
                ),
            ]),
          ),
          if (recent.isNotEmpty) ...[
            const SectionHeader('Recent transactions'),
            EarnCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Column(children: [
                for (final e in recent.take(5))
                  ListTile(
                    title: Text('${e.type.label} · ${row.snapshot.source(e.sourceId)?.name ?? ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(formatDate(e.date)),
                    trailing: AmountText(
                      MoneyFormatter(ref.watch(localeProvider), Currency.byCode(e.currencyCode)).minor(e.amountMinor),
                      style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          InfoBanner(
            icon: Icons.visibility_outlined,
            text: 'You are viewing ${a.name} inside ${combined.name}. Nothing can be changed here — open '
                '${a.name}\'s own account to edit income or record payments.',
          ),
          const SizedBox(height: AppSpace.md),
          GradientButton(
            onPressed: () async {
              if (await openAccountView(context, ref, IndividualView(a.id)) && context.mounted) context.go('/home');
            },
            child: Text('Open ${a.name}\'s account'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlobSurface(
      spec: BlobSpec(seed: label.hashCode & 0x3ff, radius: AppRadius.md + 6, wobble: 0.4),
      color: c.card,
      shadows: AppShadows.card(Theme.of(context).brightness),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AmountText(value, style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
        ),
      ]),
    );
  }
}
