import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routing/app_shell.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/components.dart';

/// The brand mark on a soft white plate with a lavender glow.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(size * 0.32),
          boxShadow: AppShadows.glow,
        ),
        child: EarnLensMark(size: size * 0.8),
      );
}

/// Numeric keypad with masked PIN dots. Supports a hardware keyboard
/// (digits, Backspace, Enter) for the web and tablets.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    this.onBiometric,
    this.errorText,
    this.errorIcon = Icons.error_outline_rounded,
    this.submitLabel = 'Unlock',
    this.keySize = 72,
    this.dense = false,
  });

  final Future<void> Function(String pin) onSubmit;
  final bool enabled;
  final VoidCallback? onBiometric;
  final String? errorText;

  /// Icon shown in the error/lockout message pill.
  final IconData errorIcon;
  final String submitLabel;

  /// Diameter of each key (clamped to 56–80); smaller on short screens.
  final double keySize;

  /// Tighter vertical rhythm for short screens.
  final bool dense;

  static double _rowGap(bool dense) => dense ? 8 : 12;
  static double _errorHeight(bool dense) => dense ? 38 : 46;
  static double _buttonGap(bool dense) => dense ? 8 : AppSpace.md;

  /// Largest key size (56–76) for which the whole pad fits in [height].
  static double keySizeFor(double height, {bool dense = false}) {
    final chrome = 22 + _errorHeight(dense) + 4 * _rowGap(dense) + _buttonGap(dense) + 54;
    return ((height - chrome) / 4).clamp(56.0, 76.0);
  }

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;
  final _focus = FocusNode();

  void clear() => setState(() => _pin = '');

  @override
  void initState() {
    super.initState();
    // `autofocus` is ignored when another field (e.g. an earlier form step)
    // still holds focus, so claim keyboard focus explicitly once shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _add(String d) {
    if (!widget.enabled || _busy || _pin.length >= PinService.maxLength) return;
    if (!_focus.hasFocus) _focus.requestFocus();
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
  }

  void _back() {
    if (_pin.isEmpty || _busy) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (!widget.enabled || _busy || _pin.length < PinService.minLength) return;
    setState(() => _busy = true);
    final pin = _pin;
    try {
      await widget.onSubmit(pin);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pin = '';
        });
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _add(ch);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _back();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final size = widget.keySize.clamp(56.0, 80.0);
    final gap = math.max(14.0, size * 0.32);
    final dots = _pin.length < PinService.minLength ? PinService.minLength : _pin.length;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '${_pin.length} digits entered',
            liveRegion: true,
            child: SizedBox(
              height: 22,
              child: _Shake(
                trigger: widget.errorText,
                enabled: !reduce,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < dots; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: _Dot(filled: i < _pin.length, error: widget.errorText != null && _pin.isEmpty, reduce: reduce),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: PinPad._errorHeight(widget.dense),
            child: Center(
              child: AnimatedSwitcher(
                duration: reduce ? Duration.zero : AppDurations.fast,
                child: widget.errorText == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        key: ValueKey(widget.errorText),
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.errorSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(widget.errorIcon, size: 16, color: c.error),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.errorText!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.caption.copyWith(color: c.error, fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ]),
                        ),
                      ),
              ),
            ),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            _row([for (final d in row) _Key(label: d, size: size, enabled: widget.enabled, onTap: () => _add(d))], gap),
          _row([
            widget.onBiometric == null
                ? SizedBox(width: size, height: size)
                : _Key(
                    icon: Icons.fingerprint_rounded,
                    semantic: 'Use biometrics',
                    size: size,
                    accent: true,
                    onTap: widget.onBiometric!,
                  ),
            _Key(label: '0', size: size, enabled: widget.enabled, onTap: () => _add('0')),
            _Key(icon: Icons.backspace_outlined, semantic: 'Delete digit', size: size, plain: true, onTap: _back),
          ], gap),
          SizedBox(height: PinPad._buttonGap(widget.dense)),
          SizedBox(
            width: math.min(3 * size + 2 * gap, 280),
            child: GradientButton(
              onPressed: widget.enabled && !_busy && _pin.length >= PinService.minLength ? _submit : null,
              busy: _busy,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                    )
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> keys, double gap) => Padding(
        padding: EdgeInsets.symmetric(vertical: PinPad._rowGap(widget.dense) / 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, k) in keys.indexed) ...[if (i > 0) SizedBox(width: gap), k],
        ]),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.error, required this.reduce});
  final bool filled;
  final bool error;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedScale(
      duration: reduce ? Duration.zero : AppDurations.medium,
      curve: AppCurves.overshoot,
      scale: filled ? 1.0 : 0.82,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : AppDurations.fast,
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled ? AppGradients.orb : null,
          color: filled ? null : (error ? c.errorSoft : c.accentSoft),
          border: Border.all(color: filled ? Colors.transparent : (error ? c.error : c.accentText.withValues(alpha: 0.35)), width: 1.6),
          boxShadow: filled ? const [BoxShadow(color: Color(0x406B3BEA), blurRadius: 8, offset: Offset(0, 3))] : null,
        ),
      ),
    );
  }
}

