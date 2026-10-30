import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/fraction.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/account_controller.dart';
import 'account_avatar.dart';

/// Locales offered for an account's number formatting (null = profile's).
const accountLocales = <String?, String>{
  null: 'Same as my profile',
  'en_IN': 'English (India) · 1,23,456.78',
  'en_US': 'English (United States) · 123,456.78',
  'en_GB': 'English (United Kingdom) · 123,456.78',
  'de_DE': 'German · 123.456,78',
  'fr_FR': 'French · 123 456,78',
};

/// Create a new individual account, or edit [accountId].
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.accountId});
  final String? accountId;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Account? _existing = widget.accountId == null ? null : ref.read(accountByIdProvider(widget.accountId!));
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late final _description = TextEditingController(text: _existing?.description ?? '');
  late final TextEditingController _target;
  late AccountType _type = _existing?.type ?? AccountType.personal;
  late String? _emoji = _existing?.avatarEmoji;
  late int _color = _existing?.colorIndex ?? ref.read(accountsProvider).length % accountColors.length;
  late String? _image = _existing?.avatarImage;
  late Currency _currency = Currency.byCode(
      _existing?.currencyCode ?? ref.read(profileStreamProvider).value?.currencyCode ?? Currency.inr.code);
  late String? _locale = _existing?.locale;
  bool _openAfter = true;

  bool get _editing => _existing != null;

  @override
  void initState() {
    super.initState();
    final target = _existing?.monthlyTargetMinor;
    _target = TextEditingController(
      text: target == null
          ? ''
          : Fraction.fromInt(target).divInt(_currency.minorPerMajor).toDecimalString(_currency.minorDigits),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
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
    final now = ref.read(clockProvider).now();
    final description = _description.text.trim();
    final target = parseMoney(_target, _currency);
    final controller = ref.read(accountControllerProvider);
    final router = GoRouter.of(context);
    final base = _existing ??
        Account(
          id: ref.read(idProvider).newId(),
          name: '',
          type: _type,
          currencyCode: _currency.code,
          createdAt: now,
          updatedAt: now,
        );
    final account = base.copyWith(
      name: _name.text.trim(),
      type: _type,
      avatarEmoji: _emoji ?? _type.defaultEmoji,
      colorIndex: _color,
      avatarImage: _image,
      clearAvatarImage: _image == null,
      description: description.isEmpty ? null : description,
      clearDescription: description.isEmpty,
      currencyCode: _currency.code,
      locale: _locale,
      clearLocale: _locale == null,
      monthlyTargetMinor: target,
      clearMonthlyTarget: target == null,
      updatedAt: now,
    );
    final ok = await runGuarded(context, () async {
      if (_editing) {
        await controller.updateAccount(account);
      } else {
        await controller.createAccount(account, open: _openAfter);
      }
    }, success: _editing ? 'Account updated' : 'Account "${account.name}" created');
    if (!ok) return;
    if (!_editing && _openAfter) {
      router.go('/home');
    } else if (router.canPop()) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = ref.watch(accountsProvider).length;
    if (!_editing && count >= Account.maxAccounts) {
      return Scaffold(
        appBar: AppBar(title: const Text('New account')),
        body: EmptyState(
          icon: Icons.group_off_outlined,
          title: 'Account limit reached',
          message: const AccountLimitException().message,
          action: 'Manage accounts',
          onAction: () => context.pushReplacement('/settings/accounts'),
        ),
      );
    }
    final emoji = _emoji ?? _type.defaultEmoji;
    final mixedCurrency = _editing && _currency.code != _existing!.currencyCode;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(_editing ? 'Edit account' : 'New account')),
      body: Form(
        key: _form,
        child: EarnPageList(
          children: [
            Center(
              child: Column(children: [
                AccountAvatar(emoji: emoji, colorIndex: _color, image: _image, size: 96, ring: true),
                const SizedBox(height: AppSpace.sm),
                Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_image == null ? 'Add photo' : 'Change photo'),
                  ),
                  if (_image != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _image = null),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Remove photo'),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: AppSpace.md),
            if (!_editing)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: Text(
                  '$count of ${Account.maxAccounts} accounts used. An account is a separate set of income, payments and '
                  'settings on this device — not a separate login.',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
              ),
            TextFormField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Account name', hintText: 'e.g. Family, Studio, Priya'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Give the account a name' : null,
            ),
            const SizedBox(height: AppSpace.md),
            Text('Type', style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            ChoicePills<AccountType>(
              values: AccountType.values,
              selected: _type,
              label: (t) => '${t.defaultEmoji} ${t.label}',
              onSelected: (t) => setState(() {
                // Follow the type's emoji unless the user picked one.
                if (_emoji == null || _emoji == _type.defaultEmoji) _emoji = null;
                _type = t;
              }),
            ),
            if (_image == null) ...[
              const SizedBox(height: AppSpace.lg),
              Text('Avatar', style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpace.sm),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final e in {_type.defaultEmoji, ...accountEmoji})
                  EmojiChoice(emoji: e, selected: e == emoji, onTap: () => setState(() => _emoji = e)),
              ]),
            ],
            const SizedBox(height: AppSpace.lg),
            Text('Colour', style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < accountColors.length; i++)
                ColorChoice(index: i, selected: i == _color, onTap: () => setState(() => _color = i)),
            ]),
            const SizedBox(height: AppSpace.lg),
            SelectField<Currency>(
              label: 'Currency',
              value: _currency,
              values: Currency.supported,
              itemLabel: (cur) => '${cur.code} · ${cur.name}',
              onChanged: (cur) => setState(() => _currency = cur),
              helper: mixedCurrency
                  ? 'Income already recorded keeps its own currency. Totals only add amounts in the account currency.'
                  : 'Totals are shown in this currency. EarnLens never converts between currencies.',
            ),
            const SizedBox(height: AppSpace.md),
            SelectField<String?>(
              label: 'Number format',
              value: _locale,
              values: accountLocales.keys.toList(),
              itemLabel: (l) => accountLocales[l]!,
              onChanged: (l) => setState(() => _locale = l),
            ),
            const SizedBox(height: AppSpace.md),
            MoneyField(
              controller: _target,
              currency: _currency,
              label: 'Monthly target (optional)',
              required: false,
              helper: 'Shown as a goal on this account\'s dashboard.',
            ),
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _description,
              maxLength: 200,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            if (!_editing)
              SettingsSwitch(
                title: 'Open it after creating',
                value: _openAfter,
                onChanged: (v) => setState(() => _openAfter = v),
              ),
            const SizedBox(height: AppSpace.lg),
            BusyButton(label: _editing ? 'Save changes' : 'Create account', accent: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class EmojiChoice extends StatelessWidget {
  const EmojiChoice({super.key, required this.emoji, required this.selected, required this.onTap});
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Avatar $emoji',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? c.accent : c.line, width: selected ? 2 : 1),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22), textScaler: TextScaler.noScaling),
        ),
      ),
    );
  }
}

class ColorChoice extends StatelessWidget {
  const ColorChoice({super.key, required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seriesAt(index);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Colour ${index + 1}',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? context.colors.ink : Colors.transparent, width: 3),
          ),
          child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
        ),
      ),
    );
  }
}
