// Library (BIB-01, BIB-04..10): catalog in fixed order, accent-insensitive search,
// filters by Level and Genre ("or" within a group, "and" across groups). Tapping a
// card opens the Reader at the start.
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
import 'card.dart';

/// Filters the catalog (already in BIB-04 order). Pure function, tested separately.
List<Story> filterStories(
  List<Story> all,
  String Function(GenreId) gName,
  String query,
  Set<int> levels,
  Set<GenreId> genreIds,
) {
  final q = normalize(query.trim());
  return [
    for (final s in all)
      if ((levels.isEmpty || levels.contains(s.level.v)) &&
          (genreIds.isEmpty || genreIds.contains(s.genre)) &&
          (q.isEmpty ||
              normalize(s.title).contains(q) ||
              normalize(s.subtitle).contains(q) ||
              normalize(gName(s.genre)).contains(q)))
        s,
  ];
}

/// Genre name in the Navigation language (BIB-06); '' for an unknown id (BIB-11).
String genreName(Lists lists, IndexState st, GenreId id, bool navTarget) => lists.genre(id, st.nav(navTarget));

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Story> _stories = const [];
  Lists _lists = Lists.nil;
  IndexState _state = IndexState.nil;
  List<GenreId> _genreOrder = const [];
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
    final lists = await dbLists();
    final state = await dbIndexState();
    // Genres in the order they appear in the catalog.
    final order = <GenreId>[];
    for (final s in stories) {
      if (!order.contains(s.genre)) order.add(s.genre);
    }
    if (!mounted) return;
    setState(() {
      _stories = stories;
      _lists = lists;
      _state = state;
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
    String gName(GenreId id) => genreName(_lists, _state, id, s.navIt);
    final list = filterStories(_stories, gName, _query.text, _levels, _genreIds);
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
        // Large app bar: the small title shows when the large one leaves the screen.
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
              SliverToBoxAdapter(child: _filters(gName)),
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
                      lists: _lists,
                      state: _state,
                      first: i == 0,
                      onTap: () => openReader(context, list[i], _stories, _lists, _state),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filters(String Function(GenreId) gName) {
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
                    gName(g),
                    selected: _genreIds.contains(g),
                    onTap: () => setState(() => _genreIds.contains(g) ? _genreIds.remove(g) : _genreIds.add(g)),
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
