import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../features/authentication/application/session_controller.dart';

/// Rounded surface used for every card in the app.
///
/// * default — white surface with a soft lavender-tinted shadow;
/// * [accent] — the purple hero gradient with white content;
/// * [dark] — the deep "night" gradient with white content;
/// * [tint] — a pastel surface (quick actions, rate tiles).
///
/// Content inherits a readable foreground colour through [DefaultTextStyle]
/// and [IconTheme], so children should not hardcode text colours.
class EarnCard extends StatelessWidget {
  const EarnCard({
    super.key,
    required this.child,
    this.accent = false,
    this.dark = false,
    this.tint,
    this.padding = const EdgeInsets.all(AppSpace.xl - 4),
    this.radius = AppRadius.lg,
    this.onTap,
    this.semanticLabel,
    this.elevated = true,
  });

  final Widget child;

  /// Purple gradient card for primary content.
  final bool accent;

  /// Deep purple card (strong contrast, used sparingly).
  final bool dark;

  /// Optional pastel background (ignored when [accent] or [dark]).
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool elevated;

  /// Foreground for content on this card.
  static Color foreground(BuildContext context, {bool accent = false, bool dark = false}) =>
      accent || dark ? AppColors.white : context.colors.ink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final gradient = accent ? AppGradients.hero : (dark ? AppGradients.night : null);
    final fg = foreground(context, accent: accent, dark: dark);
    final shape = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: !elevated ? null : (gradient != null ? AppShadows.glow : AppShadows.card(brightness)),
        ),
        child: Material(
          color: gradient != null ? Colors.transparent : (tint ?? c.card),
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: onTap == null ? content : InkWell(onTap: onTap, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays an amount, masked when privacy mode is active.
class AmountText extends ConsumerWidget {
  const AmountText(this.text, {super.key, this.style, this.semanticsLabel, this.alwaysShow = false});

  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final bool alwaysShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = !alwaysShow && ref.watch(hideAmountsProvider);
    return Text(
      hidden ? '••••••' : text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      semanticsLabel: hidden ? 'Amount hidden' : (semanticsLabel ?? text),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(4, AppSpace.lg, 4, AppSpace.sm),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            if (action != null) LinkAction(label: action!, onTap: onAction),
          ],
        ),
      );
}

/// Violet "See all →" style link used in card and section headers.
class LinkAction extends StatelessWidget {
  const LinkAction({super.key, required this.label, this.onTap, this.icon = Icons.arrow_forward_rounded});
  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.accentText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AppType.label.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: color),
          ]),
        ),
      ),
    );
  }
}

/// Small rounded label (status, category).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.textColor, this.icon});

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color ?? c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: textColor ?? c.ink), const SizedBox(width: 4)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: textColor ?? c.ink),
          ),
        ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl, horizontal: AppSpace.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        EntranceScale(
          child: SizedBox(
            width: 112,
            height: 104,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [c.accent.withValues(alpha: 0.35), c.accent.withValues(alpha: 0)]),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppShadows.card(Theme.of(context).brightness),
                ),
                child: Icon(icon, size: 30, color: c.accentText),
              ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpace.sm),
        Text(message, style: context.text.bodyMedium?.copyWith(color: c.inkMuted), textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: AppSpace.xl),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ]),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: message,
        action: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading'});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(label: label, child: const Padding(padding: EdgeInsets.all(32), child: EarnLoader())),
      );
}

/// Branded loading animation: three bars rising in a wave.
class EarnLoader extends StatefulWidget {
  const EarnLoader({super.key, this.size = 36});
  final double size;

  @override
  State<EarnLoader> createState() => _EarnLoaderState();
}

class _EarnLoaderState extends State<EarnLoader> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: s * 0.2,
                height: s * (0.35 + 0.55 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi - i * 0.9))),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.violet, AppColors.lavender],
                  ),
                  borderRadius: BorderRadius.circular(s * 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fades and scales a child in once when first built (no-op with reduced motion).
class EntranceScale extends StatelessWidget {
  const EntranceScale({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.entrance + delay,
      curve: Interval(
        delay.inMilliseconds / (AppDurations.entrance + delay).inMilliseconds,
        1,
        curve: AppCurves.emphasized,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: Transform.scale(scale: 0.96 + 0.04 * t, child: child)),
      ),
      child: child,
    );
  }
}

/// Labelled metric: small caption above a bold amount.
class Metric extends StatelessWidget {
  const Metric({super.key, required this.label, required this.value, this.style, this.caption, this.color});

  final String label;
  final String value;
  final TextStyle? style;
  final String? caption;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.caption.copyWith(color: color?.withValues(alpha: 0.75) ?? context.colors.inkMuted)),
          const SizedBox(height: 4),
          AmountText(value, style: (style ?? AppType.amountMedium).copyWith(color: color)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: AppType.caption.copyWith(color: color?.withValues(alpha: 0.75) ?? context.colors.inkMuted)),
          ],
        ],
      );
}

/// Circular icon button with a 48dp target.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.filled = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: filled ? AppShadows.glow : AppShadows.card(Theme.of(context).brightness),
        ),
        child: Material(
          color: filled ? AppColors.violet : c.card,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: AppIconSize.md, color: filled ? AppColors.white : c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirm',
  bool destructive = false,
}) async {
  final c = context.colors;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: AppType.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: Colors.white) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [action] and reports failure in a snackbar. Returns true on success.
Future<bool> runGuarded(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
    return true;
  } on AppException catch (e) {
    if (context.mounted) showMessage(context, e.message);
  } on Object {
    if (context.mounted) showMessage(context, 'Could not complete that. Your data was not changed.');
  }
  return false;
}

/// Filled button that disables itself while its async action runs,
/// preventing duplicate submissions.
class BusyButton extends StatefulWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.accent = false});

  final String label;
  final Future<void> Function()? onPressed;
  final bool accent;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
        : Text(widget.label);
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    return SizedBox(
      width: double.infinity,
      child: widget.accent
          ? GradientButton(onPressed: onPressed, busy: _busy, child: child)
          : FilledButton(onPressed: onPressed, child: child),
    );
  }
}

/// Primary call to action: purple gradient pill with a soft glow.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.child, required this.onPressed, this.busy = false});
  final Widget child;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: enabled || busy ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: enabled ? AppShadows.glow : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(gradient: AppGradients.orb),
              child: InkWell(
                onTap: onPressed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 54),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: DefaultTextStyle.merge(
                        style: AppType.button.copyWith(color: AppColors.white),
                        child: IconTheme.merge(data: const IconThemeData(color: AppColors.white), child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain-language explanation for financial terms ("What does this mean?").
class InfoTip extends StatelessWidget {
  const InfoTip({super.key, required this.title, required this.message, this.color});
  final String title;
  final String message;

  /// Icon colour (defaults to muted ink; pass white-ish on dark cards).
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'What does this mean?',
        icon: Icon(Icons.info_outline_rounded, size: 20, color: color ?? context.colors.inkMuted),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppType.title),
                const SizedBox(height: 12),
                Text(message, style: AppType.body),
              ]),
            ),
          ),
        ),
      );
}
