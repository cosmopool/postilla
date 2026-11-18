// Library filter widgets (BIB-05, BIB-08, BIB-13, BIB-14): the facet button,
// the facet sheet with its checklist, the status line and the two-way empty state.
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'facets.dart';

String facetName(Facet f) => switch (f) {
      Facet.level => ui.level,
      Facet.genre => ui.genre,
      Facet.tag => ui.tagFacet,
    };

(String, String) facetWords(Facet f) => switch (f) {
      Facet.level => (ui.levelOne, ui.levelMany),
      Facet.genre => (ui.genreOne, ui.genreMany),
      Facet.tag => (ui.tagOne, ui.tagMany),
    };

/// A facet with more than this many values gets its own search (BIB-05).
const sheetSearchAbove = 12;

// ---------------------------------------------------------------- facet button

/// Closed facet: its name, the one value checked, or "Tema · 3" (BIB-05).
class FacetButton extends StatelessWidget {
  const FacetButton({super.key, required this.name, required this.values, required this.onTap});
  final String name;
  final List<String> values; // labels of the checked values
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final on = values.isNotEmpty;
    final fg = on ? t.onInk : t.ink;
    final (text, label) = switch (values.length) {
      0 => (name, name),
      1 => (values.first, ui.facetOneLabel(name, values.first)),
      _ => (ui.facetSeveral(name, values.length), ui.facetSeveralLabel(name, values.length)),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 44 tap target
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        selected: on,
        color: on ? t.ink : null,
        hoverColor: on ? Color.lerp(t.ink, t.bg, 0.14) : t.surface,
        pressedColor: on ? Color.lerp(t.ink, t.bg, 0.24) : t.surface2,
        child: ExcludeSemantics(
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? t.ink : t.ruleStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: T.smallMedium.copyWith(color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Glyph(Glyphs.chevronDown, size: 16, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- check row

/// One value in a facet sheet: box, name (search match marked), story count.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.name,
    required this.count,
    required this.total,
    required this.checked,
    required this.disabled,
    required this.onTap,
    this.match,
  });
  final String name;
  final int count;
  final int total; // stories on the device, for "0 de N"
  final bool checked;
  final bool disabled; // would give zero (BIB-14)
  final VoidCallback onTap;
  final (int, int)? match;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final ink = disabled ? t.inkFaint : t.ink;
    final style = T.body.copyWith(color: ink);
    final m = match;
    final nameText = m == null
        ? TextSpan(text: name, style: style)
        : TextSpan(style: style, children: [
            TextSpan(text: name.substring(0, m.$1)),
            TextSpan(
              text: name.substring(m.$1, m.$2),
              style: TextStyle(fontWeight: FontWeight.w600, fontVariations: const [FontVariation('wght', 600)], decoration: TextDecoration.underline, decorationColor: ink),
            ),
            TextSpan(text: name.substring(m.$2)),
          ]);
    return Semantics(
      checked: checked,
      enabled: !disabled,
      label: '$name, ${disabled ? ui.zeroOfLabel(total) : ui.storiesCount(count)}',
      excludeSemantics: true,
      onTap: disabled ? null : onTap,
      child: Pressable(
        onTap: disabled ? null : onTap,
        button: false,
        radius: 14,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Motion.of(context, Motion.fast),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: checked ? t.ink : null,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: checked ? t.ink : (disabled ? t.ruleStrong : t.inkMuted), width: 1.5),
                ),
                child: checked ? Center(child: Glyph(Glyphs.check, size: 16, color: t.onInk)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text.rich(nameText, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(
                disabled ? ui.zeroOf(total) : '$count',
                style: T.meta.copyWith(color: disabled ? t.inkFaint : t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sheet

/// Opens a facet's sheet. Checking applies live: `onChanged` refilters the list
/// behind it. Tapping outside or dragging down closes it, without undoing (BIB-05).
Future<void> openFacetSheet(
  BuildContext context, {
  required LibIndex index,
  required LibQuery query,
  required Facet facet,
  required VoidCallback onChanged,
}) {
  final t = context.tk;
  final tall = facet != Facet.level;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true, // the short sheet stays short, but may grow and scroll on a small screen
    backgroundColor: t.bg,
    barrierColor: t.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => FacetSheet(index: index, query: query, facet: facet, onChanged: onChanged, tall: tall),
  );
}

class FacetSheet extends StatefulWidget {
  const FacetSheet({
    super.key,
    required this.index,
    required this.query,
    required this.facet,
    required this.onChanged,
    this.tall = true,
  });
  final LibIndex index;
  final LibQuery query;
  final Facet facet;
  final VoidCallback onChanged;
  final bool tall;

  @override
  State<FacetSheet> createState() => _FacetSheetState();
}

class _FacetSheetState extends State<FacetSheet> {
  // Frozen while the sheet is open (BIB-14): nothing jumps under the finger.
  late final FacetOrder _order = widget.index.order(widget.query, widget.facet);
  late final int _present = widget.index.present(widget.facet).length;
  final _search = TextEditingController();
  bool _more = false;

  Set<String> get _sel => widget.query.sel[widget.facet]!;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String v) {
    setState(() => _sel.contains(v) ? _sel.remove(v) : _sel.add(v));
    widget.onChanged();
  }

  void _clear() {
    setState(_sel.clear);
    widget.onChanged();
  }

  Widget _row(String v, {String text = ''}) {
    final f = widget.facet;
    final zero = _order.zero.contains(v);
    final name = widget.index.label(f, v);
    return CheckRow(
      name: name,
      count: _order.counts[v] ?? 0,
      total: widget.index.total(f, v),
      checked: _sel.contains(v),
      disabled: zero,
      match: matchRange(name, text),
      onTap: () => _toggle(v),
    );
  }

  Widget _group(String label, int? n) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Row(
        children: [
          Expanded(child: MicroLabel(label, header: true)),
          if (n != null) Text('$n', style: T.label.copyWith(color: t.inkMuted)),
        ],
      ),
    );
  }

  List<Widget> _body() {
    final f = widget.facet;
    final (one, many) = facetWords(f);
    final text = _search.text.trim();
    final t = context.tk;
    if (text.isNotEmpty) {
      final found = widget.index.find(_order, f, text);
      if (found.isEmpty) {
        return [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(liveRegion: true, child: Text(ui.noValueWith(one, text), style: T.meta.copyWith(color: t.inkMuted))),
          ),
        ];
      }
      return [
        _group(ui.foundOf(found.length, _present, many), null),
        for (final v in found) _row(v, text: text),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(ui.accentTip(one), style: T.meta.copyWith(color: t.inkMuted)),
        ),
      ];
    }
    return [
      if (f == Facet.level)
        for (final v in _order.rest) _row(v)
      else if (_order.top.isNotEmpty) ...[
        _group(ui.marked, _order.top.length),
        for (final v in _order.top) _row(v),
        if (_order.rest.isNotEmpty) ...[
          _group(ui.othersOf(many), _order.rest.length),
          for (final v in _order.rest) _row(v),
        ],
      ] else
        for (final v in _order.rest) _row(v),
      if (_order.zero.isNotEmpty) ...[
        _MoreButton(
          text: ui.zeroValues(_order.zero.length, one, many),
          open: _more,
          onTap: () => setState(() => _more = !_more),
        ),
        if (_more)
          for (final v in _order.zero) _row(v),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final f = widget.facet;
    final (one, many) = facetWords(f);
    final total = widget.index.filter(widget.query).length;
    final noteFacets = widget.index.noteFacets(widget.query, f);
    final searching = widget.query.searching;
    final mq = MediaQuery.of(context);
    final note = noteFacets.isEmpty && !searching ? null : _note(noteFacets, searching);
    final head = <Widget>[
      Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          decoration: BoxDecoration(color: t.inkFaint, borderRadius: BorderRadius.circular(2)),
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: facetName(f), style: T.heading.copyWith(color: t.ink)),
                  if (f != Facet.level)
                    TextSpan(text: '  ${ui.countOf(_present, one, many)}', style: T.meta.copyWith(color: t.inkMuted)),
                ]),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: _sel.isNotEmpty,
            label: ui.clearFacet(one),
            excludeSemantics: true,
            onTap: _sel.isEmpty ? null : _clear,
            child: Btn(ui.clear, kind: BtnKind.ghost, small: true, onTap: _sel.isEmpty ? null : _clear),
          ),
        ],
      ),
      if (note != null) Padding(padding: const EdgeInsets.only(top: 4), child: note),
      if (f != Facet.level && _present > sheetSearchAbove)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SearchField(controller: _search, hint: ui.searchAmong(_present, many)),
        ),
      const SizedBox(height: 8),
    ];
    final foot = Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 8 + mq.padding.bottom),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.rule))),
      child: Semantics(
        liveRegion: true,
        child: Btn(ui.seeStories(total), block: true, onTap: () => Navigator.of(context).pop()),
      ),
    );
    final body = _body();
    if (!widget.tall) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height - mq.padding.top - 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...head, ...body]),
              ),
            ),
            const SizedBox(height: 12),
            foot,
          ],
        ),
      );
    }
    return SizedBox(
      height: mq.size.height - mq.padding.top - 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: head),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: body,
            ),
          ),
          foot,
        ],
      ),
    );
  }

  Widget _note(List<Facet> facets, bool search) {
    final t = context.tk;
    final style = T.meta.copyWith(color: t.inkMuted);
    final bold = TextStyle(color: t.ink, fontWeight: FontWeight.w600, fontVariations: const [FontVariation('wght', 600)]);
    // The sentence comes from the strings; the facet names inside it are bold.
    final names = [for (final f in facets) facetName(f)];
    final sentence = ui.sheetNote(names, search);
    final spans = <TextSpan>[];
    var rest = sentence;
    for (final n in names) {
      final at = rest.indexOf(n);
      if (at < 0) continue;
      spans.add(TextSpan(text: rest.substring(0, at)));
      spans.add(TextSpan(text: n, style: bold));
      rest = rest.substring(at + n.length);
    }
    spans.add(TextSpan(text: rest));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.text, required this.open, required this.onTap});
  final String text;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.rule))),
      child: Semantics(
        expanded: open,
        child: Pressable(
          onTap: onTap,
          radius: 0,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(child: Text(text, style: T.small.copyWith(color: t.inkMuted))),
                Glyph(open ? Glyphs.chevronUp : Glyphs.chevronDown, size: 16, color: t.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- status line

/// One line under the large title, the only place where syncing speaks (BIB-13):
/// the unknown-format notice (OFF-26), the new-stories count (OFF-24), or the
/// story count. Announced when it changes; no close button.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.state, required this.stories});
  final IndexState state;
  final int stories;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final style = T.small.copyWith(color: t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]);
    final Widget line;
    if (state.unknownFormat) {
      // v1: no "Atualizar na loja" link; opening a URL needs a platform channel (v1.1, ARQ-73).
      line = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Glyph(Glyphs.circleArrowUp, size: 18, color: t.ink)),
          const SizedBox(width: 8),
          Expanded(child: Text(ui.unknownFormat, style: style.copyWith(color: t.ink))),
        ],
      );
    } else if (state.newCount > 0) {
      line = Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: t.ink, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(TextSpan(style: style, children: [
              TextSpan(
                text: ui.newStories(state.newCount),
                style: TextStyle(color: t.ink, fontWeight: FontWeight.w600, fontVariations: const [FontVariation('wght', 600)]),
              ),
              TextSpan(text: ' ${ui.arrived(state.newCount)}'),
            ])),
          ),
        ],
      );
    } else {
      line = Text(ui.storiesOnDeviceLine(stories), style: style);
    }
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 16), child: line),
    );
  }
}

// ---------------------------------------------------------------- empty with two ways out

/// Search over filters with no result (BIB-08): both ways out, each saying what
/// it brings back.
class TwoWayEmpty extends StatelessWidget {
  const TwoWayEmpty({
    super.key,
    required this.query,
    required this.filtered,
    required this.withQuery,
    required this.onClearSearch,
    required this.onClearFilters,
  });
  final String query;
  final int filtered; // stories with the filters and no search
  final int withQuery; // stories with the search and no filters
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    Widget way(String label, String note, VoidCallback onTap) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                hint: note,
                child: Btn(label, kind: BtnKind.secondary, small: true, block: true, onTap: onTap),
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(
                child: Text(note, style: T.meta.copyWith(color: t.inkMuted), textAlign: TextAlign.center),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Text(ui.noStoryFound, style: T.button.copyWith(color: t.ink), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(ui.noneOfFiltered(filtered, query), style: T.small.copyWith(color: t.inkMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              way(ui.clearSearch, ui.backToFiltered(filtered), onClearSearch),
              const SizedBox(width: 12),
              way(ui.clearFilters, ui.showsWithQuery(withQuery, query), onClearFilters),
            ],
          ),
        ],
      ),
    );
  }
}
