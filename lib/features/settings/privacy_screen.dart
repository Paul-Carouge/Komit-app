import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/automatic_backup_service.dart';
import '../shared/shared_widgets.dart';

/// What stays on the phone and what leaves it, in plain words: the update check, backups,
/// exports, and each Android permission with the reason Komit needs it.
///
/// Keep the permission list equal to releaseManifestAllowedPermissions in app/build.gradle.kts.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = KomitColors.of(context).mutedText;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(title: localizations.privacyTitle),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              0,
              AppSpacing.screenGutter,
              AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  localizations.privacyIntroduction,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: mutedColor),
                ),
                SectionTitle(localizations.privacyWhatLeavesTitle),
                _PrivacyCard(
                  entries: [
                    (
                      LucideIcons.refreshCw,
                      colorScheme.primary,
                      localizations.privacyUpdateCheckTitle,
                      localizations.privacyUpdateCheckBody,
                    ),
                    (
                      LucideIcons.eyeOff,
                      mutedColor,
                      localizations.privacyNoTrackingTitle,
                      localizations.privacyNoTrackingBody,
                    ),
                  ],
                ),
                SectionTitle(localizations.privacyBackupsTitle),
                _PrivacyCard(
                  entries: [
                    (
                      LucideIcons.cloudOff,
                      colorScheme.primary,
                      localizations.privacyCloudBackupTitle,
                      localizations.privacyCloudBackupBody,
                    ),
                    (
                      LucideIcons.history,
                      mutedColor,
                      localizations.automaticBackups,
                      localizations.privacyAutomaticBackupsBody(automaticBackupRetentionCount),
                    ),
                    (
                      LucideIcons.fileJson,
                      mutedColor,
                      localizations.privacyPlainExportTitle,
                      localizations.privacyPlainExportBody,
                    ),
                    (
                      LucideIcons.lockKeyhole,
                      mutedColor,
                      localizations.privacyEncryptedExportTitle,
                      localizations.privacyEncryptedExportBody,
                    ),
                    (
                      LucideIcons.scrollText,
                      mutedColor,
                      localizations.privacyErrorLogTitle,
                      localizations.privacyErrorLogBody,
                    ),
                  ],
                ),
                SectionTitle(localizations.privacyPermissionsTitle),
                _PrivacyCard(
                  entries: [
                    (
                      LucideIcons.bell,
                      mutedColor,
                      localizations.permissionNotificationsTitle,
                      localizations.permissionNotificationsBody,
                    ),
                    (
                      LucideIcons.power,
                      mutedColor,
                      localizations.permissionStartupTitle,
                      localizations.permissionStartupBody,
                    ),
                    (
                      LucideIcons.download,
                      mutedColor,
                      localizations.permissionInstallTitle,
                      localizations.permissionInstallBody,
                    ),
                    (
                      LucideIcons.globe,
                      mutedColor,
                      localizations.permissionInternetTitle,
                      localizations.permissionInternetBody,
                    ),
                    (
                      LucideIcons.vibrate,
                      mutedColor,
                      localizations.permissionVibrationTitle,
                      localizations.permissionVibrationBody,
                    ),
                    (
                      LucideIcons.fingerprint,
                      mutedColor,
                      localizations.permissionBiometricTitle,
                      localizations.permissionBiometricBody,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.entries});

  final List<(IconData icon, Color color, String title, String body)> entries;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        children: [
          for (final (icon, color, title, body) in entries)
            MergeSemantics(
              child: ListTile(
                leading: HabitIconBadge(icon: icon, color: color),
                title: Text(title),
                subtitle: Text(body),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}
