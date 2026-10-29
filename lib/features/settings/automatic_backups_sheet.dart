import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/automatic_backup_service.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';
import 'backup_actions.dart';

/// Lists the automatic backups, newest first; returns the one the user chose to restore.
Future<AutomaticBackup?> showAutomaticBackupsSheet(BuildContext context) => showModalBottomSheet<AutomaticBackup>(
  context: context,
  // Root navigator, like every Komit sheet: it covers the frosted navigation bar instead of sliding under it.
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => const _AutomaticBackupsSheet(),
);

class _AutomaticBackupsSheet extends ConsumerWidget {
  const _AutomaticBackupsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(localizations.automaticBackups, style: textTheme.headlineSmall)),
            const SizedBox(height: AppSpacing.small),
            Text(
              localizations.automaticBackupsExplanation(automaticBackupRetentionCount),
              style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
            ),
            const SizedBox(height: AppSpacing.large),
            Flexible(
              child: AsyncValueView(
                value: ref.watch(automaticBackupsProvider),
                retryProvider: automaticBackupsProvider,
                builder: (backups) => backups.isEmpty
                    ? KomoEmptyState(
                        mood: KomoMood.sleepy,
                        mascotSize: AppSizes.mascotSmall,
                        title: localizations.noAutomaticBackupsTitle,
                        message: localizations.noAutomaticBackupsMessage,
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final backup in backups)
                            ListTile(
                              leading: HabitIconBadge(
                                icon: switch (backup.reason) {
                                  AutomaticBackupReason.beforeImport => KomitIcons.upload,
                                  AutomaticBackupReason.beforeUpdate => KomitIcons.refreshCw,
                                  AutomaticBackupReason.daily => KomitIcons.calendarCheck,
                                },
                                color: komitColors.mutedText,
                              ),
                              title: Text(formatAutomaticBackupDate(context, backup)),
                              subtitle: Text(switch (backup.reason) {
                                AutomaticBackupReason.beforeImport => localizations.automaticBackupBeforeImport,
                                AutomaticBackupReason.beforeUpdate => localizations.automaticBackupBeforeUpdate,
                                AutomaticBackupReason.daily => localizations.automaticBackupDaily,
                              }),
                              trailing: const Icon(KomitIcons.chevronRight),
                              onTap: () => Navigator.of(context).pop(backup),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
