import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../shared/shared_widgets.dart';
import '../updates/update_prompt.dart';
import '../../services/app_lock_service.dart';
import '../../services/notification_permission_service.dart';
import 'automatic_backups_sheet.dart';
import 'backup_actions.dart';
import 'backup_passphrase_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final installedVersion = ref.watch(installedVersionProvider).value;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(title: localizations.settings),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              0,
              AppSpacing.screenGutter,
              AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                SectionTitle(localizations.yourName),
                _UserNameField(
                  // A new key resets the field when the name changes elsewhere, e.g. after an import.
                  key: ValueKey(settings.userName),
                  initialUserName: settings.userName,
                  onSubmitted: settingsController.updateUserName,
                ),
                SectionTitle(localizations.appearance),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: RadioGroup<ThemeMode>(
                    groupValue: settings.themeMode,
                    onChanged: (themeMode) {
                      if (themeMode == null) return;
                      unawaited(KomitHaptics.selection());
                      settingsController.updateThemeMode(themeMode);
                    },
                    child: Column(
                      children: [
                        for (final (themeMode, icon, label) in [
                          (ThemeMode.system, KomitIcons.smartphone, localizations.themeSystem),
                          (ThemeMode.light, KomitIcons.sun, localizations.themeLight),
                          (ThemeMode.dark, KomitIcons.moon, localizations.themeDark),
                        ])
                          RadioListTile<ThemeMode>(
                            value: themeMode,
                            secondary: HabitIconBadge(icon: icon, color: colorScheme.primary),
                            title: Text(label),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                      ],
                    ),
                  ),
                ),
                SectionTitle(localizations.language),
                SegmentedButton<String?>(
                  segments: [
                    // Null follows the phone, including Android's per-app language setting.
                    ButtonSegment(value: null, label: Text(localizations.languageSystem)),
                    // Each language is named in itself, so it can be found whatever the current one.
                    const ButtonSegment(value: 'en', label: Text('English')),
                    const ButtonSegment(value: 'fr', label: Text('Français')),
                  ],
                  selected: {settings.languageCode},
                  selectedIcon: const Icon(KomitIcons.check),
                  onSelectionChanged: (selection) {
                    unawaited(KomitHaptics.selection());
                    settingsController.updateLanguageCode(selection.single);
                  },
                ),
                SectionTitle(localizations.notifications),
                const _NotificationSettingsCard(),
                SectionTitle(localizations.privacyAndSecurity),
                const _PrivacyAndSecurityCard(),
                SectionTitle(localizations.dataAndStorage),
                const _DataAndStorageCard(),
                if (ref.watch(appUpdateServiceProvider).isSupported) ...[
                  SectionTitle(localizations.updates),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: HabitIconBadge(icon: KomitIcons.refreshCw, color: colorScheme.primary),
                          title: Text(localizations.checkForUpdates),
                          trailing: const Icon(KomitIcons.chevronRight),
                          onTap: () => checkForUpdate(context, ref, isUserInitiated: true),
                        ),
                        SwitchListTile(
                          secondary: HabitIconBadge(icon: KomitIcons.calendarClock, color: komitColors.mutedText),
                          title: Text(localizations.checkForUpdatesAutomatically),
                          subtitle: Text(localizations.checkForUpdatesAutomaticallyDescription),
                          value: settings.isAutomaticUpdateCheckEnabled,
                          onChanged: (isEnabled) {
                            unawaited(KomitHaptics.selection());
                            settingsController.updateAutomaticUpdateCheckEnabled(isEnabled: isEnabled);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                SectionTitle(localizations.about),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (installedVersion != null)
                        ListTile(
                          leading: HabitIconBadge(icon: KomitIcons.info, color: komitColors.mutedText),
                          title: Text(localizations.versionLabel(installedVersion)),
                        ),
                      ListTile(
                        leading: HabitIconBadge(icon: KomitIcons.scrollText, color: komitColors.mutedText),
                        title: Text(localizations.openSourceLicenses),
                        trailing: const Icon(KomitIcons.chevronRight),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: localizations.appTitle,
                          applicationVersion: installedVersion,
                        ),
                      ),
                      if (ref.watch(appUpdateServiceProvider).isSupported)
                        ListTile(
                          leading: HabitIconBadge(icon: KomitIcons.history, color: komitColors.mutedText),
                          title: Text(localizations.allVersionsOnGitHub),
                          trailing: const Icon(KomitIcons.externalLink),
                          onTap: () => _openReleasesPage(context, ref),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openReleasesPage(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(appUpdateServiceProvider).openReleasesPage();
  } on Object catch (error, stackTrace) {
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'releases_page_failed', error: error, stackTrace: stackTrace),
    );
    if (context.mounted) showMessageSnackBar(context, AppLocalizations.of(context).settingsUnavailable);
  }
}

