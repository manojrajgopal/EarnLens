import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/dependency_injection.dart';
import 'core/platform/privacy_channel.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/settings.dart';
import 'features/authentication/application/session_controller.dart';
import 'features/notifications/application/notification_service.dart';
import 'features/widgets/home_widget_service.dart';

class EarnLensApp extends ConsumerStatefulWidget {
  const EarnLensApp({super.key});

  @override
  ConsumerState<EarnLensApp> createState() => _EarnLensAppState();
}

class _EarnLensAppState extends ConsumerState<EarnLensApp> with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final privacy = ref.read(securitySettingsProvider).privacyMode;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (privacy) setState(() => _obscured = true);
      case AppLifecycleState.paused:
        if (privacy) setState(() => _obscured = true);
        ref.read(sessionProvider.notifier).onBackgrounded();
      case AppLifecycleState.resumed:
        setState(() => _obscured = false);
        ref.read(sessionProvider.notifier).onResumed();
        ref.read(homeWidgetServiceProvider).requestPublish();
        ref.read(notificationServiceProvider).requestSync();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final appearance = ref.watch(appearanceProvider);
    ref.watch(notificationSyncProvider);
    ref.watch(homeWidgetSyncProvider);
    ref.listen(securitySettingsProvider.select((s) => s.privacyMode), (_, on) => PrivacyChannel.setSecure(on));

    return MaterialApp.router(
      title: 'EarnLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (appearance.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'IN'), Locale('en', 'US'), Locale('en', 'GB'), Locale('hi', 'IN')],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final content = AnnotatedRegion<SystemUiOverlayStyle>(
          // Default system-bar styling for screens without an AppBar.
          value: systemBarsFor(Theme.of(context).brightness),
          child: MediaQuery(
            data: mq.copyWith(disableAnimations: mq.disableAnimations || appearance.reduceMotion),
            child: child ?? const SizedBox.shrink(),
          ),
        );
        return Stack(children: [
          content,
          if (_obscured) const Positioned.fill(child: _PrivacyCover()),
        ]);
      },
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(child: EarnLensMark(size: 72)),
      );
}
