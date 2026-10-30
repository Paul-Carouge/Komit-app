import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/updates/release_notes.dart';
import 'package:komit/features/updates/update_prompt.dart';
import 'package:komit/l10n/app_localizations.dart';

import '../../support/komit_test_app.dart';

void main() {
  test('reads headings, bullets, paragraphs and bold, dropping the version heading', () {
    final blocks = parseReleaseNotes('''
## Komit 2.4.0

### Nouveautés
- **Ton bilan de l'année** : Komo raconte ton année.
* Une autre ligne

Merci d'utiliser Komit !
''');

    expect(
      [for (final block in blocks) block.kind],
      [
        ReleaseNotesBlockKind.heading,
        ReleaseNotesBlockKind.bullet,
        ReleaseNotesBlockKind.bullet,
        ReleaseNotesBlockKind.paragraph,
      ],
    );
    expect(blocks[0].spans, ['Nouveautés']);
    expect(blocks[1].spans, ['', "Ton bilan de l'année", ' : Komo raconte ton année.']);
    expect(blocks[2].spans, ['Une autre ligne']);
    expect(blocks[3].spans, ["Merci d'utiliser Komit !"]);
  });

  test('keeps links, HTML and an unmatched bold marker as literal text', () {
    final blocks = parseReleaseNotes('[clic](https://example.com) <b>x</b> **pas fermé');

    expect(blocks.single.kind, ReleaseNotesBlockKind.paragraph);
    expect(blocks.single.spans, ['[clic](https://example.com) <b>x</b> **pas fermé']);
  });

  test('an indented line continues the bullet above it, bold included', () {
    final blocks = parseReleaseNotes('- **Un bilan\n  de ton année** : Komo raconte\n  ton année.\nUn paragraphe.');

    expect([for (final block in blocks) block.kind], [ReleaseNotesBlockKind.bullet, ReleaseNotesBlockKind.paragraph]);
    expect(blocks.first.spans, ['', 'Un bilan de ton année', ' : Komo raconte ton année.']);
  });

  test('empty notes give no block', () {
    expect(parseReleaseNotes('  \n\n'), isEmpty);
  });

  testWidgets('the welcome sheet shows the rendered notes on a compact phone and closes', (tester) async {
    tester.view.physicalSize = compactPhoneLogicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: lightAppTheme,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showWhatsNewSheet(
              context,
              version: '2.4.0',
              releaseNotes: '## Komit 2.4.0\n\n### Nouveautés\n- **Nouveautés après une mise à jour** : une fois.',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Bienvenue dans la 2.4.0'), findsOneWidget);
    expect(find.textContaining('Komit 2.4.0'), findsNothing);
    expect(find.text('Nouveautés'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text("C'est parti"));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Bienvenue dans la 2.4.0'), findsNothing);
  });
}
