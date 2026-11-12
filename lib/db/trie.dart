// "Did you mean" (ARQ-66): trie of normalized lemmas, walked with the
// rows of the OSA distance (Levenshtein where swapping two adjacent letters
// counts as 1 edit) and pruned above the limit. Each node keeps the previous row and
// the one before it, which transposition needs.
import 'dart:math';

class TrieHit {
  const TrieHit(this.word, this.distance, this.rank);
  final String word;
  final int distance;
  final int rank; // NVdB band, 9 = outside
}

/// Nodes in parallel arrays: children by code unit, word and rank on the final node.
class Trie {
  final List<Map<int, int>> _children = [{}];
  final List<String?> _word = [null];
  final List<int> _rank = [9];
  final List<int> _char = [0];

  void insert(String word, int rank) {
    var node = 0;
    for (final c in word.runes) {
      var next = _children[node][c];
      if (next == null) {
        next = _children.length;
        _children.add({});
        _word.add(null);
        _rank.add(9);
        _char.add(c);
        _children[node][c] = next;
      }
      node = next;
    }
    _word[node] = word;
    _rank[node] = min(_rank[node], rank);
  }

  /// Words within `maxDist` edits of `query`, by distance then rank.
  List<TrieHit> search(String query, int maxDist) {
    final q = query.runes.toList();
    final first = List<int>.generate(q.length + 1, (i) => i);
    final hits = <TrieHit>[];
    for (final MapEntry(key: c, value: child) in _children[0].entries) {
      _walk(child, c, 0, q, first, null, maxDist, hits);
    }
    hits.sort((a, b) {
      final d = a.distance.compareTo(b.distance);
      if (d != 0) return d;
      final r = a.rank.compareTo(b.rank);
      return r != 0 ? r : a.word.compareTo(b.word);
    });
    return hits;
  }

  void _walk(int node, int c, int prevChar, List<int> q, List<int> prev, List<int>? prev2, int maxDist, List<TrieHit> hits) {
    final row = List<int>.filled(q.length + 1, 0);
    row[0] = prev[0] + 1;
    var best = row[0];
    for (var i = 1; i <= q.length; i++) {
      final cost = q[i - 1] == c ? 0 : 1;
      var v = min(min(row[i - 1] + 1, prev[i] + 1), prev[i - 1] + cost);
      if (prev2 != null && i > 1 && q[i - 1] == prevChar && q[i - 2] == c) {
        v = min(v, prev2[i - 2] + 1);
      }
      row[i] = v;
      if (v < best) best = v;
    }
    final w = _word[node];
    if (w != null && row[q.length] <= maxDist) hits.add(TrieHit(w, row[q.length], _rank[node]));
    if (best > maxDist) return;
    for (final MapEntry(key: nc, value: child) in _children[node].entries) {
      _walk(child, nc, c, q, row, prev, maxDist, hits);
    }
  }
}

/// OSA distance between two words (the same as the search).
int osa(String a, String b) {
  final s = a.runes.toList();
  final t = b.runes.toList();
  final d = List.generate(s.length + 1, (_) => List<int>.filled(t.length + 1, 0));
  for (var i = 0; i <= s.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= t.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= s.length; i++) {
    for (var j = 1; j <= t.length; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      var v = min(min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + cost);
      if (i > 1 && j > 1 && s[i - 1] == t[j - 2] && s[i - 2] == t[j - 1]) v = min(v, d[i - 2][j - 2] + 1);
      d[i][j] = v;
    }
  }
  return d[s.length][t.length];
}
