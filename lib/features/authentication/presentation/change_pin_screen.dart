import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../application/session_controller.dart';
import 'pin_pad.dart';

/// Change the PIN (verifying the current one) or create one if none exists.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verified = !ref.read(pinConfiguredProvider);
  }

  Future<void> _checkCurrent(String pin) async {
    final r = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    setState(() {
      switch (r) {
        case PinAccepted():
          _verified = true;
          _error = null;
        case PinRejected(:final lockedFor):
          _error = lockedFor == null ? 'Incorrect PIN' : 'Too many attempts. Try again later.';
        case PinLockedOut():
          _error = 'Too many attempts. Try again later.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(ref.read(pinConfiguredProvider) ? 'Change PIN' : 'Set a PIN')),
      body: LayoutBuilder(builder: (context, constraints) {
        final bottom = AppInsets.bottomClearance(context);
        final h = constraints.maxHeight - bottom - AppSpace.sm;
        final dense = h < 640;
        final keySize = PinPad.keySizeFor(h - PinSetupFlow.headerHeight - 72, dense: dense);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, AppSpace.sm, 20, bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: Center(
              child: _verified
                  ? PinSetupFlow(
                      title: 'Choose a new PIN',
                      keySize: keySize,
                      dense: dense,
                      onCreated: (pin) async {
                        await ref.read(pinServiceProvider).setPin(pin);
                        ref.read(pinConfiguredProvider.notifier).set(true);
                        if (!context.mounted) return;
                        showMessage(context, 'PIN updated');
                        context.pop();
                      },
                    )
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.orb,
                          boxShadow: AppShadows.glow,
                        ),
                        child: const Icon(Icons.lock_rounded, color: AppColors.white),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text('Enter your current PIN',
                          style: AppType.title.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpace.lg),
                      PinPad(
                        onSubmit: _checkCurrent,
                        errorText: _error,
                        submitLabel: 'Continue',
                        keySize: keySize,
                        dense: dense,
                      ),
                    ]),
            ),
          ),
        );
      }),
    );
  }
}
