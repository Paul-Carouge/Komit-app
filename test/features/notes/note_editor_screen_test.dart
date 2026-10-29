import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/router.dart';

import '../../support/komit_test_app.dart';

void main() {
  testWidgets('saving a new note, then going back before the save ends, stores it once', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final router = await pumpKomitApp(tester, environment, theme: lightAppTheme, location: AppRoutes.notes);
    unawaited(router.push(AppRoutes.newNote));
    await settleWithDatabaseWork(tester);
    const content = 'Buy trail shoes before the race.';

    await tester.enterText(find.byType(TextField), content);
    // An open transaction holds the write lock, so the first save is still waiting when the
    // back gesture lands, like a slow write on a real phone.
    final releaseWriteLock = Completer<void>();
    final database = environment.database;
    final heldTransaction = database.transaction(() => releaseWriteLock.future);
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    releaseWriteLock.complete();
    await tester.runAsync(() => heldTransaction);
    await settleWithDatabaseWork(tester);

    final notes = await tester.runAsync(
      () => (database.select(database.notes)..where((note) => note.content.equals(content))).get(),
    );
    expect(notes, hasLength(1));
    await environment.dispose(tester);
  });
}
