import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';

/// Pastel colour families for settings icon badges.
enum SettingsTone { violet, peach, mint, sky, rose }

/// (foreground, background) for a [SettingsTone] in the current brightness.
(Color, Color) settingsToneColors(BuildContext context, SettingsTone tone, {bool danger = false}) {
  final c = context.colors;
  if (danger) return (c.error, c.errorSoft);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final (Color fg, Color bg) = switch (tone) {
    SettingsTone.violet => (dark ? AppColors.lavenderOnDark : AppColors.violet, AppColors.lilacSoft),
    SettingsTone.peach => (AppColors.peach, AppColors.peachSoft),
    SettingsTone.mint => (AppColors.mint, AppColors.mintSoft),
    SettingsTone.sky => (AppColors.sky, AppColors.skySoft),
    SettingsTone.rose => (AppColors.seriesAt(5), AppColors.blush),
  };
  return dark ? (fg, fg.withValues(alpha: 0.16)) : (fg, bg);
}

/// Scaffold + width-constrained, padded list used by every settings-style
/// screen.
///
/// * Sub-pages (default): opaque background with a transparent app bar.
/// * [root] pages (the Settings tab): transparent scaffold so the shell's
///   lavender backdrop shows, with a large light headline instead of an app
///   bar; [actions] sit beside the headline.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.onRefresh,
    this.root = false,
    this.subtitle,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  /// Only for settings screens that display data (e.g. change history).
  final Future<void> Function()? onRefresh;

  /// Tab root: transparent background and large title.
  final bool root;

  /// Muted line under the large title (root pages only).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (!root) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(title: Text(title), actions: actions),
        body: EarnPageList(onRefresh: onRefresh, children: children),
      );
    }
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EarnPageList(
        onRefresh: onRefresh,
        top: MediaQuery.paddingOf(context).top + AppSpace.lg,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(
                  header: true,
                  child: Text(title, style: AppType.headlineLight.copyWith(color: c.ink)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                ],
              ]),
            ),
            ...?actions,
          ]),
          const SizedBox(height: AppSpace.lg),
          ...children,
        ],
      ),
    );
  }
}

/// Bold group heading above a settings card.
class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, AppSpace.xl - 2, 6, AppSpace.sm + 2),
        child: Semantics(
          header: true,
          child: Text(title, style: AppType.section.copyWith(color: context.colors.ink, fontWeight: FontWeight.w700)),
        ),
      );
}

/// A titled white card holding settings rows separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;

  /// Optional explanatory text shown under the card.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, indent: 18, endIndent: 18, color: c.line));
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) SettingsGroupHeader(title!) else const SizedBox(height: AppSpace.md),
        EarnCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, AppSpace.sm + 2, 10, 0),
            child: Text(footer!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
          ),
      ],
    );
  }
}

/// Padded content block inside a [SettingsGroup] (forms, explanations).
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: AppSpace.md + 2), child: child);
}

/// Leading pastel icon badge for settings rows.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, this.danger = false, this.tone = SettingsTone.violet});
  final IconData icon;
  final bool danger;
  final SettingsTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = settingsToneColors(context, tone, danger: danger);
    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 21, color: fg),
      ),
    );
  }
}

/// Navigation / action row with a 48dp+ target.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.chevron = true,
    this.tone = SettingsTone.violet,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool chevron;
  final SettingsTone tone;

  /// Short current value shown before the chevron (e.g. "On", "Dark").
  final String? value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trailingWidgets = <Widget>[
      if (value != null)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            value!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w600),
          ),
        ),
      ?trailing,
      if (trailing == null && onTap != null && chevron) Icon(Icons.chevron_right_rounded, color: c.inkMuted),
    ];
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                SettingsIcon(icon, danger: danger, tone: tone),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      title,
                      style: AppType.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: danger ? c.error : c.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                    ],
                  ]),
                ),
                if (trailingWidgets.isNotEmpty) ...[
                  const SizedBox(width: AppSpace.sm),
                  for (final (i, w) in trailingWidgets.indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    w,
                  ],
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch row.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.tone = SettingsTone.violet,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final SettingsTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    return SwitchListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: icon == null ? null : SettingsIcon(icon!, tone: tone),
      title: Text(
        title,
        style: AppType.label.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled ? c.ink : c.ink.withValues(alpha: 0.5),
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Soft tinted note with an icon badge, used for honest explanations and
/// warnings.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.message, this.icon = Icons.info_outline_rounded, this.warning = false});

  final String message;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = warning ? c.warning : c.accentText;
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg - 2),
      decoration: BoxDecoration(
        color: warning ? c.warningSoft : c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: c.card.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: fg),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(message, style: AppType.bodySmall.copyWith(color: c.ink)),
          ),
        ),
      ]),
    );
  }
}

/// Title row used at the top of settings bottom sheets.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle, this.icon, this.tone = SettingsTone.violet});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final SettingsTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (icon != null) ...[SettingsIcon(icon!, tone: tone), const SizedBox(width: AppSpace.md)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(title, style: AppType.title.copyWith(color: c.ink))),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
          ],
        ]),
      ),
    ]);
  }
}

/// Shows a bottom sheet with a single choice list; returns the picked value.
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) label,
  String Function(T)? description,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpace.md),
                  child: Text(title, style: AppType.title),
                ),
                for (final v in values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: _OptionRow(
                      label: label(v),
                      description: description?.call(v),
                      selected: v == selected,
                      onTap: () => Navigator.pop(ctx, v),
                      colors: c,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
    this.description,
  });
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final EarnColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.accentSoft : c.cardHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: selected ? c.accentText.withValues(alpha: 0.5) : Colors.transparent, width: 1.4),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(label,
                      style: AppType.label.copyWith(
                          fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: c.ink)),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(description!, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                  ],
                ]),
              ),
              const SizedBox(width: AppSpace.sm),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: selected
                    ? Icon(Icons.check_circle_rounded, key: const ValueKey(1), color: c.accentText)
                    : Icon(Icons.circle_outlined, key: const ValueKey(0), color: c.line),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
