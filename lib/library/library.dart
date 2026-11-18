// Library (BIB-01, BIB-04..14): the status line, the search, the Nível · Gênero ·
// Tema facets and the stories in BIB-04 order. Tapping a card opens the Reader
// at the start. The filter rules live in facets.dart, the widgets in sheet.dart.
import 'package:flutter/foundation.dart' show ValueListenable;
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
import 'facets.dart';
import 'sheet.dart';

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
  LibIndex? _index;
  final _filter = LibQuery();
  final _query = TextEditingController();
  final _scroll = ScrollController();
  bool _scrolled = false;
  int _lastCount = -1;
  bool _countShown = false; // the status line showed the new-stories count (BIB-13)
  ValueListenable<bool>? _visible;

  @override
  void initState() {
    super.initState();
    _load();
    _query.addListener(() {
      if (_filter.text == _query.text) return;
      setState(() => _filter.text = _query.text);
    });
    _scroll.addListener(() {
      final s = _scroll.offset > 48;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
    tabReselected.addListener(_reselected);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Off screen (another tab, or the Reader on top), the Library's tickers stop.
    final v = TickerMode.getNotifier(context);
    if (v != _visible) {
      _visible?.removeListener(_visibilityChanged);
      _visible = v..addListener(_visibilityChanged);
    }
  }

  void _visibilityChanged() {
    if (_visible?.value ?? true) {
      _load();
    } else {
      _left();
    }
  }

  /// Leaving the Library after the line showed the count zeroes it (BIB-13, ARQ-26).
  void _left() {
    if (!_countShown) return;
    _countShown = false;
    dbNewCountReset();
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
    if (!mounted) return;
    setState(() {
      _stories = stories;
      _lists = lists;
      _state = state;
      _index = null;
    });
  }

  @override
  void dispose() {
    _visible?.removeListener(_visibilityChanged);
    tabReselected.removeListener(_reselected);
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The index follows Immersion › Navigation, so it is rebuilt when that changes.
  LibIndex _indexFor(LangId lang) {
    final i = _index;
    if (i != null && i.lang == lang && i.otherName == ui.otherGenre && identical(i.stories, _stories)) return i;
    return _index = LibIndex(_stories, _lists, lang, ui.otherGenre);
  }

  void _clearFilters() => setState(_filter.clearFilters);

  void _open(Story story) {
    _left();
    dbArrivalOpened(story.id);
    openReader(context, story, _stories, _lists, _state);
  }

  Future<void> _openFacet(LibIndex index, Facet f) async {
    await openFacetSheet(context, index: index, query: _filter, facet: f, onChanged: () => setState(() {}));
    if (mounted) setState(() {});
  }

  void _announce(int n, bool filtering) {
    if (filtering && n != _lastCount) {
      _lastCount = n;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? SemanticsService.sendAnnouncement(View.of(context), ui.storiesCount(n), Directionality.of(context)) : null,
      );
    } else if (!filtering) {
      _lastCount = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = watchSettings(context);
    final t = context.tk;
    final index = _indexFor(_state.nav(s.navIt));
    final searching = _filter.searching, filtered = _filter.filtered;
    final filtering = searching || filtered;
    final list = index.filter(_filter);
    _announce(list.length, filtering);
    if (_state.newCount > 0 && !_state.unknownFormat) _countShown = true;

    String gName(GenreId id) {
      final n = _lists.genre(id, index.lang);
      return n.isEmpty ? ui.otherGenre : n;
    }

    final Widget? empty;
    if (list.isNotEmpty || _stories.isEmpty) {
      empty = null;
    } else if (searching && filtered) {
      empty = TwoWayEmpty(
        query: _filter.text.trim(),
        filtered: index.filter(_filter.copy(text: '')).length,
        withQuery: index.filter(_filter.copy(keepSel: false)).length,
        onClearSearch: _query.clear,
        onClearFilters: _clearFilters,
      );
    } else if (searching) {
      empty = EmptyState(
        glyph: Glyphs.search,
        title: ui.noStoryFound,
        text: ui.noStoryForQuery(_filter.text.trim()),
        action: Btn(ui.clearSearch, kind: BtnKind.secondary, small: true, onTap: _query.clear),
      );
    } else {
      // Filters alone reach zero only after a sync removed stories (BIB-08).
      empty = EmptyState(
        glyph: Glyphs.search,
        title: ui.noStoryFound,
        text: ui.noStoryForFilters,
        action: Btn(ui.clearFilters, kind: BtnKind.secondary, small: true, onTap: _clearFilters),
      );
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Semantics(
                    header: true,
                    child: Text(nav.library, style: T.title.copyWith(color: t.ink)),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: StatusLine(state: _state, stories: _stories.length)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: SearchField(controller: _query, hint: ui.searchStories),
                ),
              ),
              SliverToBoxAdapter(child: _facets(index)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  filtering ? ui.results : ui.allStories,
                  count: list.length,
                  // With an empty list the way out is in the empty state, not here (BIB-08).
                  action: filtered && list.isNotEmpty
                      ? Btn(ui.clearFilters, kind: BtnKind.ghost, small: true, onTap: _clearFilters)
                      : null,
                ),
              ),
              if (empty != null)
                SliverToBoxAdapter(child: empty)
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => _card(list[i], gName, i == 0),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The one place the Library builds a card (slice 1 owns StoryCard).
  Widget _card(Story story, String Function(GenreId) gName, bool first) => StoryCard(
        story: story,
        genre: gName(story.genre),
        first: first,
        onTap: () => _open(story),
      );

  /// Checked values in the facet's order; one a sync removed still shows, since it
  /// still filters (BIB-14: a checked value is never hidden).
  List<String> _checkedLabels(LibIndex index, Facet f) {
    final sel = _filter.sel[f]!, present = index.present(f);
    return [
      for (final v in present) if (sel.contains(v)) index.label(f, v),
      for (final v in sel) if (!present.contains(v)) index.label(f, v),
    ];
  }

  Widget _facets(LibIndex index) => Semantics(
        container: true,
        label: ui.filters,
        explicitChildNodes: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in Facet.values)
                FacetButton(
                  name: facetName(f),
                  values: _checkedLabels(index, f),
                  onTap: () => _openFacet(index, f),
                ),
            ],
          ),
        ),
      );
}
