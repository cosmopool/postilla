// Settings › Sobre (AJU-04, OFF-13): the app's colophon, in the same form as a
// story's (LEI-13), inside a surface card with the wordmark and the credits.
import 'package:flutter/material.dart';

import '../strings.dart';
import '../ui/theme.dart';

const appVersion = '0.1.0';

/// Facts the colophon shows. Zero values are valid: the rows show what is known.
class AboutFacts {
  const AboutFacts({this.dictVersion = '', this.dumpDate = '', this.stories = 0, this.cursor = 0});
  final String dictVersion;
  final String dumpDate; // YYYY-MM-DD
  final int stories; // on the device, for the current pair
  final int cursor; // stored feed cursor
}

/// "2026-10-01" → "01/10/2026".
String dumpDateLabel(String iso) => iso.isEmpty ? '' : iso.split('-').reversed.join('/');

class AboutCard extends StatelessWidget {
  const AboutCard({super.key, required this.facts});
  final AboutFacts facts;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final dump = dumpDateLabel(facts.dumpDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wordmark(size: 28),
          const SizedBox(height: 16),
          Colophon(rows: [
            (ui.appLabel, ui.versionN(appVersion), ''),
            (ui.dictionaryContent, ui.versionN(facts.dictVersion), dump.isEmpty ? '' : ui.wikiDump(dump)),
            (ui.storiesContent, ui.storiesOnDevice(facts.stories), ui.syncCursor(facts.cursor)),
          ]),
          const SizedBox(height: 16),
          Text(ui.creditsText, style: T.meta.copyWith(color: t.inkMuted)),
        ],
      ),
    );
  }
}

/// Labelled rows (`.ui-colophon`): the label column is as wide as the longest
/// label; the second line is muted.
class Colophon extends StatelessWidget {
  const Colophon({super.key, required this.rows});
  final List<(String, String, String)> rows; // label, value, second line

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: t.rule)),
      ),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (final (i, (label, value, second)) in rows.indexed)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12, top: i == 0 ? 0 : 8),
                  child: Text(label.toUpperCase(), style: T.label.copyWith(color: t.inkMuted)),
                ),
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: T.small.copyWith(color: t.ink)),
                      if (second.isNotEmpty) Text(second, style: T.meta.copyWith(color: t.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "Postılla" with the accent dot on the dotless i (identity › wordmark).
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final style = TextStyle(
      fontFamily: 'Newsreader',
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
      letterSpacing: -0.025 * size,
      color: t.ink,
    );
    final dot = t.dark ? t.accent : const Color(0xFFD9AD00); // --color-accent-mark
    return Semantics(
      label: 'Postilla',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Post'),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text('ı', style: style),
                  Positioned(
                    top: size * 0.05,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: size * 0.135,
                        height: size * 0.135,
                        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const TextSpan(text: 'lla'),
          ],
        ),
      ),
    );
  }
}
