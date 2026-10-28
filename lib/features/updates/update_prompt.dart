import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/app_update_service.dart';
import '../shared/shared_widgets.dart';

final installedVersionProvider = FutureProvider<String?>((ref) async {
  final updateService = ref.watch(appUpdateServiceProvider);
  return updateService.isSupported ? updateService.readInstalledVersion() : null;
});

/// Checks once per launch, silently: a failed check must never bother the user.
class StartupUpdateCheck extends ConsumerStatefulWidget {
  const StartupUpdateCheck({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<StartupUpdateCheck> createState() => _StartupUpdateCheckState();
}

class _StartupUpdateCheckState extends ConsumerState<StartupUpdateCheck> {
  static bool _hasCheckedThisLaunch = false;

  @override
  void initState() {
    super.initState();
    if (_hasCheckedThisLaunch) return;
    _hasCheckedThisLaunch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkForUpdate(context, ref, isUserInitiated: false));
    });
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
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateProgressDialog(update: update!, updateService: updateService),
  );
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
  AppUpdateFailureReason? _failureReason;

  @override
  void initState() {
    super.initState();
    unawaited(_install());
  }

  Future<void> _install() async {
    try {
      await widget.updateService.downloadAndInstall(
        widget.update,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      // The system installer takes over from here.
      if (mounted) Navigator.of(context).pop();
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
    return AlertDialog(
      content: failureReason != null
          ? Text(
              localizations.updateFailed(switch (failureReason) {
                AppUpdateFailureReason.installPermissionRequired => localizations.updateErrorInstallPermission,
                AppUpdateFailureReason.network => localizations.updateErrorNetwork,
                AppUpdateFailureReason.invalidRelease => localizations.updateErrorInvalidRelease,
                AppUpdateFailureReason.corruptedDownload => localizations.updateErrorCorruptedDownload,
                AppUpdateFailureReason.installFailed => localizations.updateErrorInstallFailed,
              }),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(localizations.downloadingUpdate((_progress * 100).round())),
                const SizedBox(height: AppSpacing.large),
                LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              ],
            ),
      actions: [
        if (failureReason != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
      ],
    );
  }
}
