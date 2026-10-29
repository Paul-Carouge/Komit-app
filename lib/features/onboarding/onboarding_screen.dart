import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_mascot.dart';
import '../settings/backup_actions.dart';
import '../shared/shared_widgets.dart';

/// Below this screen height Komo shrinks, so the step text and buttons stay above the fold.
const double _compactScreenHeight = 700;

/// Incoming step text rises by this share of its own height while fading in.
const double _stepEntranceRise = 0.04;

enum _OnboardingStep {
  welcome(KomoMood.waving),
  name(KomoMood.idle),
  // Komo is drowsy here: the reminder it offers comes in the evening.
  reminders(KomoMood.sleepy);

  const _OnboardingStep(this.komoMood);

  final KomoMood komoMood;

  _OnboardingStep? get previous => index == 0 ? null : _OnboardingStep.values[index - 1];
}

/// Three short steps led by Komo: hello (or restore a backup), first name, reminders.
/// The reminders step only explains them: Android's permission dialog appears later, in
/// context, when the user turns on the reminder of a habit.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  _OnboardingStep _step = _OnboardingStep.welcome;
  bool _isFinishing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showStep(_OnboardingStep step) {
    unawaited(KomitHaptics.selection());
    setState(() => _step = step);
  }

  Future<void> _finish({String? userName}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    unawaited(KomitHaptics.celebration());
    // Lets Komo finish one happy hop before the dashboard replaces it.
    await Future<void>.delayed(motionAwareDuration(context, AppDurations.mascotHopCycle));
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .completeOnboarding(userName: userName ?? _nameController.text);
    } on Object catch (error) {
      developer.log('Onboarding could not be saved', name: 'komit.onboarding', error: error);
      unawaited(KomitHaptics.error());
      if (!mounted) return;
      setState(() => _isFinishing = false);
      showMessageSnackBar(context, AppLocalizations.of(context).genericError);
      return;
    }
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
    final previousStep = _step.previous;
    final isCompactScreen = MediaQuery.sizeOf(context).height < _compactScreenHeight;
    final stepParts = _buildStepParts(context);
    return PopScope(
      canPop: previousStep == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && previousStep != null) _showStep(previousStep);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.readableContentMaximumWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.small, AppSpacing.small, AppSpacing.extraLarge, 0),
                    child: _OnboardingTopBar(
                      step: _step,
                      onBackPressed: previousStep == null ? null : () => _showStep(previousStep),
                    ),
                  ),
                  Expanded(
                    // Centered when it fits, scrollable with large text, a keyboard or in landscape.
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.extraLarge),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 2 * AppSpacing.extraLarge),
                          ),
                          child: Column(
                            // Komo and the text sit centered above; the actions stay low, near the thumb.
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox.shrink(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: KomoMascot(
                                      mood: _isFinishing ? KomoMood.happy : _step.komoMood,
                                      size: isCompactScreen ? AppSizes.mascotMedium : AppSizes.mascotLarge,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.extraLarge),
                                  _switchWithStep(context, _StepText(parts: stepParts)),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.huge),
                                child: _switchWithStep(context, _StepActions(parts: stepParts)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchWithStep(BuildContext context, Widget child) => AnimatedSwitcher(
    duration: motionAwareDuration(context, AppDurations.standard),
    switchInCurve: AppCurves.standard,
    switchOutCurve: AppCurves.standard,
    transitionBuilder: _slideAndFadeTransition,
    child: KeyedSubtree(key: ValueKey(_step), child: child),
  );

  static Widget _slideAndFadeTransition(Widget child, Animation<double> animation) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, _stepEntranceRise), end: Offset.zero).animate(animation),
      child: child,
    ),
  );

  _StepParts _buildStepParts(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return switch (_step) {
      _OnboardingStep.welcome => _StepParts(
        title: localizations.onboardingTitle,
        message: localizations.onboardingSubtitle,
        primaryAction: FilledButton(
          onPressed: _isFinishing ? null : () => _showStep(_OnboardingStep.name),
          child: Text(localizations.getStarted),
        ),
        secondaryAction: TextButton.icon(
          onPressed: _isFinishing ? null : _restoreFromBackup,
          icon: const Icon(LucideIcons.upload),
          label: Text(localizations.restoreFromBackup),
        ),
      ),
      _OnboardingStep.name => _StepParts(
        title: localizations.onboardingNameTitle,
        message: localizations.onboardingNameMessage,
        field: TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
          onSubmitted: (_) => _showStep(_OnboardingStep.reminders),
          decoration: InputDecoration(labelText: localizations.onboardingNameLabel),
        ),
        primaryAction: FilledButton(
          onPressed: () => _showStep(_OnboardingStep.reminders),
          child: Text(localizations.continueAction),
        ),
        secondaryAction: TextButton(
          onPressed: () {
            _nameController.clear();
            _showStep(_OnboardingStep.reminders);
          },
          child: Text(localizations.skip),
        ),
      ),
      _OnboardingStep.reminders => _StepParts(
        title: localizations.onboardingRemindersTitle,
        message: localizations.onboardingRemindersMessage,
        primaryAction: FilledButton.icon(
          onPressed: _isFinishing ? null : _finish,
          icon: const Icon(LucideIcons.arrowRight),
          label: Text(localizations.getStarted),
        ),
        secondaryAction: TextButton.icon(
          onPressed: _isFinishing ? null : () => context.push(AppRoutes.privacy),
          icon: const Icon(LucideIcons.shieldCheck),
          label: Text(localizations.privacyLink),
        ),
      ),
    };
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.step, required this.onBackPressed});

  final _OnboardingStep step;

  /// Null on the first step, which has nothing to go back to.
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final onBackPressed = this.onBackPressed;
    return SizedBox(
      height: AppSizes.minimumTouchTarget,
      child: Row(
        children: [
          if (onBackPressed != null) BackButton(onPressed: onBackPressed),
          const Spacer(),
          _StepIndicator(currentStepIndex: step.index, stepCount: _OnboardingStep.values.length),
        ],
      ),
    );
  }
}

