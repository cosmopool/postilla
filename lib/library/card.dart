// Story card (BIB-01): one row of the Library list.
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../strings.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, required this.genre, required this.onTap, this.first = false});
  final Story story;
  final String genre;
  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
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
                Text(
                  story.title,
                  style: T.cardTitle.copyWith(color: t.ink),
                  locale: const Locale('it'),
                ),
                const SizedBox(height: 4),
                Text(
                  story.subtitle,
                  style: T.small.copyWith(color: t.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  locale: const Locale('it'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    LevelBadge(story.level.v, name: story.level.name),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('$genre · ${ui.minutes(story.minutes)}', style: T.meta.copyWith(color: t.inkMuted)),
                    ),
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
