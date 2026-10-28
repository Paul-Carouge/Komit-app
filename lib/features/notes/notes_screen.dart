import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/game_badges.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_card.dart';
import '../../core/ui/game_text.dart';
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
                AppSpacing.screenGutter,
                AppSpacing.large,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: GameTitle(localizations.secondBrain, style: textTheme.headlineMedium)),
                    GameIconButton(
                      icon: LucideIcons.settings,
                      tooltip: localizations.settingsTooltip,
                      onPressed: () => context.push(AppRoutes.settings),
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
                    return GameCard(
                      onTap: () => context.push(AppRoutes.noteEditor(note.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(note.updatedAt),
                            style: textTheme.labelMedium?.copyWith(color: komitColors.mutedText),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            note.content,
                            maxLines: _notePreviewMaximumLines,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge,
                          ),
                        ],
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
    return GameCard(
      color: komitColors.notesFace,
      isHero: true,
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      onTap: () => context.push(AppRoutes.newNote),
      child: Row(
        children: [
          GameBadge(icon: LucideIcons.plus, color: Theme.of(context).colorScheme.primary, size: AppSizes.heroBadge),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: GameTitle(
              AppLocalizations.of(context).newNote,
              isHeader: false,
              onColor: komitColors.notesFace,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}
