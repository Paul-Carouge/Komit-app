import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/current_calendar_day.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/app_lock_service.dart';
import '../mascot/komo_mascot.dart';

/// Time away after which Komit locks again: long enough to check a message and come back
/// without unlocking, short enough that a phone left on a table is not left open.
const Duration appLockBackgroundGracePeriod = Duration(minutes: 1);

/// Hides the whole app behind a lock screen at launch and after [appLockBackgroundGracePeriod]
/// in the background, while the lock is on, until the system prompt succeeds.
///
/// The app stays mounted but offstage, so screens and unsaved fields survive a lock. There is
/// no way around the lock: Back leaves Komit instead of reaching the screens behind it. It also
/// applies the window protections (recents screenshot, FLAG_SECURE) that follow the settings.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  late bool _isLocked = ref.read(settingsControllerProvider).isAppLockEnabled;
  bool _isAuthenticating = false;

  /// Why the last attempt did not unlock; null before any attempt, which prompts on its own.
  AppLockAuthenticationResult? _lastFailedAttemptResult;
  DateTime? _hiddenAt;

  /// What the navigator last reported, given back to Android once unlocked.
  bool _canNavigatorHandleBack = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Registered before the router's back button dispatcher, so this observer is asked first.
    WidgetsBinding.instance.addObserver(this);
    _lifecycleListener = AppLifecycleListener(onHide: _onHide, onShow: _onShow, onResume: _onResume);
    ref.listenManual(settingsControllerProvider, (_, settings) {
      _applyWindowProtections(
        isAppLockEnabled: settings.isAppLockEnabled,
        isScreenContentHidden: settings.isScreenContentHidden,
      );
    }, fireImmediately: true);
    if (_isLocked) WidgetsBinding.instance.addPostFrameCallback((_) => _onLocked());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _applyWindowProtections({required bool isAppLockEnabled, required bool isScreenContentHidden}) {
    final appLockService = ref.read(appLockServiceProvider);
    final logger = ref.read(appLoggerProvider);
    unawaited(
      Future.wait([
        appLockService.setRecentsScreenshotEnabled(isEnabled: !isAppLockEnabled),
        appLockService.setSecureWindow(isSecure: isScreenContentHidden),
      ]).then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) =>
            logger.logError(event: 'window_protection_failed', error: error, stackTrace: stackTrace),
      ),
    );
  }

  void _onHide() {
    // The credential screen of older Android versions hides Komit too; that is not leaving.
    if (!_isAuthenticating) _hiddenAt = ref.read(clockProvider)();
  }

  void _onShow() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (_isLocked || hiddenAt == null || !ref.read(settingsControllerProvider).isAppLockEnabled) return;
    final timeAway = ref.read(clockProvider)().difference(hiddenAt);
    // A clock set back gives a negative time away: lock rather than trust it.
    if (timeAway >= appLockBackgroundGracePeriod || timeAway.isNegative) {
      setState(() {
        _isLocked = true;
        _lastFailedAttemptResult = null;
      });
      _onLocked();
    }
  }

  void _onResume() {
    ref.invalidate(canUseAppLockProvider);
    if (_isLocked && _lastFailedAttemptResult == null) unawaited(_authenticate());
  }

  void _onLocked() {
    FocusManager.instance.primaryFocus?.unfocus();
    // Android 13+ predictive back: the system then handles Back itself and leaves Komit.
    const NavigationNotification(canHandlePop: false).dispatch(context);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) unawaited(_authenticate());
  }

  void _unlock() {
    setState(() => _isLocked = false);
    NavigationNotification(canHandlePop: _canNavigatorHandleBack).dispatch(context);
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    final localizations = AppLocalizations.of(context);
    setState(() => _isAuthenticating = true);
    AppLockAuthenticationResult result;
    try {
      result = await ref
          .read(appLockServiceProvider)
          .authenticate(title: localizations.appLockPromptTitle, subtitle: localizations.appLockPromptSubtitle);
    } on PlatformException catch (error, stackTrace) {
      unawaited(ref.read(appLoggerProvider).logError(event: 'app_lock_failed', error: error, stackTrace: stackTrace));
      result = AppLockAuthenticationResult.failed;
    }
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    switch (result) {
      case AppLockAuthenticationResult.succeeded:
        unawaited(KomitHaptics.success());
        _unlock();
      // The screen lock was removed in the system settings, which itself required the
      // credential: nothing is left to check, so the lock turns off instead of locking out.
      case AppLockAuthenticationResult.unavailable:
        _unlock();
        unawaited(ref.read(settingsControllerProvider.notifier).updateAppLockEnabled(isEnabled: false));
      case AppLockAuthenticationResult.cancelled || AppLockAuthenticationResult.failed:
        setState(() => _lastFailedAttemptResult = result);
    }
  }

  /// Android 12 and older send Back here first: while locked it leaves Komit.
  @override
  Future<bool> didPopRoute() async {
    if (!_isLocked) return false;
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<NavigationNotification>(
          onNotification: (notification) {
            _canNavigatorHandleBack = notification.canHandlePop;
            // While locked, Android must keep handling Back; the app learns the truth on unlock.
            return _isLocked;
          },
          child: ExcludeFocus(
            excluding: _isLocked,
            child: TickerMode(
              enabled: !_isLocked,
              child: Offstage(offstage: _isLocked, child: widget.child),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: AppDurations.standard,
          switchInCurve: AppCurves.standard,
          switchOutCurve: AppCurves.standard,
          child: _isLocked
              ? _AppLockScreen(
                  isAuthenticating: _isAuthenticating,
                  lastFailedAttemptResult: _lastFailedAttemptResult,
                  onUnlockPressed: _authenticate,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AppLockScreen extends StatelessWidget {
  const _AppLockScreen({
    required this.isAuthenticating,
    required this.lastFailedAttemptResult,
    required this.onUnlockPressed,
  });

  final bool isAuthenticating;
  final AppLockAuthenticationResult? lastFailedAttemptResult;
  final VoidCallback onUnlockPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    final failureMessage = switch (lastFailedAttemptResult) {
      AppLockAuthenticationResult.cancelled => localizations.appLockCancelled,
      AppLockAuthenticationResult.failed => localizations.appLockFailed,
      _ => null,
    };
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.readableContentMaximumWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: KomoMascot(mood: KomoMood.sleepy, size: AppSizes.mascotLarge),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  Semantics(
                    header: true,
                    child: Text(
                      localizations.appLockTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    failureMessage ?? localizations.appLockMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: komitColors.mutedText),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight)),
                    onPressed: isAuthenticating ? null : onUnlockPressed,
                    icon: const Icon(KomitIcons.fingerprint),
                    label: Text(failureMessage == null ? localizations.unlock : localizations.tryAgain),
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