/// Progress drawn as day cells: done and current steps are filled with amber, like logged days.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStepIndex, required this.stepCount});

  final int currentStepIndex;
  final int stepCount;

  static const double _cellSize = 10;
  static const double _currentCellWidth = 28;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final duration = motionAwareDuration(context, AppDurations.standard);
    return Semantics(
      label: AppLocalizations.of(context).onboardingStepProgress(currentStepIndex + 1, stepCount),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var stepIndex = 0; stepIndex < stepCount; stepIndex++)
            AnimatedContainer(
              duration: duration,
              curve: AppCurves.emphasized,
              margin: const EdgeInsets.only(left: AppSpacing.extraSmall),
              width: stepIndex == currentStepIndex ? _currentCellWidth : _cellSize,
              height: _cellSize,
              decoration: BoxDecoration(
                color: stepIndex <= currentStepIndex ? colorScheme.primary : komitColors.emptyCell,
                borderRadius: BorderRadius.circular(AppRadii.gridCell),
              ),
            ),
        ],
      ),
    );
  }
}

/// What one step shows: its text (and optional field) in the middle, its actions at the bottom.
class _StepParts {
  const _StepParts({
    required this.title,
    required this.message,
    required this.primaryAction,
    this.secondaryAction,
    this.field,
  });

  final String title;
  final String message;
  final Widget? field;
  final Widget primaryAction;
  final Widget? secondaryAction;
}

class _StepText extends StatelessWidget {
  const _StepText({required this.parts});

  final _StepParts parts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final field = parts.field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(parts.title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          parts.message,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: KomitColors.of(context).mutedText),
        ),
        if (field != null) ...[const SizedBox(height: AppSpacing.extraLarge), field],
      ],
    );
  }
}

class _StepActions extends StatelessWidget {
  const _StepActions({required this.parts});

  final _StepParts parts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        parts.primaryAction,
        const SizedBox(height: AppSpacing.small),
        // Keeps the primary button where it was on the previous steps.
        parts.secondaryAction ?? const SizedBox(height: AppSizes.minimumTouchTarget),
      ],
    );
  }
}
