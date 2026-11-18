// Reader title page (LEI-13), the wait after a language switch (BIB-12),
// the local reading error (LEI-16) and the translation button (TRA-10).
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// SPDX ids the app names (LEI-13). An id the table lacks shows as is.
const _licenseNames = {
  'CC-BY-SA-4.0': 'CC BY-SA 4.0',
  'CC-BY-4.0': 'CC BY 4.0',
  'CC-BY-SA-3.0': 'CC BY-SA 3.0',
  'CC0-1.0': 'CC0 1.0',
};

String licenseName(String id) => id == 'public-domain' ? ui.publicDomain : (_licenseNames[id] ?? id);

/// Share of the words in NVdB bands 1–3, rounded down (LEI-13); -1 without band data.
int coveragePercent(List<int> bandWords, int words) {
  if (words <= 0 || bandWords.every((b) => b == 0)) return -1;
  final basic = bandWords.skip(1).fold(0, (a, b) => a + b);
  return basic * 100 ~/ words;
}

/// "Viagem · Trem · Bolonha": genre and every tag, in the Navigation language.
/// An unknown genre is "Outros"; an unknown tag is left out (BIB-11).
String titleMeta(Story s, Lists lists, IndexState state, bool navTarget) {
  final lang = state.nav(navTarget);
  final g = lists.genre(s.genre, lang);
  return [
    g.isEmpty ? nav.otherGenre : g,
    for (final t in s.tags)
      if (lists.tag(t, lang) case final name when name.isNotEmpty) name,
  ].join(' · ');
}

/// What the Reader shows on open (BIB-12): the text, or a wait while the files
/// of the chosen languages are still arriving after a switch.
enum ReaderOpening { text, waitNative, waitStory }

/// `targetFile`/`nativeFile`: whether the story has a file in that language on
/// the device. Fed from the index once it records files (ARQ-23).
ReaderOpening readerOpening(IndexState state, {required bool targetFile, required bool nativeFile}) {
  if (!state.resync) return ReaderOpening.text;
  if (!targetFile) return ReaderOpening.waitStory;
  if (!nativeFile) return ReaderOpening.waitNative;
  return ReaderOpening.text;
}

/// Level, genre · tags, title, subtitle, then `below` (the colophon or the wait).
class TitlePage extends StatelessWidget {
  const TitlePage({super.key, required this.story, required this.meta, required this.split, required this.below});
  final Story story;
  final String meta;
  final bool split;
  final Widget below;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LevelBadge(story.level.v, name: story.level.name),
            Text(meta, style: T.meta.copyWith(color: t.inkMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(story.title, style: (split ? T.title : T.titleLg).copyWith(color: t.ink), locale: const Locale('it')),
        ),
        const SizedBox(height: 8),
        Text(story.subtitle, style: T.lead.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic), locale: const Locale('it')),
        const SizedBox(height: 20),
        below,
      ],
    );
  }
}

/// Labelled rows, each only when it applies (LEI-13). Labels follow
/// Immersion › Labels and buttons, so they come from `ui`.
class Colophon extends StatelessWidget {
  const Colophon({super.key, required this.story, required this.lists});
  final Story story;
  final Lists lists;

  @override
  Widget build(BuildContext context) {
    final s = story;
    final author = lists.author(s.author);
    final credit = [if (author.isNotEmpty) author, if (s.adapted) ui.adapted].join(' · ');
    final cover = coveragePercent(s.bandWords, s.words);
    final rows = <(String, String, String)>[
      if (s.license != 'LicenseRef-Postilla') (ui.colText, credit, ui.license(licenseName(s.license))),
      (ui.colReading, ui.minutes(s.minutes), ''),
      if (cover >= 0) (ui.colVocabulary, ui.coverage(cover), ui.nvdbSource),
      if (!s.hasNative) (ui.colTranslation, ui.noNativeYet, ui.noNativeWhy),
    ];
    final t = context.tk;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: t.rule))),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (final (i, (label, main, small)) in rows.indexed)
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
                      if (main.isNotEmpty) Text(main, style: T.small.copyWith(color: t.ink)),
                      if (small.isNotEmpty) Text(small, style: T.meta.copyWith(color: t.inkMuted)),
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

/// Wait in place of the colophon and the text (BIB-12). Never claims a time.
class ReaderWait extends StatelessWidget {
  const ReaderWait({super.key, required this.targetHere, this.progress, required this.onReadTargetOnly, required this.onBack});

  /// The target file is on the device: only the translation is missing.
  final bool targetHere;
  final double? progress; // 0..1 of the story's download, when known
  final VoidCallback onReadTargetOnly;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle),
                  child: Center(child: Glyph(Glyphs.download, size: 20, color: t.ink)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(targetHere ? ui.waitNativeTitle : ui.waitStoryTitle, style: T.button.copyWith(color: t.ink)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(targetHere ? ui.waitNativeText : ui.waitStoryText, style: T.small.copyWith(color: t.inkMuted)),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress, minHeight: 4, color: t.ink, backgroundColor: t.rule),
              ),
            ],
            const SizedBox(height: 12),
            if (targetHere) ...[
              Btn(ui.readWithoutTranslation, block: true, onTap: onReadTargetOnly),
              const SizedBox(height: 8),
            ],
            Btn(ui.backToLibrary, kind: BtnKind.ghost, block: true, onTap: onBack),
          ],
        ),
      ),
    );
  }
}

/// A story that fails to open (LEI-16): a local error, never the network.
class ReaderError extends StatelessWidget {
  const ReaderError({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ui.readError, style: T.button.copyWith(color: t.ink), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(ui.readErrorText, style: T.small.copyWith(color: t.inkMuted), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Btn(ui.backToLibrary, kind: BtnKind.secondary, small: true, onTap: onBack),
          ],
        ),
      ),
    );
  }
}

/// Translation button (`.ui-trbtn`): `languages` icon and label, no outline; a
/// ghost pill only on press. As wide as the longer label, so nothing moves when it
/// swaps. Disabled (TRA-10) it stays focusable and carries the hint.
class TranslationButton extends StatelessWidget {
  const TranslationButton({super.key, required this.hiding, required this.enabled, required this.onTap});
  final bool hiding;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final fg = enabled ? t.ink : t.inkFaint;
    final style = T.smallMedium.copyWith(color: fg);
    final label = hiding ? ui.hideTranslation : ui.showTranslation;
    final other = hiding ? ui.showTranslation : ui.hideTranslation;
    final body = Pressable(
      onTap: enabled ? onTap : null,
      button: false,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Glyph(Glyphs.languages, size: 20, color: fg),
              const SizedBox(width: 8),
              Stack(
                children: [
                  Opacity(opacity: 0, child: Text(other, style: style)),
                  Text(label, style: style),
                ],
              ),
            ],
          ),
        ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      focusable: true,
      label: label,
      hint: enabled ? null : ui.noTranslationHint,
      excludeSemantics: true,
      // Disabled, it stays focusable so the hint can be reached (TRA-10).
      child: enabled ? body : Focus(child: body),
    );
  }
}
