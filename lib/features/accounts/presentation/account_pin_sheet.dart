import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../authentication/presentation/pin_pad.dart';
import '../application/account_controller.dart';
import 'account_avatar.dart';

enum AccountPinMode {
  /// Enter the PIN to open the account for this session.
  unlock,

  /// Choose a new PIN (entered twice).
  set,

  /// Enter the current PIN to remove it.
  remove,
}

/// PIN entry for one account. Returns true when the PIN was accepted (or set).
Future<bool> showAccountPinSheet(BuildContext context, Account account, {AccountPinMode mode = AccountPinMode.unlock}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (_) => _AccountPinSheet(account: account, mode: mode),
  );
  return ok ?? false;
}

class _AccountPinSheet extends ConsumerStatefulWidget {
  const _AccountPinSheet({required this.account, required this.mode});
  final Account account;
  final AccountPinMode mode;

  @override
  ConsumerState<_AccountPinSheet> createState() => _AccountPinSheetState();
}

class _AccountPinSheetState extends ConsumerState<_AccountPinSheet> {
  String? _error;
  String? _first;
  Duration? _locked;
  Timer? _timer;
  int _padKey = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _countdown(Duration d) {
    _timer?.cancel();
    setState(() => _locked = d);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = (_locked ?? Duration.zero) - const Duration(seconds: 1);
      if (!mounted) return;
      if (left <= Duration.zero) {
        t.cancel();
        setState(() {
          _locked = null;
          _error = null;
        });
      } else {
        setState(() => _locked = left);
      }
    });
  }

  void _reject(PinCheck check) {
    switch (check) {
      case PinRejected(:final failedAttempts, :final lockedFor):
        final left = PinService.freeAttempts - failedAttempts;
        setState(() => _error = lockedFor != null
            ? 'Too many attempts.'
            : 'Incorrect PIN. $left ${left == 1 ? 'attempt' : 'attempts'} before a delay.');
        if (lockedFor != null) _countdown(lockedFor);
      case PinLockedOut(:final remaining):
        _countdown(remaining);
      case PinAccepted():
        break;
    }
  }

  Future<void> _submit(String pin) async {
    final accounts = ref.read(accountControllerProvider);
    final id = widget.account.id;
    switch (widget.mode) {
      case AccountPinMode.unlock:
        final check = await accounts.unlockAccount(id, pin);
        if (!mounted) return;
        check is PinAccepted ? Navigator.pop(context, true) : _reject(check);
      case AccountPinMode.remove:
        final check = await accounts.removeAccountPin(id, pin);
        if (!mounted) return;
        check is PinAccepted ? Navigator.pop(context, true) : _reject(check);
      case AccountPinMode.set:
        if (_first == null) {
          final problem = PinService.validateNewPin(pin);
          setState(() {
            _error = problem;
            if (problem == null) _first = pin;
            _padKey++;
          });
          return;
        }
        if (_first != pin) {
          setState(() {
            _first = null;
            _error = "The PINs didn't match. Start again.";
            _padKey++;
          });
          return;
        }
        try {
          await accounts.setAccountPin(id, pin);
          if (mounted) Navigator.pop(context, true);
        } on AppException catch (e) {
          if (mounted) setState(() => _error = e.message);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = widget.account;
    final (title, subtitle) = switch (widget.mode) {
      AccountPinMode.unlock => ('Unlock ${a.name}', 'This account has its own PIN.'),
      AccountPinMode.remove => ('Remove PIN', 'Enter the current PIN of ${a.name}.'),
      AccountPinMode.set => _first == null
          ? ('Set a PIN for ${a.name}', 'Use 4 to 8 digits. It is asked whenever this account is opened.')
          : ('Confirm the PIN', 'Enter the same PIN again.'),
    };
    final locked = _locked;
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AccountAvatar.of(a, size: 56, locked: widget.mode == AccountPinMode.unlock),
          const SizedBox(height: AppSpace.md),
          Semantics(header: true, child: Text(title, style: AppType.title.copyWith(color: c.ink), textAlign: TextAlign.center)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppType.bodySmall.copyWith(color: c.inkMuted), textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.lg),
          PinPad(
            key: ValueKey(_padKey),
            enabled: locked == null,
            onSubmit: _submit,
            submitLabel: switch (widget.mode) {
              AccountPinMode.unlock => 'Unlock',
              AccountPinMode.remove => 'Remove',
              AccountPinMode.set => _first == null ? 'Next' : 'Save PIN',
            },
            errorText: locked != null ? 'Too many attempts. Try again in ${locked.inSeconds}s' : _error,
            errorIcon: locked != null ? Icons.timer_outlined : Icons.error_outline_rounded,
            keySize: PinPad.keySizeFor(height * 0.55, dense: height < 700),
            dense: height < 700,
          ),
        ]),
      ),
    );
  }
}
