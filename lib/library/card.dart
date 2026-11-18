// Story card (BIB-01): one row of the Library list.
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../settings/settings.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// The card's kicker (BIB-01): the genre and at most the first two tags in
/// their stored order (by id); `more` counts the tags left out. Names are in `lang` (Immersion ›
/// Navigation). An unknown genre shows as `other` and an unknown tag is hidden
/// (BIB-11), so it neither shows nor counts in `more`. Never cuts a name.
({String text, int more}) cardKicker(Story s, Lists lists, LangId lang, String other) {
  final genre = lists.genre(s.genre, lang);
  final tags = [
    for (final t in s.tags)
      if (lists.tag(t, lang).isNotEmpty) lists.tag(t, lang),
  ];
  return (text: [genre.isEmpty ? other : genre, ...tags.take(2)].join(' · '), more: tags.length > 2 ? tags.length - 2 : 0);
}

/// Narration length as minutes and seconds ("4:12").
String clock(int ms) => '${ms ~/ 60000}:${(ms ~/ 1000 % 60).toString().padLeft(2, '0')}';

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.lists,
    required this.state,
    required this.onTap,
    this.first = false,
  });
  final Story story;
  final Lists lists;
  final IndexState state;
  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final s = watchSettings(context);
    final kick = cardKicker(story, lists, state.nav(s.navIt), nav.otherGenre);
    final author = lists.author(story.author);
    final meta = T.meta.copyWith(color: t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]);
    // The pressed background bleeds 12 px past the text; the hairline is inset 12 px.
    return Column(
      children: [
        if (!first) Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: t.rule),
        Pressable(
          onTap: onTap,
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: kick.more > 0 ? '${kick.text}, ${ui.moreTags(kick.more)}' : kick.text,
                  child: ExcludeSemantics(
                    child: Text(
                      (kick.more > 0 ? '${kick.text} · +${kick.more}' : kick.text).toUpperCase(),
                      style: T.label.copyWith(color: t.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(story.title, style: T.cardTitle.copyWith(color: t.ink), locale: const Locale('it')),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(author, style: T.small.copyWith(color: t.ink, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 2),
                Text(
                  story.subtitle,
                  style: T.small.copyWith(color: t.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  locale: const Locale('it'),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          LevelBadge(story.level.v, name: story.level.name),
                          Text(ui.minutes(story.minutes), style: meta),
                          if (story.audioMs > 0)
                            Semantics(
                              label: ui.narration(story.audioMs),
                              child: ExcludeSemantics(
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Glyph(Glyphs.headphones, size: 16, color: t.inkMuted),
                                  const SizedBox(width: 3),
                                  Text(clock(story.audioMs), style: meta),
                                ]),
                              ),
                            ),
                          if (!story.hasNative)
                            Container(
                              constraints: const BoxConstraints(minHeight: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: t.ruleStrong),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(ui.noTranslation, style: meta),
                            ),
                        ],
                      ),
                    ),
                    if (story.arrived)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 4),
                        Text(ui.arrivedNow, style: meta.copyWith(color: t.ink)),
                      ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
