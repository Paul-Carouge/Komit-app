import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum ReleaseNotesBlockKind { heading, bullet, paragraph }

/// A line of release notes. [spans] alternate plain and bold text, starting with plain.
class ReleaseNotesBlock {
  const ReleaseNotesBlock(this.kind, this.spans);

  final ReleaseNotesBlockKind kind;
  final List<String> spans;
}

final RegExp _headingPattern = RegExp(r'^#{1,6}\s+(.*)$');
final RegExp _bulletPattern = RegExp(r'^[-*]\s+(.*)$');

/// The "## Komit 2.3.1" line repeats the version the screen title already shows.
final RegExp _versionHeadingPattern = RegExp(r'^Komit\s+v?\d+\.\d+\.\d+\s*$');

/// Reads the small Markdown subset Komit's release notes use: headings, bullets, paragraphs
/// and **bold**. Everything else stays literal text: remote content is never interpreted as
/// links, images or HTML.
List<ReleaseNotesBlock> parseReleaseNotes(String releaseNotes) {
  final blocks = <ReleaseNotesBlock>[];
  for (final rawLine in releaseNotes.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final heading = _headingPattern.firstMatch(line)?.group(1);
    if (heading != null) {
      if (!_versionHeadingPattern.hasMatch(heading)) {
        blocks.add(ReleaseNotesBlock(ReleaseNotesBlockKind.heading, _boldSpans(heading)));
      }
      continue;
    }
    final bullet = _bulletPattern.firstMatch(line)?.group(1);
    blocks.add(
      bullet != null
          ? ReleaseNotesBlock(ReleaseNotesBlockKind.bullet, _boldSpans(bullet))
          : ReleaseNotesBlock(ReleaseNotesBlockKind.paragraph, _boldSpans(line)),
    );
  }
  return blocks;
}

/// Splits on `**`; an unmatched marker stays visible rather than bolding the rest of the line.
List<String> _boldSpans(String text) {
  final parts = text.split('**');
  if (parts.length.isEven) return [text];
  return parts;
}

class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({required this.releaseNotes, super.key});

  final String releaseNotes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final blocks = parseReleaseNotes(releaseNotes);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, block) in blocks.indexed)
            Padding(
              padding: EdgeInsets.only(
                top: index == 0
                    ? 0
                    : block.kind == ReleaseNotesBlockKind.heading
                    ? AppSpacing.large
                    : AppSpacing.small,
              ),
              child: switch (block.kind) {
                ReleaseNotesBlockKind.heading => Semantics(
                  header: true,
                  child: Text.rich(_richText(block.spans), style: textTheme.titleSmall),
                ),
                ReleaseNotesBlockKind.bullet => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Text('•  ', style: textTheme.bodyMedium)),
                    Expanded(child: Text.rich(_richText(block.spans), style: textTheme.bodyMedium)),
                  ],
                ),
                ReleaseNotesBlockKind.paragraph => Text.rich(_richText(block.spans), style: textTheme.bodyMedium),
              },
            ),
        ],
      ),
    );
  }

  TextSpan _richText(List<String> spans) => TextSpan(
    children: [
      for (final (index, span) in spans.indexed)
        TextSpan(
          text: span,
          style: index.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
    ],
  );
}
