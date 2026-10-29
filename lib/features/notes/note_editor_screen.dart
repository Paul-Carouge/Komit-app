import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({required this.noteId, super.key});

  /// Null creates a new note.
  final int? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _contentController = TextEditingController();
  int? _noteId;
  String _savedContent = '';
  DateTime? _createdAt;
  bool _isLoading = true;

  /// The last save in the queue. Saves run one after another: a back gesture while the
  /// check button's save is still writing would otherwise insert the new note twice.
  Future<void> _lastQueuedSave = Future.value();

  /// Android may end a paused app without warning; saving then keeps what was typed.
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId;
    _lifecycleListener = AppLifecycleListener(onPause: _saveInBackground);
    _loadNote();
  }

  Future<void> _loadNote() async {
    final noteId = _noteId;
    if (noteId != null) {
      final note = await ref.read(noteRepositoryProvider).findNoteById(noteId);
      if (!mounted) return;
      if (note == null) {
        context.pop();
        return;
      }
      _contentController.text = note.content;
      _savedContent = note.content;
      _createdAt = note.createdAt;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Queues a save of the text as it is now. The text and the repository are read right away,
  /// because the queued save may run after this screen is gone.
  Future<void> _enqueueSave() {
    final content = _contentController.text.trim();
    final repository = ref.read(noteRepositoryProvider);
    final save = _lastQueuedSave.then((_) async {
      if (content.isEmpty || content == _savedContent.trim()) return;
      _noteId = await repository.saveNote(noteId: _noteId, content: content);
      _savedContent = content;
    });
    // The caller awaiting [save] reports its error; the queue itself only needs to move on.
    _lastQueuedSave = save.then<void>((_) {}, onError: (Object _) {});
    return save;
  }

  /// Saving on leave and on pause means a note is never lost to a back gesture or a closed app.
  /// A failure is logged and explained, even if the screen has closed meanwhile.
  Future<void> _saveInBackground() async {
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    final logger = ref.read(appLoggerProvider);
    try {
      await _enqueueSave();
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(logger.logError(event: 'note_save_failed', error: error, stackTrace: stackTrace));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(localizations.noteSaveFailed)));
    }
  }

  Future<void> _saveAndClose() async {
    final logger = ref.read(appLoggerProvider);
    try {
      await _enqueueSave();
      unawaited(KomitHaptics.success());
      if (mounted) context.pop();
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(logger.logError(event: 'note_save_failed', error: error, stackTrace: stackTrace));
      if (mounted) showMessageSnackBar(context, AppLocalizations.of(context).noteSaveFailed);
    }
  }

  Future<void> _delete() async {
    final localizations = AppLocalizations.of(context);
    final noteId = _noteId;
    if (noteId == null) {
      context.pop();
      return;
    }
    final isConfirmed = await showDestructiveConfirmationDialog(
      context,
      message: localizations.deleteNoteConfirmation,
      confirmLabel: localizations.delete,
    );
    if (!isConfirmed || !mounted) return;
    try {
      await ref.read(noteRepositoryProvider).deleteNote(noteId);
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(
        ref.read(appLoggerProvider).logError(event: 'note_delete_failed', error: error, stackTrace: stackTrace),
      );
      if (mounted) showMessageSnackBar(context, localizations.genericError);
      return;
    }
    unawaited(KomitHaptics.warning());
    // The note is gone: leaving must not save it again.
    _savedContent = _contentController.text;
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(_createdAt ?? DateTime.now());
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_saveInBackground());
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: KomitColors.of(context).mutedText),
          ),
          actions: [
            if (_noteId != null)
              IconButton(tooltip: localizations.deleteNote, onPressed: _delete, icon: const Icon(LucideIcons.trash2)),
            IconButton(
              tooltip: localizations.save,
              onPressed: _isLoading ? null : _saveAndClose,
              icon: const Icon(LucideIcons.check),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(semanticsLabel: localizations.loading))
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
                child: TextField(
                  controller: _contentController,
                  autofocus: widget.noteId == null,
                  expands: true,
                  maxLines: null,
                  maxLength: maximumNoteContentLength,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: borderlessInlineInputDecoration(hintText: localizations.noteHint),
                ),
              ),
      ),
    );
  }
}
