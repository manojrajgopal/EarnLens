import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/account_controller.dart';
import '../application/account_summaries.dart';
import 'account_avatar.dart';
import 'account_form_screen.dart';
import 'account_switcher_sheet.dart';

/// Checkbox list of individual accounts for a combined account. Shows,
/// as the selection changes, whether the same set is already combined.
class MemberSelection extends ConsumerWidget {
  const MemberSelection({super.key, required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // Archived accounts can stay in a combination but aren't offered anew.
    final accounts = ref.watch(accountsProvider).where((a) => !a.isArchived || selected.contains(a.id)).toList();
    return EarnCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
      child: Column(children: [
        for (final (i, a) in accounts.indexed) ...[
          if (i > 0) Divider(height: 1, indent: 18, endIndent: 18, color: c.line),
          CheckboxListTile(
            value: selected.contains(a.id),
            onChanged: (v) => onChanged(v == true ? {...selected, a.id} : ({...selected}..remove(a.id))),
            secondary: AccountAvatar.of(a, size: 40, locked: a.requiresPin),
            title: Text(a.name, style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
            subtitle: Text('${a.type.label} · ${a.currencyCode}${a.isArchived ? ' · Archived' : ''}',
                style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        ],
      ]),
    );
  }
}

/// The combined account that already has exactly [selected] as members.
CombinedAccount? duplicateOf(WidgetRef ref, Set<String> selected, {String? exceptId}) {
  if (selected.length < 2) return null;
  final key = CombinedAccount.memberKeyOf(selected);
  for (final k in ref.watch(combinedAccountsProvider)) {
    if (k.memberKey == key && k.id != exceptId) return k;
  }
  return null;
}

/// Warning shown while the selection duplicates an existing combination,
/// with a shortcut to open that one instead.
class DuplicateNotice extends ConsumerWidget {
  const DuplicateNotice({super.key, required this.existing});
  final CombinedAccount existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: EarnCard(
        tint: c.warningSoft,
        radius: AppRadius.md,
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: c.warning),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              'These accounts are already combined as "${existing.name}". The order you pick them in doesn\'t matter.',
              style: AppType.bodySmall.copyWith(color: c.ink),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (await openAccountView(context, ref, CombinedView(existing.id)) && context.mounted) {
                context.go('/home');
              }
            },
            child: const Text('Open it'),
          ),
        ]),
      ),
    );
  }
}

/// Explains how a combined account handles members in different currencies.
class CurrencyNotice extends StatelessWidget {
  const CurrencyNotice({super.key, required this.display, required this.memberCurrencies});
  final String display;
  final Set<String> memberCurrencies;

  @override
  Widget build(BuildContext context) {
    final others = memberCurrencies.difference({display});
    if (others.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: InfoBanner(
        icon: Icons.currency_exchange_rounded,
        text: 'Members use ${memberCurrencies.join(', ')}. Totals add up $display only; '
            '${others.join(', ')} income is listed separately. EarnLens never converts currencies.',
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c.accentText),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: AppType.bodySmall.copyWith(color: c.ink))),
      ]),
    );
  }
}

/// Create a combined account, or edit [combinedId]'s name, avatar and
/// currency (members are changed on their own screen).
class CombinedFormScreen extends ConsumerStatefulWidget {
  const CombinedFormScreen({super.key, this.combinedId});
  final String? combinedId;

  @override
  ConsumerState<CombinedFormScreen> createState() => _CombinedFormScreenState();
}

class _CombinedFormScreenState extends ConsumerState<CombinedFormScreen> {
  final _form = GlobalKey<FormState>();
  late final CombinedAccount? _existing =
      widget.combinedId == null ? null : ref.read(combinedByIdProvider(widget.combinedId!));
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late String _emoji = _existing?.emoji ?? '👥';
  late int _color = _existing?.colorIndex ?? 1;
  late String? _image = _existing?.avatarImage;
  late Set<String> _members = {...?_existing?.memberIds};
  late String? _currency = _existing?.currencyCode;

  bool get _editing => _existing != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Set<String> _memberCurrencies() => {
        for (final a in ref.read(accountsProvider))
          if (_members.contains(a.id)) a.currencyCode,
      };

