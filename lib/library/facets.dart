// Library filter logic (BIB-05, BIB-06, BIB-11, BIB-14), with no widgets: the
// story index the facets read, the match rule, the counts and the frozen order.
import '../db/db.dart';

/// The three facets, in their fixed order (BIB-05).
enum Facet { level, genre, tag }

/// Genre value that collects the stories whose genre the cached list lacks (BIB-11).
const otherGenre = '\u0000outros';

/// What the learner filters by: the search text and the checked values per facet.
/// A value is the level number as text, the genre id or the tag id.
class LibQuery {
  LibQuery({this.text = '', Map<Facet, Set<String>>? sel})
      : sel = sel ?? {for (final f in Facet.values) f: <String>{}};
  String text;
  final Map<Facet, Set<String>> sel;

  bool get filtered => sel.values.any((s) => s.isNotEmpty);
  bool get searching => text.trim().isNotEmpty;
  void clearFilters() {
    for (final s in sel.values) {
      s.clear();
    }
  }

  LibQuery copy({String? text, bool keepSel = true}) => LibQuery(
        text: text ?? this.text,
        sel: {for (final f in Facet.values) f: keepSel ? {...sel[f]!} : <String>{}},
      );
}

/// Frozen order of a facet's values when its sheet opens (BIB-14).
class FacetOrder {
  const FacetOrder({required this.counts, required this.top, required this.rest, required this.zero});
  final Map<String, int> counts; // stories if the value were checked
  final List<String> top; // checked
  final List<String> rest; // unchecked with stories
  final List<String> zero; // unchecked that would give zero: disabled, collapsed
  List<String> get all => [...top, ...rest, ...zero];
}

/// The Library's stories with what the filters need, computed once per load.
/// Names follow Immersion › Navigation (`lang`); `otherName` is "Outros".
class LibIndex {
  LibIndex(this.stories, this.lists, this.lang, this.otherName) {
    for (final s in stories) {
      final g = lists.genre(s.genre, lang).isEmpty ? otherGenre : s.genre.v;
      final tags = [for (final t in s.tags) if (lists.tag(t, lang).isNotEmpty) t.v];
      _values.add({
        Facet.level: ['${s.level.v}'],
        Facet.genre: [g],
        Facet.tag: tags,
      });
      _hay.add(normalize([
        s.title,
        s.subtitle,
        label(Facet.genre, g),
        for (final t in tags) label(Facet.tag, t),
        lists.author(s.author),
      ].join(' ')));
    }
    for (final f in Facet.values) {
      final total = <String, int>{};
      for (final v in _values) {
        for (final x in v[f]!) {
          total[x] = (total[x] ?? 0) + 1;
        }
      }
      _total[f] = total;
    }
  }

  final List<Story> stories; // BIB-04 order
  final Lists lists;
  final LangId lang;
  final String otherName;
  final _values = <Map<Facet, List<String>>>[];
  final _hay = <String>[];
  final _total = <Facet, Map<String, int>>{};

  /// Values at least one story on the device has (BIB-05). Level in A1 → C2 order.
  List<String> present(Facet f) {
    final vs = _total[f]!.keys.toList();
    if (f == Facet.level) vs.sort((a, b) => int.parse(a) - int.parse(b));
    return vs;
  }

  /// Stories on the device with the value.
  int total(Facet f, String v) => _total[f]![v] ?? 0;

  String label(Facet f, String v) => switch (f) {
        Facet.level => Level(int.tryParse(v) ?? 0).name,
        Facet.genre => v == otherGenre ? otherName : lists.genre(GenreId(v), lang),
        Facet.tag => lists.tag(TagId(v), lang),
      };

  bool _matches(int i, LibQuery q, Facet? skip) {
    final text = normalize(q.text.trim());
    if (text.isNotEmpty && !_hay[i].contains(text)) return false;
    for (final f in Facet.values) {
      if (f == skip) continue;
      final sel = q.sel[f]!;
      if (sel.isNotEmpty && !_values[i][f]!.any(sel.contains)) return false;
    }
    return true;
  }

  /// "Or" within a facet, "and" across facets, search on top (BIB-05, BIB-06).
  List<Story> filter(LibQuery q) => [
        for (var i = 0; i < stories.length; i++)
          if (_matches(i, q, null)) stories[i],
      ];

  /// Stories that would remain with `v` checked: the other facets and the search
  /// apply, the facet's own selection doesn't (BIB-14).
  int count(LibQuery q, Facet f, String v) {
    var n = 0;
    for (var i = 0; i < stories.length; i++) {
      if (_values[i][f]!.contains(v) && _matches(i, q, f)) n++;
    }
    return n;
  }

  /// Order computed when a sheet opens (BIB-14): checked on top, then most stories,
  /// ties by name, "Outros" last; zero values apart, by name. Level is fixed.
  FacetOrder order(LibQuery q, Facet f) {
    final sel = q.sel[f]!;
    final on = present(f);
    // A checked value is never hidden, even one a sync left with no story.
    final vs = [...on, for (final v in sel) if (!on.contains(v)) v];
    final counts = {for (final v in vs) v: count(q, f, v)};
    final checked = [for (final v in vs) if (sel.contains(v)) v];
    final rest = [for (final v in vs) if (!sel.contains(v) && counts[v]! > 0) v];
    final zero = [for (final v in vs) if (!sel.contains(v) && counts[v] == 0) v];
    if (f == Facet.level) {
      // Fixed A1 → C2: checked values stay in place, so `top` stays empty.
      return FacetOrder(counts: counts, top: const [], rest: [for (final v in vs) if (sel.contains(v) || counts[v]! > 0) v], zero: zero);
    }
    int otherLast(String a, String b) => (a == otherGenre ? 1 : 0) - (b == otherGenre ? 1 : 0);
    int byName(String a, String b) => normalize(label(f, a)).compareTo(normalize(label(f, b)));
    int byCount(String a, String b) {
      final o = otherLast(a, b);
      if (o != 0) return o;
      final c = counts[b]! - counts[a]!;
      return c != 0 ? c : byName(a, b);
    }

    checked.sort(byCount);
    rest.sort(byCount);
    zero.sort((a, b) {
      final o = otherLast(a, b);
      return o != 0 ? o : byName(a, b);
    });
    return FacetOrder(counts: counts, top: checked, rest: rest, zero: zero);
  }

  /// Values of the sheet search: the name contains the text, accent- and case-free.
  List<String> find(FacetOrder order, Facet f, String text) {
    final q = normalize(text.trim());
    return [for (final v in order.all) if (normalize(label(f, v)).contains(q)) v];
  }

  /// Facets (other than `f`) whose selection the sheet's counts apply (BIB-14).
  List<Facet> noteFacets(LibQuery q, Facet f) => [for (final x in Facet.values) if (x != f && q.sel[x]!.isNotEmpty) x];
}

/// Where the search text sits in a name, in UTF-16 units of `name`, or null.
/// Matching ignores accents and case, as the search does.
(int, int)? matchRange(String name, String text) {
  final q = normalize(text.trim());
  if (q.isEmpty) return null;
  // normalize() maps each code point to one, so code-point positions line up.
  final runes = name.runes.toList();
  final folded = String.fromCharCodes(normalize(name).runes);
  final at = folded.indexOf(q);
  if (at < 0) return null;
  final cps = folded.substring(0, at).runes.length;
  final cpe = cps + q.runes.length;
  int units(int cp) => String.fromCharCodes(runes.take(cp)).length;
  return (units(cps), units(cpe));
}
