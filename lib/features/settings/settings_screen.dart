import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';
import '../updates/update_prompt.dart';
import '../../services/notification_permission_service.dart';
import 'backup_actions.dart';

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
                          (ThemeMode.system, LucideIcons.smartphone, localizations.themeSystem),
                          (ThemeMode.light, LucideIcons.sun, localizations.themeLight),
                          (ThemeMode.dark, LucideIcons.moon, localizations.themeDark),
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
                  selectedIcon: const Icon(LucideIcons.check),
                  onSelectionChanged: (selection) {
                    unawaited(KomitHaptics.selection());
                    settingsController.updateLanguageCode(selection.single);
                  },
                ),
                SectionTitle(localizations.notifications),
                const _NotificationSettingsCard(),
                SectionTitle(localizations.dataAndStorage),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: HabitIconBadge(icon: LucideIcons.download, color: komitColors.mutedText),
                        title: Text(localizations.exportData),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () => exportBackupToUserChosenFile(context, ref),
                      ),
                      ListTile(
                        // Neutral like export: the confirmation dialog carries the warning.
                        leading: HabitIconBadge(icon: LucideIcons.upload, color: komitColors.mutedText),
                        title: Text(localizations.importData),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () => importBackupFromUserChosenFile(context, ref),
                      ),
                    ],
                  ),
                ),
                if (ref.watch(appUpdateServiceProvider).isSupported) ...[
                  SectionTitle(localizations.updates),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: HabitIconBadge(icon: LucideIcons.refreshCw, color: colorScheme.primary),
                      title: Text(localizations.checkForUpdates),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => checkForUpdate(context, ref, isUserInitiated: true),
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
                          leading: HabitIconBadge(icon: LucideIcons.info, color: komitColors.mutedText),
                          title: Text(localizations.versionLabel(installedVersion)),
                        ),
                      ListTile(
                        leading: HabitIconBadge(icon: LucideIcons.scrollText, color: komitColors.mutedText),
                        title: Text(localizations.openSourceLicenses),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: localizations.appTitle,
                          applicationVersion: installedVersion,
                        ),
                      ),
                      if (ref.watch(appUpdateServiceProvider).isSupported)
                        ListTile(
                          leading: HabitIconBadge(icon: LucideIcons.history, color: komitColors.mutedText),
                          title: Text(localizations.allVersionsOnGitHub),
                          trailing: const Icon(LucideIcons.externalLink),
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
        LucideIcons.bellRing,
        colorScheme.primary,
        localizations.notificationsStatusEnabled,
      ),
      AsyncData(value: NotificationStatus.disabled) => (
        LucideIcons.bellOff,
        colorScheme.error,
        localizations.notificationsStatusDisabled,
      ),
      AsyncData(value: NotificationStatus.unavailable) ||
      AsyncError() => (LucideIcons.bellOff, komitColors.mutedText, localizations.notificationsStatusUnavailable),
      _ => (LucideIcons.bell, komitColors.mutedText, localizations.loading),
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
            leading: HabitIconBadge(icon: LucideIcons.settings, color: komitColors.mutedText),
            title: Text(localizations.openSystemSettings),
            trailing: const Icon(LucideIcons.externalLink),
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
