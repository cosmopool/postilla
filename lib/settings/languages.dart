// Settings › Idiomas (AJU-08): the target and native language, picked from the
// cached language list (ARQ-27). A switch stores the new pair and resyncs from
// cursor 0 (ARQ-22); the files of the language left behind stay on the device.
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Target choices: learnable languages. The stored target stays offered even if
/// the backend stopped offering it (a stored choice never becomes invalid).
List<Language> targetChoices(List<Language> all, LangId current) => [
      for (final l in all)
        if (l.target || l.id == current) l,
    ];

/// Native choices: every language stories are translated into, minus the
/// target. One the app has no interface strings for still counts: Immersion's
/// native side falls back to Portuguese (AJU-08, §11 #32).
List<Language> nativeChoices(List<Language> all, LangId target) => [
      for (final l in all)
        if (l.translate && l.id != target) l,
    ];

/// The language's own name; the id when the cache lacks it.
String languageName(List<Language> all, LangId id) {
  for (final l in all) {
    if (l.id == id) return l.name;
  }
  return id.v;
}

/// The pair after picking `target`: the native stays unless it is no longer a
/// choice, then it becomes the first native choice.
(LangId, LangId) pairAfterTarget(List<Language> all, LangId target, LangId native) {
  final natives = nativeChoices(all, target);
  if (natives.isEmpty || natives.any((l) => l.id == native)) return (target, native);
  return (target, natives.first.id);
}

/// Picker page: one row per language, the chosen one checked. One tap picks
/// and goes back.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, required this.title, required this.choices, required this.selected});
  final String title;
  final List<Language> choices;
  final LangId selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return ColoredBox(
      color: t.bg,
      child: Column(
        children: [
          CompactBar(backLabel: ui.backToSettings, title: title),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                for (final l in choices)
                  Semantics(
                    selected: l.id == selected,
                    inMutuallyExclusiveGroup: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                      child: Pressable(
                        radius: 14,
                        onTap: () => Navigator.of(context).pop(l.id),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(child: Text(l.name, style: T.body.copyWith(color: t.ink))),
                              if (l.id == selected) Glyph(Glyphs.check, size: 20, color: t.ink),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
