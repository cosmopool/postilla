import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/trie.dart';

void main() {
  test('osa conta a troca de letras vizinhas como 1 edição', () {
    expect(osa('finsetrino', 'finestrino'), 1);
    expect(osa('finestrinno', 'finestrino'), 1);
    expect(osa('casa', 'casa'), 0);
    expect(osa('ca', 'abc'), 3);
  });

  test('trie acha até 2 edições, por distância e depois faixa', () {
    final t = Trie()
      ..insert('finestrino', 2)
      ..insert('finestra', 1)
      ..insert('fine', 1)
      ..insert('casa', 1);
    final hits = t.search('finsetrino', 2);
    expect(hits.first.word, 'finestrino');
    expect(hits.first.distance, 1);
    expect(hits.map((h) => h.word), isNot(contains('casa')));
    for (final w in ['finestrino', 'finestra', 'fine', 'casa']) {
      for (final h in t.search(w.substring(1), 2)) {
        expect(h.distance, osa(w.substring(1), h.word));
      }
    }
  });
}
