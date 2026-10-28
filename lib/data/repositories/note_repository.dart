import 'package:drift/drift.dart';

import '../database/app_database.dart';

class NoteRepository {
  NoteRepository(this._database);

  final AppDatabase _database;

  Stream<List<NoteRow>> watchNotesMostRecentlyUpdatedFirst() {
    final query = _database.select(_database.notes)..orderBy([(note) => OrderingTerm.desc(note.updatedAt)]);
    return query.watch();
  }

  Future<NoteRow?> findNoteById(int noteId) =>
      (_database.select(_database.notes)..where((note) => note.id.equals(noteId))).getSingleOrNull();

  /// Returns the id of the saved note.
  Future<int> saveNote({required int? noteId, required String content}) async {
    final now = DateTime.now();
    if (noteId == null) {
      return _database
          .into(_database.notes)
          .insert(NotesCompanion.insert(content: content, createdAt: now, updatedAt: now));
    }
    await (_database.update(
      _database.notes,
    )..where((note) => note.id.equals(noteId))).write(NotesCompanion(content: Value(content), updatedAt: Value(now)));
    return noteId;
  }

  Future<void> deleteNote(int noteId) =>
      (_database.delete(_database.notes)..where((note) => note.id.equals(noteId))).go();
}
