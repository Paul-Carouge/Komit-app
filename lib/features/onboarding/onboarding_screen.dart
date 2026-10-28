import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../settings/backup_actions.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish({String? userName}) async {
    await ref.read(settingsControllerProvider.notifier).completeOnboarding(userName: userName ?? _nameController.text);
    if (mounted) context.go(AppRoutes.habits);
  }

  Future<void> _restoreFromBackup() async {
    final isImported = await importBackupFromUserChosenFile(context, ref);
    // The backup may carry the user's name; keep it rather than an empty field.
    if (isImported && mounted) {
      await _finish(userName: ref.read(settingsControllerProvider).userName ?? _nameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          children: [
            const SizedBox(height: AppSpacing.huge),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                ),
                child: Icon(
                  LucideIcons.calendarCheck,
                  size: AppSpacing.huge * 1.5,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            Semantics(
              header: true,
              child: Text(
                localizations.onboardingTitle,
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              localizations.onboardingSubtitle,
              style: textTheme.bodyLarge?.copyWith(color: KomitColors.of(context).mutedText),
            ),
            const SizedBox(height: AppSpacing.huge),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _finish(),
              decoration: InputDecoration(labelText: localizations.onboardingNameLabel),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            FilledButton(onPressed: _finish, child: Text(localizations.getStarted)),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget)),
              onPressed: _restoreFromBackup,
              icon: const Icon(LucideIcons.upload),
              label: Text(localizations.restoreFromBackup),
            ),
          ],
        ),
      ),
    );
  }
}
