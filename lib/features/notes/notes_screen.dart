import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';

const int _notePreviewMaximumLines = 4;

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final notes = ref.watch(notesProvider);
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.extraLarge,
                AppSpacing.small,
                AppSpacing.large,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(localizations.secondBrain, style: textTheme.headlineSmall),
                      ),
                    ),
                    IconButton(
                      tooltip: localizations.settingsTooltip,
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(LucideIcons.settings),
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              sliver: SliverToBoxAdapter(child: _NewNoteBanner()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              sliver: SliverToBoxAdapter(child: SectionTitle(localizations.myNotes)),
            ),
            switch (notes) {
              AsyncData(value: final notes) when notes.isEmpty => SliverToBoxAdapter(
                child: KomoEmptyState(
                  mood: KomoMood.idle,
                  title: localizations.noNotesYet,
                  message: localizations.noNotesYetMessage,
                ),
              ),
              AsyncData(value: final notes) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  0,
                  AppSpacing.screenGutter,
                  AppSpacing.extraLarge,
                ),
                sliver: SliverList.separated(
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.medium),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return PressableCard(
                      onTap: () => context.push(AppRoutes.noteEditor(note.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(note.updatedAt),
                              style: textTheme.labelMedium?.copyWith(color: komitColors.mutedText),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            Text(note.content, maxLines: _notePreviewMaximumLines, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _ => SliverToBoxAdapter(
                child: AsyncValueView(value: notes, builder: (_) => const SizedBox()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _NewNoteBanner extends StatelessWidget {
  const _NewNoteBanner();

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final foregroundColor = komitColors.onNotesGradient;
    return PressableCard(
      gradient: LinearGradient(colors: [komitColors.notesGradientStart, komitColors.notesGradientEnd]),
      onTap: () => context.push(AppRoutes.newNote),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        child: Row(
          children: [
            Container(
              width: AppSizes.heroBadge,
              height: AppSizes.heroBadge,
              decoration: BoxDecoration(
                color: foregroundColor.withValues(alpha: AppOpacity.overlayOnColor),
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
              child: Icon(LucideIcons.plus, color: foregroundColor, size: AppSizes.iconHero),
            ),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Text(
                AppLocalizations.of(context).newNote,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foregroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