/// The app lock and screen protection toggles.
class _PrivacyAndSecurityCard extends ConsumerWidget {
  const _PrivacyAndSecurityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    // Unknown while loading or on failure: the toggle stays usable only once a lock is confirmed.
    final canUseAppLock = ref.watch(canUseAppLockProvider).value ?? false;
    final isAppLockToggleEnabled = canUseAppLock || settings.isAppLockEnabled;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: HabitIconBadge(icon: KomitIcons.lockKeyhole, color: colorScheme.primary),
            title: Text(localizations.appLockSetting),
            subtitle: Text(
              isAppLockToggleEnabled ? localizations.appLockSettingDescription : localizations.appLockUnavailable,
            ),
            value: settings.isAppLockEnabled,
            onChanged: isAppLockToggleEnabled
                ? (isEnabled) => _changeAppLock(context, ref, isEnabled: isEnabled)
                : null,
          ),
          ListTile(
            leading: HabitIconBadge(icon: KomitIcons.shieldCheck, color: komitColors.mutedText),
            title: Text(localizations.privacyLink),
            trailing: const Icon(KomitIcons.chevronRight),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          SwitchListTile(
            secondary: HabitIconBadge(icon: KomitIcons.eyeOff, color: komitColors.mutedText),
            title: Text(localizations.hideScreenContentSetting),
            subtitle: Text(localizations.hideScreenContentSettingDescription),
            value: settings.isScreenContentHidden,
            onChanged: (isHidden) {
              unawaited(KomitHaptics.selection());
              settingsController.updateScreenContentHidden(isHidden: isHidden);
            },
          ),
        ],
      ),
    );
  }

  /// Turning the lock on asks to unlock once, so nobody locks themselves out of a lock that
  /// does not work on their phone.
  Future<void> _changeAppLock(BuildContext context, WidgetRef ref, {required bool isEnabled}) async {
    final localizations = AppLocalizations.of(context);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    if (!isEnabled) {
      unawaited(KomitHaptics.selection());
      await settingsController.updateAppLockEnabled(isEnabled: false);
      return;
    }
    final AppLockAuthenticationResult result;
    try {
      result = await ref
          .read(appLockServiceProvider)
          .authenticate(title: localizations.appLockSetting, subtitle: localizations.appLockPromptSubtitle);
    } on PlatformException catch (error, stackTrace) {
      unawaited(ref.read(appLoggerProvider).logError(event: 'app_lock_failed', error: error, stackTrace: stackTrace));
      if (context.mounted) showMessageSnackBar(context, localizations.appLockFailed);
      return;
    }
    if (result == AppLockAuthenticationResult.succeeded) {
      unawaited(KomitHaptics.success());
      await settingsController.updateAppLockEnabled(isEnabled: true);
    } else if (result == AppLockAuthenticationResult.unavailable) {
      ref.invalidate(canUseAppLockProvider);
    }
  }
}

/// Days without an export after which Settings reminds the user to save one.
const int _daysWithoutExportBeforeReminder = 30;

/// Export, import and restore. One operation at a time: while one runs, every tile is disabled
/// and the running one shows a spinner, since encoding a long history takes a moment.
class _DataAndStorageCard extends ConsumerStatefulWidget {
  const _DataAndStorageCard();

  @override
  ConsumerState<_DataAndStorageCard> createState() => _DataAndStorageCardState();
}

enum _BackupOperation { export, encryptedExport, import, restore }

class _DataAndStorageCardState extends ConsumerState<_DataAndStorageCard> {
  _BackupOperation? _runningOperation;