/// Horizontal shake whenever [trigger] changes to a non-null value.
class _Shake extends StatelessWidget {
  const _Shake({required this.trigger, required this.enabled, required this.child});
  final Object? trigger;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || trigger == null) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(math.sin(t * math.pi * 4) * 8 * (1 - t), 0), child: child),
      child: child,
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    this.semantic,
    required this.size,
    required this.onTap,
    this.accent = false,
    this.plain = false,
    this.enabled = true,
  });
  final String? label;
  final IconData? icon;
  final String? semantic;
  final double size;
  final VoidCallback onTap;
  final bool accent;
  final bool plain;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final fg = accent ? c.accentText : c.ink;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantic ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: plain || accent ? null : AppShadows.card(brightness),
        ),
        child: Material(
          color: plain ? Colors.transparent : (accent ? c.accentSoft : c.card),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: c.accent.withValues(alpha: 0.25),
            highlightColor: c.accentSoft,
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: AppType.amountMedium.copyWith(
                          fontSize: size * 0.36,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation('wght', 600)],
                          color: enabled ? fg : fg.withValues(alpha: 0.4),
                        ),
                      )
                    : Icon(icon, size: size * 0.36, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-step "enter, then confirm" PIN creation.
class PinSetupFlow extends StatefulWidget {
  const PinSetupFlow({
    super.key,
    required this.onCreated,
    this.title = 'Create a PIN',
    this.keySize = 68,
    this.dense = false,
  });

  final Future<void> Function(String pin) onCreated;
  final String title;
  final double keySize;
  final bool dense;

  /// Height of everything above the keypad.
  static const headerHeight = 6 + AppSpace.md + 26 + 4 + 20 + AppSpace.lg;

  @override
  State<PinSetupFlow> createState() => _PinSetupFlowState();
}

class _PinSetupFlowState extends State<PinSetupFlow> {
  String? _first;
  String? _error;

  Future<void> _submit(String pin) async {
    if (_first == null) {
      final problem = PinService.validateNewPin(pin);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = 'PINs did not match. Start again.';
      });
      return;
    }
    await widget.onCreated(pin);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final confirming = _first != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, done) in [true, confirming].indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
              width: done ? 28 : 14,
              height: 6,
              decoration: BoxDecoration(
                gradient: done ? AppGradients.orb : null,
                color: done ? null : c.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ],
        ]),
        const SizedBox(height: AppSpace.md),
        Text(confirming ? 'Confirm your PIN' : widget.title,
            style: AppType.title.copyWith(color: c.ink, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          confirming ? 'Enter the same PIN again.' : '4 to 8 digits. Avoid 1234 or repeated digits.',
          style: AppType.bodySmall.copyWith(color: c.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.lg),
        PinPad(
          key: ValueKey(_first == null),
          onSubmit: _submit,
          errorText: _error,
          keySize: widget.keySize,
          dense: widget.dense,
          submitLabel: _first == null ? 'Next' : 'Confirm PIN',
        ),
      ],
    );
  }
}
