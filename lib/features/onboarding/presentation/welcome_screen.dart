import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../authentication/presentation/pin_pad.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EarnBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EntranceScale(
                            child: Row(
                              children: [
                                const BrandBadge(size: 52),
                                const SizedBox(width: 12),
                                Text(
                                  'EarnLens',
                                  style: AppType.title.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          EntranceScale(
                            delay: const Duration(milliseconds: 80),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Your earnings,\n'),
                                  TextSpan(
                                    text: 'clearly.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontVariations: const [FontVariation('wght', 700)],
                                      color: c.accentText,
                                    ),
                                  ),
                                ],
                              ),
                              style: AppType.displayLight.copyWith(color: c.ink),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'EarnLens shows how much you have earned — live, to the second — across your salary, '
                            'side work and business, and compares it with what you expected.',
                            style: AppType.body.copyWith(color: c.inkMuted),
                          ),
                          const SizedBox(height: 28),
                          for (final (i, f) in [
                            (
                              Icons.bolt_rounded,
                              'Live earnings',
                              'Calculated from your pay rules and the clock, so nothing is lost when the app is closed.',
                              AppColors.violet,
                              AppColors.lilacSoft,
                            ),
                            (
                              Icons.compare_arrows_rounded,
                              'Expected vs actual',
                              'Track estimates, real earnings and money received separately.',
                              AppColors.peach,
                              AppColors.peachSoft,
                            ),
                            (
                              Icons.lock_outline_rounded,
                              'Private by default',
                              'Your financial data stays on this device. No account, no cloud, no ads.',
                              AppColors.mint,
                              AppColors.mintSoft,
                            ),
                          ].indexed)
                            EntranceScale(
                              delay: Duration(milliseconds: 140 + 70 * i),
                              child: _Feature(
                                icon: f.$1,
                                title: f.$2,
                                text: f.$3,
                                color: f.$4,
                                tint: dark ? f.$4.withValues(alpha: 0.14) : f.$5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Actions stay pinned and visible on every screen height.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GradientButton(
                          onPressed: () => context.go('/onboarding'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Get started'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: c.card.withValues(alpha: 0.7),
                            foregroundColor: c.accentText,
                            side: BorderSide(color: c.accentText.withValues(alpha: 0.3), width: 1.2),
                            minimumSize: const Size(64, 52),
                          ),
                          onPressed: () => context.go('/onboarding?sample=1'),
                          child: const Text('Explore with sample data'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sample data is clearly labelled and can be removed at any time in Settings › Data.',
                          textAlign: TextAlign.center,
                          style: AppType.caption.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.tint,
  });
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(AppRadius.md + 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.section.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(text, style: AppType.bodySmall.copyWith(color: c.ink.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
