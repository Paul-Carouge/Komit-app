import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';
import '../updates/update_prompt.dart';
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
    final currentLanguageCode =
        settings.languageCode ?? (Localizations.localeOf(context).languageCode == 'fr' ? 'fr' : 'en');
    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.huge),
        children: [
          SectionTitle(localizations.yourName),
          _UserNameField(initialUserName: settings.userName, onSubmitted: settingsController.updateUserName),
          SectionTitle(localizations.appearance),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (themeMode) {
                if (themeMode != null) settingsController.updateThemeMode(themeMode);
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
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'fr', label: Text('Français')),
            ],
            selected: {currentLanguageCode},
            onSelectionChanged: (selection) => settingsController.updateLanguageCode(selection.single),
          ),
          SectionTitle(localizations.dataAndStorage),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: HabitIconBadge(icon: LucideIcons.download, color: komitColors.mutedText),
                  title: Text(localizations.exportData),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => exportBackupToUserChosenFile(context, ref),
                ),
                ListTile(
                  leading: HabitIconBadge(icon: LucideIcons.upload, color: colorScheme.error),
                  title: Text(localizations.importData, style: TextStyle(color: colorScheme.error)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => importBackupFromUserChosenFile(context, ref),
                ),
              ],
            ),
          ),
          if (ref.watch(appUpdateServiceProvider).isSupported) ...[
            SectionTitle(localizations.updates),
            Card(
              child: ListTile(
                leading: HabitIconBadge(icon: LucideIcons.refreshCw, color: colorScheme.primary),
                title: Text(localizations.checkForUpdates),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => checkForUpdate(context, ref, isUserInitiated: true),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.huge),
          if (installedVersion != null)
            Text(
              localizations.versionLabel(installedVersion),
              textAlign: TextAlign.center,
              style: TextStyle(color: komitColors.mutedText),
            ),
        ],
      ),
    );
  }
}

class _UserNameField extends StatefulWidget {
  const _UserNameField({required this.initialUserName, required this.onSubmitted});

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
