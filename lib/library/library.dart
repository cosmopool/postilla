// Biblioteca (BIB-01, BIB-04..10): catálogo na ordem fixa, busca sem acento,
// filtros por Nível e Gênero ("ou" no grupo, "e" entre grupos). Tocar num
// card abre o Leitor no início.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../db/db.dart';
import '../main.dart' show AppTab, tabReselected;
import '../reader/reader.dart';
import '../settings/settings.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Filtra o catálogo (já na ordem do BIB-04). Função pura, testada à parte.
List<Story> filterStories(
  List<Story> all,
  Map<GenreId, Genre> genres,
  String query,
  Set<int> levels,
  Set<GenreId> genreIds,
  bool genreIt,
) {
  final q = normalize(query.trim());
  return [
    for (final s in all)
      if ((levels.isEmpty || levels.contains(s.level.v)) &&
          (genreIds.isEmpty || genreIds.contains(s.genre)) &&
          (q.isEmpty ||
              normalize(s.title).contains(q) ||
              normalize(s.subtitle).contains(q) ||
              normalize(genreName(genres[s.genre], genreIt)).contains(q)))
        s,
  ];
}

String genreName(Genre? g, bool italian) => g == null ? '' : (italian ? g.it : g.pt);

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Story> _stories = const [];
  Map<GenreId, Genre> _genres = const {};
  List<Genre> _genreOrder = const [];
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final Set<int> _levels = {};
  final Set<GenreId> _genreIds = {};
  bool _scrolled = false;
  int _lastCount = -1;

  @override
  void initState() {
    super.initState();
    _load();
    _query.addListener(() => setState(() {}));
    _scroll.addListener(() {
      final s = _scroll.offset > 48;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
    tabReselected.addListener(_reselected);
  }

  void _reselected() {
    if (tabReselected.value.$1 == AppTab.library && _scroll.hasClients) {
      _scroll.animateTo(0, duration: Motion.of(context, Motion.base), curve: Motion.standard);
    }
  }

  Future<void> _load() async {
    final stories = await dbStories();
    final genres = await dbGenres();
    // Gêneros na ordem em que aparecem no catálogo.
    final order = <Genre>[];
    final byId = {for (final g in genres) g.id: g};
    for (final s in stories) {
      final g = byId[s.genre];
      if (g != null && !order.contains(g)) order.add(g);
    }
    if (!mounted) return;
    setState(() {
      _stories = stories;
      _genres = byId;
      _genreOrder = order;
    });
  }

  @override
  void dispose() {
    tabReselected.removeListener(_reselected);
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    _levels.clear();
    _genreIds.clear();
  });

  @override
  Widget build(BuildContext context) {
    final s = watchSettings(context);
    final t = context.tk;
    final filtering = _query.text.trim().isNotEmpty || _levels.isNotEmpty || _genreIds.isNotEmpty;
    final list = filterStories(_stories, _genres, _query.text, _levels, _genreIds, s.navIt);
    if (filtering && list.length != _lastCount) {
      _lastCount = list.length;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted
            ? SemanticsService.sendAnnouncement(View.of(context), ui.storiesCount(list.length), Directionality.of(context))
            : null,
      );
    } else if (!filtering) {
      _lastCount = -1;
    }

    return Column(
      children: [
        // App bar grande: o título pequeno aparece quando o grande sai da tela.
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _scrolled ? t.rule : t.bg)),
          ),
          child: AnimatedOpacity(
            opacity: _scrolled ? 1 : 0,
            duration: Motion.of(context, Motion.fast),
            child: Text(nav.library, style: T.button.copyWith(color: t.ink)),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Semantics(
                    header: true,
                    child: Text(nav.library, style: T.title.copyWith(color: t.ink)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: SearchField(controller: _query, hint: ui.searchStories),
                ),
              ),
              SliverToBoxAdapter(child: _filters(s.navIt)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  filtering ? ui.results : ui.allStories,
                  count: list.length,
                  action: _levels.isNotEmpty || _genreIds.isNotEmpty
                      ? Btn(ui.clearFilters, kind: BtnKind.ghost, small: true, onTap: _clearFilters)
                      : null,
                ),
              ),
              if (list.isEmpty && _stories.isNotEmpty)
                SliverToBoxAdapter(
                  child: _query.text.trim().isNotEmpty
                      ? EmptyState(
                          glyph: Glyphs.search,
                          title: ui.noStoryFound,
                          text: ui.noStoryForQuery(_query.text.trim()),
                          action: Btn(ui.clearSearch, kind: BtnKind.secondary, small: true, onTap: _query.clear),
                        )
                      : EmptyState(
                          glyph: Glyphs.search,
                          title: ui.noStoryFound,
                          text: ui.noStoryForFilters,
                          action: Btn(ui.clearFilters, kind: BtnKind.secondary, small: true, onTap: _clearFilters),
                        ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => StoryCard(
                      story: list[i],
                      genre: genreName(_genres[list[i].genre], s.navIt),
                      first: i == 0,
                      onTap: () => openReader(context, list[i], _stories, _genres),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filters(bool genreIt) {
    final t = context.tk;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: ui.level,
            container: true,
            child: Row(
              children: [
                for (var l = 1; l <= 4; l++) ...[
                  FilterChipBtn(
                    Level(l).name,
                    selected: _levels.contains(l),
                    onTap: () => setState(() => _levels.contains(l) ? _levels.remove(l) : _levels.add(l)),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Container(width: 1, height: 20, color: t.ruleStrong, margin: const EdgeInsets.only(right: 8)),
          Semantics(
            label: ui.genre,
            container: true,
            child: Row(
              children: [
                for (final g in _genreOrder) ...[
                  FilterChipBtn(
                    genreName(g, genreIt),
                    selected: _genreIds.contains(g.id),
                    onTap: () => setState(() => _genreIds.contains(g.id) ? _genreIds.remove(g.id) : _genreIds.add(g.id)),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, required this.genre, required this.onTap, this.first = false});
  final Story story;
  final String genre;
  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    // O fundo de pressão sangra 12 px além do texto; a hairline fica recuada 12 px.
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