  /// The chosen currency if a member uses it, else the most common one.
  String _displayCurrency() {
    final counts = <String, int>{};
    for (final a in ref.read(accountsProvider)) {
      if (_members.contains(a.id)) counts[a.currencyCode] = (counts[a.currencyCode] ?? 0) + 1;
    }
    if (_currency != null && counts.containsKey(_currency)) return _currency!;
    if (counts.isEmpty) return _currency ?? Currency.inr.code;
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  Future<void> _pickPhoto() async {
    final picked = await ref.read(fileServiceProvider).pick(extensions: const ['jpg', 'jpeg', 'png', 'webp']);
    if (picked == null) return;
    try {
      final png = await squareAvatarPng(picked.bytes);
      if (mounted) setState(() => _image = png);
    } on Object {
      if (mounted) showMessage(context, 'That photo could not be read. Try a JPG or PNG image.');
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final router = GoRouter.of(context);
    final now = ref.read(clockProvider).now();
    final controller = ref.read(accountControllerProvider);
    final base = _existing ??
        CombinedAccount(
          id: ref.read(idProvider).newId(),
          name: '',
          currencyCode: _displayCurrency(),
          memberIds: _members.toList(),
          createdAt: now,
          updatedAt: now,
        );
    final combined = base.copyWith(
      name: _name.text.trim(),
      avatarEmoji: _emoji,
      colorIndex: _color,
      avatarImage: _image,
      clearAvatarImage: _image == null,
      currencyCode: _displayCurrency(),
      updatedAt: now,
    );
    try {
      if (_editing) {
        await controller.updateCombined(combined);
        if (mounted) showMessage(context, 'Combined account updated');
        if (router.canPop()) router.pop();
      } else {
        await controller.createCombined(combined, open: true);
        if (mounted) showMessage(context, '"${combined.name}" created');
        router.go('/home');
      }
    } on DuplicateCombinationException catch (e) {
      if (!mounted) return;
      final open = await confirmDialog(
        context,
        title: 'Already combined',
        message: '${e.message} Open the existing combined account instead?',
        confirm: 'Open "${e.existingName}"',
      );
      if (open && mounted && await openAccountView(context, ref, CombinedView(e.existingId))) router.go('/home');
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _delete() async {
    final existing = _existing!;
    final members = ref.read(combinedMembersProvider(existing.id)).map((m) => m.name).join(', ');
    final ok = await confirmDialog(
      context,
      title: 'Delete "${existing.name}"?',
      message: 'Only this combination is removed. $members keep all of their income, payments and history.',
      confirm: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    if (await runGuarded(context, () => ref.read(accountControllerProvider).deleteCombined(existing.id),
        success: 'Combined account deleted')) {
      router.go('/settings/accounts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_editing && ref.watch(combinedByIdProvider(_existing!.id)) == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox());
    }
    final duplicate = _editing ? null : duplicateOf(ref, _members);
    final members = _editing ? ref.watch(combinedMembersProvider(_existing!.id)) : const <Account>[];
    final display = _displayCurrency();
    final currencies = _editing ? {for (final m in members) m.currencyCode} : _memberCurrencies();
    final canSave = _editing || (_members.length >= 2 && duplicate == null);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(_editing ? 'Combined account' : 'Combine accounts')),
      body: Form(
        key: _form,
        child: EarnPageList(children: [
          Center(
            child: Column(children: [
              AccountAvatar(emoji: _emoji, colorIndex: _color, image: _image, size: 88, ring: true),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(_image == null ? 'Add photo' : 'Change photo'),
                ),
                if (_image != null)
                  TextButton(onPressed: () => setState(() => _image = null), child: const Text('Remove photo')),
              ]),
            ]),
          ),
          if (!_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: InfoBanner(
                icon: Icons.layers_outlined,
                text: 'A combined account adds up its members\' figures live. It never copies or changes their '
                    'records and doesn\'t count toward the ${Account.maxAccounts}-account limit.',
              ),
            ),
          TextFormField(
            controller: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Household, Family + Studio'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
          ),
          if (_image == null) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in const ['👥', '🏠', '👨‍👩‍👧', '🤝', '💼', '🌍', '💞', '⭐'])
                EmojiChoice(emoji: e, selected: e == _emoji, onTap: () => setState(() => _emoji = e)),
            ]),
          ],
          const SizedBox(height: AppSpace.md),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < accountColors.length; i++)
              ColorChoice(index: i, selected: i == _color, onTap: () => setState(() => _color = i)),
          ]),
          SettingsGroupHeader(_editing ? 'Members' : 'Choose at least two accounts'),
          if (_editing) ...[
            EarnCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
              child: Column(children: [
                for (final m in members)
                  ListTile(
                    leading: AccountAvatar.of(m, size: 40, locked: m.requiresPin),
                    title: Text(m.name, style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                    subtitle: Text('${m.type.label} · ${m.currencyCode}'),
                  ),
                SettingsTile(
                  icon: Icons.group_add_outlined,
                  title: 'Add or remove members',
                  onTap: () => context.push('/settings/accounts/combined/${_existing!.id}/members'),
                ),
              ]),
            ),
          ] else ...[
            MemberSelection(selected: _members, onChanged: (s) => setState(() => _members = s)),
            if (duplicate != null) DuplicateNotice(existing: duplicate),
          ],
          if (currencies.length > 1) ...[
            const SizedBox(height: AppSpace.md),
            SelectField<String>(
              label: 'Show totals in',
              value: display,
              values: currencies.toList()..sort(),
              itemLabel: (code) => '$code · ${Currency.byCode(code).name}',
              onChanged: (code) => setState(() => _currency = code),
            ),
          ],
          CurrencyNotice(display: display, memberCurrencies: currencies),
          const SizedBox(height: AppSpace.lg),
          BusyButton(
            label: _editing ? 'Save changes' : 'Create combined account',
            accent: true,
            onPressed: canSave ? _save : null,
          ),
          if (_editing) ...[
            const SizedBox(height: AppSpace.md),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: c.error),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete combined account'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Adds or removes members of a combined account. Totals recalculate as soon
