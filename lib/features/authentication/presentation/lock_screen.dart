import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/local/data_wiper.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/session_controller.dart';
import 'pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  Duration? _lockedFor;
  Timer? _countdown;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final remaining = await ref.read(pinServiceProvider).remainingLockout();
    if (remaining != null) _startCountdown(remaining);
    final enabled = ref.read(securitySettingsProvider).biometricsEnabled;
    final available = enabled && await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available && _lockedFor == null) _biometric();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown(Duration d) {
    _countdown?.cancel();
    setState(() => _lockedFor = d);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = (_lockedFor ?? Duration.zero) - const Duration(seconds: 1);
      if (!mounted) return;
      if (next <= Duration.zero) {
        t.cancel();
        setState(() {
          _lockedFor = null;
          _error = null;
        });
      } else {
        setState(() => _lockedFor = next);
      }
    });
  }

  Future<void> _verify(String pin) async {
    final result = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    switch (result) {
      case PinAccepted():
        ref.read(sessionProvider.notifier).unlock();
      case PinRejected(:final failedAttempts, :final lockedFor):
        final left = PinService.freeAttempts - failedAttempts;
        setState(() => _error = lockedFor != null
            ? 'Too many attempts.'
            : 'Incorrect PIN. $left ${left == 1 ? 'attempt' : 'attempts'} before a delay.');
        if (lockedFor != null) _startCountdown(lockedFor);
      case PinLockedOut(:final remaining):
        _startCountdown(remaining);
    }
  }

  Future<void> _biometric() async {
    final ok = await ref.read(biometricServiceProvider).authenticate('Unlock EarnLens');
    if (ok && mounted) ref.read(sessionProvider.notifier).unlock();
  }

  Future<void> _forgotPin() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHeader(
              icon: Icons.key_rounded,
              title: 'Forgot your PIN?',
              subtitle: 'EarnLens has no online account, so nobody can reset your PIN remotely. Your options:',
            ),
            const SizedBox(height: 16),
            if (_biometricAvailable) ...[
              _OptionCard(
                child: SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  tone: SettingsTone.mint,
                  title: 'Verify with biometrics and set a new PIN',
                  subtitle: 'Keeps all your data.',
                  onTap: () => Navigator.pop(ctx, 'bio'),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            _OptionCard(
              child: SettingsTile(
                icon: Icons.delete_forever_outlined,
                danger: true,
                title: 'Erase EarnLens on this device',
                subtitle: 'Deletes all local data and the PIN. You can restore from a backup afterwards.',
                onTap: () => Navigator.pop(ctx, 'erase'),
              ),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'bio') {
      final ok = await ref.read(biometricServiceProvider).authenticate('Verify it is you to reset your PIN');
      if (!ok || !mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: PinSetupFlow(
              title: 'Choose a new PIN',
              keySize: 60,
              dense: true,
              onCreated: (pin) async {
                await ref.read(pinServiceProvider).setPin(pin);
                if (ctx.mounted) Navigator.pop(ctx);
                ref.read(sessionProvider.notifier).unlock();
              },
            ),
          ),
        ),
      );
    } else if (choice == 'erase') {
      final confirmed = await confirmDialog(
        context,
        title: 'Erase all data?',
        message: 'This permanently deletes every income source, payment and setting stored on this device. '
            'It cannot be undone. Make sure you have a backup if you want to restore later.',
        confirm: 'Erase everything',
        destructive: true,
      );
      if (!confirmed) return;
      await DataWiper(ref.read(databaseProvider), ref.read(pinServiceProvider), ref.read(notificationProviderProvider))
          .wipeEverything();
      ref.read(pinConfiguredProvider.notifier).set(false);
      ref.read(sessionProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileStreamProvider).value?.displayName;
    final locked = _lockedFor;
    final c = context.colors;
    final first = name?.trim().split(RegExp(r'\s+')).first;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EarnBackdrop(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final h = constraints.maxHeight;
            final dense = h < 700;
            final brand = dense ? 44.0 : 60.0;
            // Header (mark, greeting, hint) and footer (forgot link) heights,
            // so the keypad can take whatever height is left.
            final header = brand + (dense ? 12 : 22) + (dense ? 30 : 36) + 4 + 20 + (dense ? 14 : 28);
            final footer = 48.0 + (dense ? 4 : 12);
            final padV = dense ? 12.0 : 32.0;
            final keySize = PinPad.keySizeFor(h - header - footer - 2 * padV, dense: dense);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: padV),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h - 2 * padV),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandBadge(size: brand),
                      SizedBox(height: dense ? 12 : 22),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          first == null || first.isEmpty ? 'Welcome back' : 'Welcome back, $first',
                          maxLines: 1,
                          style: AppType.headlineLight.copyWith(color: c.ink, fontSize: dense ? 26 : 30),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, size: 14, color: c.inkMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Enter your PIN to open EarnLens',
                              style: AppType.bodySmall.copyWith(color: c.inkMuted)),
                        ),
                      ]),
                      SizedBox(height: dense ? 14 : 28),
                      PinPad(
                        enabled: locked == null,
                        onSubmit: _verify,
                        onBiometric: _biometricAvailable ? _biometric : null,
                        errorText: locked != null ? 'Too many attempts. Try again in ${_fmt(locked)}' : _error,
                        errorIcon: locked != null ? Icons.timer_outlined : Icons.error_outline_rounded,
                        keySize: keySize,
                        dense: dense,
                      ),
                      SizedBox(height: dense ? 4 : 12),
                      TextButton(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: _forgotPin,
                        child: const Text('Forgot PIN?'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }
}

/// Rounded tinted container for an option row in a sheet.
class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.cardHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
