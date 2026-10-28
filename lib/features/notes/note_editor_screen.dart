import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId;
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
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges => _contentController.text.trim() != _savedContent.trim();

  /// Saving on leave means a note is never lost to an accidental back gesture.
  Future<void> _saveIfChanged() async {
    final content = _contentController.text.trim();
    if (!_hasUnsavedChanges || content.isEmpty) return;
    _noteId = await ref.read(noteRepositoryProvider).saveNote(noteId: _noteId, content: content);
    _savedContent = content;
  }

  Future<void> _saveAndClose() async {
    try {
      await _saveIfChanged();
      unawaited(KomitHaptics.success());
      if (mounted) context.pop();
    } on Object {
      unawaited(KomitHaptics.error());
      if (mounted) showMessageSnackBar(context, AppLocalizations.of(context).genericError);
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
    await ref.read(noteRepositoryProvider).deleteNote(noteId);
    unawaited(KomitHaptics.warning());
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
        if (didPop) unawaited(_saveIfChanged());
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
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
                child: TextField(
                  controller: _contentController,
                  autofocus: widget.noteId == null,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: localizations.noteHint,
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
      ),
    );
  }
}