/// as it is saved; no records move.
class CombinedMembersScreen extends ConsumerStatefulWidget {
  const CombinedMembersScreen({super.key, required this.combinedId});
  final String combinedId;

  @override
  ConsumerState<CombinedMembersScreen> createState() => _CombinedMembersScreenState();
}

class _CombinedMembersScreenState extends ConsumerState<CombinedMembersScreen> {
  late Set<String> _members = {...?ref.read(combinedByIdProvider(widget.combinedId))?.memberIds};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final existing = ref.watch(combinedByIdProvider(widget.combinedId));
    if (existing == null) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final before = existing.memberIds.toSet();
    final names = {for (final a in ref.watch(accountsProvider)) a.id: a.name};
    final added = _members.difference(before).map((id) => names[id]).join(', ');
    final removed = before.difference(_members).map((id) => names[id]).join(', ');
    final duplicate = duplicateOf(ref, _members, exceptId: existing.id);
    final changed = added.isNotEmpty || removed.isNotEmpty;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text('Members of ${existing.name}')),
      body: EarnPageList(children: [
        Text('Choose at least two accounts. Figures recalculate from their records as soon as you save.',
            style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        const SizedBox(height: AppSpace.md),
        MemberSelection(
          selected: _members,
          onChanged: (s) => setState(() => _members = s),
        ),
        if (duplicate != null) DuplicateNotice(existing: duplicate),
        if (changed) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            icon: Icons.sync_alt_rounded,
            text: [
              if (added.isNotEmpty) 'Adding $added.',
              if (removed.isNotEmpty) 'Removing $removed (their own data is not touched).',
            ].join(' '),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        BusyButton(
          label: 'Save members',
          accent: true,
          onPressed: !changed || _members.length < 2 || duplicate != null
              ? null
              : () async {
                  final router = GoRouter.of(context);
                  if (await runGuarded(
                    context,
                    () => ref.read(accountControllerProvider).setMembers(existing.id, _members.toList()),
                    success: 'Members updated',
                  )) {
                    router.pop();
                  }
                },
        ),
      ]),
    );
  }
}