  Future<void> _run(_BackupOperation operation, Future<Object?> Function() action) async {
    setState(() => _runningOperation = operation);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _runningOperation = null);
    }
  }

  Future<void> _askPassphraseAndExportEncrypted() async {
    final passphrase = await showBackupPassphraseDialog(context, purpose: BackupPassphrasePurpose.encrypt);
    if (passphrase == null || !mounted) return;
    await _run(
      _BackupOperation.encryptedExport,
      () => exportBackupToUserChosenFile(context, ref, passphrase: passphrase),
    );
  }

  Future<void> _chooseAndRestoreAutomaticBackup() async {
    final backup = await showAutomaticBackupsSheet(context);
    if (backup == null || !mounted) return;
    await _run(_BackupOperation.restore, () => restoreAutomaticBackup(context, ref, backup));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final lastExportAt = ref.watch(settingsControllerProvider).lastExportAt;
    final daysSinceLastExport = lastExportAt == null
        ? null
        : ref.watch(currentCalendarDayProvider).daysSinceEpoch - CalendarDay.fromDateTime(lastExportAt).daysSinceEpoch;
    final isExportReminderShown =
        daysSinceLastExport != null && daysSinceLastExport >= _daysWithoutExportBeforeReminder;
    final isIdle = _runningOperation == null;

    Widget trailingFor(_BackupOperation operation) => _runningOperation == operation
        ? const SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(strokeWidth: AppSizes.inlineProgressIndicatorStroke),
          )
        : const Icon(KomitIcons.chevronRight);

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: HabitIconBadge(
              icon: KomitIcons.download,
              color: isExportReminderShown ? colorScheme.primary : komitColors.mutedText,
            ),
            title: Text(localizations.exportData),
            subtitle: isExportReminderShown ? Text(localizations.lastExportDaysAgo(daysSinceLastExport)) : null,
            trailing: trailingFor(_BackupOperation.export),
            enabled: isIdle,
            onTap: () => _run(_BackupOperation.export, () => exportBackupToUserChosenFile(context, ref)),
          ),
          ListTile(
            leading: HabitIconBadge(icon: KomitIcons.lockKeyhole, color: komitColors.mutedText),
            title: Text(localizations.exportEncryptedData),
            subtitle: Text(localizations.exportEncryptedDataDescription),
            trailing: trailingFor(_BackupOperation.encryptedExport),
            enabled: isIdle,
            onTap: _askPassphraseAndExportEncrypted,
          ),
          ListTile(
            // Neutral like export: the confirmation dialog carries the warning.
            leading: HabitIconBadge(icon: KomitIcons.upload, color: komitColors.mutedText),
            title: Text(localizations.importData),
            trailing: trailingFor(_BackupOperation.import),
            enabled: isIdle,
            onTap: () => _run(_BackupOperation.import, () => importBackupFromUserChosenFile(context, ref)),
          ),
          ListTile(
            leading: HabitIconBadge(icon: KomitIcons.history, color: komitColors.mutedText),
            title: Text(localizations.restoreAutomaticBackup),
            trailing: trailingFor(_BackupOperation.restore),
            enabled: isIdle,
            onTap: _chooseAndRestoreAutomaticBackup,
          ),
        ],
      ),
    );
  }
}

/// The live notification status (refreshed when the app resumes) and the way to change it.
class _NotificationSettingsCard extends ConsumerWidget {
  const _NotificationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final status = ref.watch(notificationStatusProvider);
    final (statusIcon, statusColor, statusText) = switch (status) {
      AsyncData(value: NotificationStatus.enabled) => (
        KomitIcons.bellRing,
        colorScheme.primary,
        localizations.notificationsStatusEnabled,
      ),
      AsyncData(value: NotificationStatus.disabled) => (
        KomitIcons.bellOff,
        colorScheme.error,
        localizations.notificationsStatusDisabled,
      ),
      AsyncData(value: NotificationStatus.unavailable) ||
      AsyncError() => (KomitIcons.bellOff, komitColors.mutedText, localizations.notificationsStatusUnavailable),
      _ => (KomitIcons.bell, komitColors.mutedText, localizations.loading),
    };
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          MergeSemantics(
            child: ListTile(
              leading: HabitIconBadge(icon: statusIcon, color: statusColor),
              title: Text(localizations.notificationsStatusTitle),
              subtitle: Text(statusText),
            ),
          ),
          ListTile(
            leading: HabitIconBadge(icon: KomitIcons.settings, color: komitColors.mutedText),
            title: Text(localizations.openSystemSettings),
            trailing: const Icon(KomitIcons.externalLink),
            onTap: () => _openNotificationSettings(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotificationSettings(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationPermissionServiceProvider).openNotificationSettings();
    } on Object catch (error, stackTrace) {
      unawaited(
        ref
            .read(appLoggerProvider)
            .logError(event: 'notification_settings_failed', error: error, stackTrace: stackTrace),
      );
      if (context.mounted) showMessageSnackBar(context, AppLocalizations.of(context).settingsUnavailable);
    }
  }
}

class _UserNameField extends StatefulWidget {
  const _UserNameField({required this.initialUserName, required this.onSubmitted, super.key});

  final String? initialUserName;
  final ValueChanged<String> onSubmitted;

  @override
  State<_UserNameField> createState() => _UserNameFieldState();
}

class _UserNameFieldState extends State<_UserNameField> {
  late final _controller = TextEditingController(text: widget.initialUserName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
        widget.onSubmitted(_controller.text);
      },
    );
  }
}
