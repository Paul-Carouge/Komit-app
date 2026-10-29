import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/current_calendar_day.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/app_update_service.dart';
import '../../services/automatic_backup_service.dart';
import '../shared/shared_widgets.dart';

final installedVersionProvider = FutureProvider<String?>((ref) async {
  final updateService = ref.watch(appUpdateServiceProvider);
  return updateService.isSupported ? updateService.readInstalledVersion() : null;
});

/// Checks at launch, at most once a day and only when the user allows it (see
/// [claimAutomaticUpdateCheck]), silently: a failed check must never bother the user.
class StartupUpdateCheck extends ConsumerStatefulWidget {
  const StartupUpdateCheck({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<StartupUpdateCheck> createState() => _StartupUpdateCheckState();
}

class _StartupUpdateCheckState extends ConsumerState<StartupUpdateCheck> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(appUpdateServiceProvider).isSupported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_checkIfDue()));
  }

  Future<void> _checkIfDue() async {
    final isDue = await claimAutomaticUpdateCheck(ref.read(settingsRepositoryProvider), now: ref.read(clockProvider)());
    if (isDue && mounted) await checkForUpdate(context, ref, isUserInitiated: false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> checkForUpdate(BuildContext context, WidgetRef ref, {required bool isUserInitiated}) async {
  final localizations = AppLocalizations.of(context);
  final updateService = ref.read(appUpdateServiceProvider);
  if (!updateService.isSupported) return;
  final AvailableUpdate? update;
  try {
    update = await updateService.findAvailableUpdate();
  } on Object catch (error) {
    developer.log('Update check failed', name: 'komit.update', error: error);
    if (isUserInitiated && context.mounted) showMessageSnackBar(context, localizations.updateCheckFailed);
    return;
  }
  if (!context.mounted) return;
  if (update == null) {
    if (isUserInitiated) showMessageSnackBar(context, localizations.upToDate);
    return;
  }
  final isInstallRequested = await showDialog<bool>(
    context: context,
    builder: (context) => _UpdateAvailableDialog(update: update!),
  );
  if (isInstallRequested != true || !context.mounted) return;
  if (!await _ensureInstallPermission(context, updateService) || !context.mounted) return;
  try {
    await ref.read(automaticBackupServiceProvider).writeSnapshot(AutomaticBackupReason.beforeUpdate);
  } on Object catch (error, stackTrace) {
    // Updates keep the database; the copy is only a safety net, so its failure must not block them.
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'pre_update_backup_failed', error: error, stackTrace: stackTrace),
    );
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateProgressDialog(update: update!, updateService: updateService),
  );
}

/// Explains the "install unknown apps" permission, opens its settings page, then waits for the
/// user to come back. The chosen update stays in this call meanwhile, so it continues on its
/// own once the permission is granted. Returns false when the user stopped or refused.
Future<bool> _ensureInstallPermission(BuildContext context, AppUpdateService updateService) async {
  final localizations = AppLocalizations.of(context);
  try {
    if (await updateService.canInstallPackages()) return true;
    if (!context.mounted) return false;
    final isRationaleAccepted = await showPermissionRationaleSheet(
      context,
      icon: KomitIcons.shieldCheck,
      title: localizations.installPermissionTitle,
      message: localizations.installPermissionMessage,
      confirmLabel: localizations.openSettings,
    );
    if (!isRationaleAccepted) return false;
    final userReturned = Completer<void>();
    final lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (!userReturned.isCompleted) userReturned.complete();
      },
    );
    try {
      await updateService.openInstallPermissionSettings();
      await userReturned.future;
    } finally {
      lifecycleListener.dispose();
    }
    if (await updateService.canInstallPackages()) return true;
    if (context.mounted) showMessageSnackBar(context, localizations.updateErrorInstallPermission);
    return false;
  } on Object catch (error) {
    developer.log('Install permission flow failed', name: 'komit.update', error: error);
    if (context.mounted) showMessageSnackBar(context, localizations.settingsUnavailable);
    return false;
  }
}

class _UpdateAvailableDialog extends StatelessWidget {
  const _UpdateAvailableDialog({required this.update});

  final AvailableUpdate update;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.updateAvailableTitle(update.version)),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.whatsNew, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.small),
              // Release notes are shown as plain text: never interpret remote content.
              SelectableText(update.releaseNotes),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(localizations.later)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, AppSizes.minimumTouchTarget)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(localizations.installUpdate),
        ),
      ],
    );
  }
}

class _UpdateProgressDialog extends StatefulWidget {
  const _UpdateProgressDialog({required this.update, required this.updateService});

  final AvailableUpdate update;
  final AppUpdateService updateService;

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  double _progress = 0;
  bool _isWaitingForSystemInstaller = false;
  AppUpdateFailureReason? _failureReason;
  late final StreamSubscription<AppUpdateFailureReason> _installFailureSubscription;

  @override
  void initState() {
    super.initState();
    // Listened before installing, so a fast refusal from Android is not missed.
    _installFailureSubscription = widget.updateService.installFailures.listen((reason) {
      developer.log('Installer reported ${reason.name}', name: 'komit.update');
      if (mounted) setState(() => _failureReason = reason);
    });
    unawaited(_install());
  }

  @override
  void dispose() {
    unawaited(_installFailureSubscription.cancel());
    super.dispose();
  }

  Future<void> _install() async {
    try {
      await widget.updateService.downloadAndInstall(
        widget.update,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      // Android shows its own confirmation now; a refusal comes back through installFailures.
      if (mounted) setState(() => _isWaitingForSystemInstaller = true);
    } on Object catch (error) {
      developer.log('Update install failed', name: 'komit.update', error: error);
      final reason = error is AppUpdateException ? error.reason : AppUpdateFailureReason.installFailed;
      if (mounted) setState(() => _failureReason = reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final failureReason = _failureReason;
    final isDone = failureReason != null || _isWaitingForSystemInstaller;
    return AlertDialog(
      content: switch (failureReason) {
        // Already a full sentence that says what to do.
        AppUpdateFailureReason.installPermissionRequired => Text(localizations.updateErrorInstallPermission),
        final reason? => Text(
          localizations.updateFailed(switch (reason) {
            AppUpdateFailureReason.installPermissionRequired => localizations.updateErrorInstallPermission,
            AppUpdateFailureReason.network => localizations.updateErrorNetwork,
            AppUpdateFailureReason.invalidRelease => localizations.updateErrorInvalidRelease,
            AppUpdateFailureReason.corruptedDownload => localizations.updateErrorCorruptedDownload,
            AppUpdateFailureReason.installFailed => localizations.updateErrorInstallFailed,
            AppUpdateFailureReason.installCancelled => localizations.updateErrorInstallCancelled,
            AppUpdateFailureReason.installConflict => localizations.updateErrorInstallConflict,
            AppUpdateFailureReason.installIncompatible => localizations.updateErrorInstallIncompatible,
            AppUpdateFailureReason.installStorage => localizations.updateErrorInstallStorage,
            AppUpdateFailureReason.installBlocked => localizations.updateErrorInstallBlocked,
          }),
        ),
        null when _isWaitingForSystemInstaller => Text(localizations.confirmInstallInSystemWindow),
        null => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.downloadingUpdate((_progress * 100).round())),
            const SizedBox(height: AppSpacing.large),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          ],
        ),
      },
      actions: [
        if (isDone)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
      ],
    );
  }
}
