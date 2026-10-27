import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';

import 'content.dart';

void main() {
  setUpAll(openTestDbs);

  test('catálogo na ordem do BIB-04', () async {
    final stories = await dbStories();
    expect(stories, isNotEmpty);
    for (var i = 1; i < stories.length; i++) {
      final a = stories[i - 1], b = stories[i];
      expect(a.level.v < b.level.v || (a.level.v == b.level.v && a.words <= b.words), isTrue);
    }
  });

  test('forma → lema: clítico, elisão, maiúscula e plural', () async {
    expect((await dbLemmas('si siede')).first.lemma, 'sedersi');
    expect((await dbLemmas("l'aria")).first.lemma, 'aria');
    expect((await dbLemmas('Il')).map((e) => e.lemma), contains('il'));
    expect((await dbLemmas('serrande')).first.lemma, 'serranda');
    final porta = (await dbLemmas('porta')).map((e) => e.lemma).toSet();
    expect(porta, containsAll(['porta', 'portare']));
    expect(await dbLemmas('Xyzzyq'), isEmpty);
  });

  test('verbete parseado, com conjugação e imperativo', () async {
    final e = await dbEntry(const EntryRef('sedersi', 'verbo'));
    expect(e.word, 'sedersi');
    expect(e.aux, 'essere');
    expect(e.conj.where((c) => c.tense == 5), isNotEmpty);
    expect(e.conj.firstWhere((c) => c.tense == 1 && c.person == 3).forms, contains('si siede'));
    expect((await dbEntry(const EntryRef('nada', 'verbo'))).isNil, isTrue);
  });

  test('busca sem acento, com curinga e "você quis dizer"', () async {
    expect((await dbSearch('citta')).first.ref.lemma, 'città');
    expect((await dbSearch('fin*ino')).map((h) => h.ref.lemma), contains('finestrino'));
    final casa = await dbSearch('casa');
    expect(casa.first.ref.lemma, 'casa');
    expect(casa.first.exact, isTrue);
    expect((await dbDidYouMean('finsetrino')).map((r) => r.lemma), contains('finestrino'));
  });

  test('ajustes gravam e voltam', () async {
    await dbSettingSet('reading.size', 3);
    await dbSettingSet('reading.size', 4);
    expect((await dbSettingsLoad())['reading.size'], 4);
  });
}
