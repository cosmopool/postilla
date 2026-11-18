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

  test('index: the fixture fills the header fields, once', () async {
    final stories = await dbStories();
    expect(stories.length, 152);
    expect(stories.map((s) => s.level.v).toSet(), {1, 2, 3, 4, 5, 6});
    // A real story keeps its UUID, so the Reader still finds its paragraphs.
    final treno = stories.firstWhere((s) => s.id.v == 'd0159518-99cc-46f0-bef2-b5b6f6f9a76d');
    expect(treno.title, 'Il treno per Bologna');
    expect(treno.minutes, 2);
    expect(treno.tags.map((t) => t.v), ['emilia-romagna', 'treno']); // by id
    expect(treno.audioMs, 252000);
    expect(treno.bandWords.reduce((a, b) => a + b), treno.words);
    expect(await dbParagraphs(treno.id), isNotEmpty);
    final pinocchio = stories.firstWhere((s) => s.id.v == 'f16c1a4c-fbf8-4434-8c2e-1fc10ccf99a5');
    expect((pinocchio.work, pinocchio.part, pinocchio.adapted, pinocchio.license), ('Pinocchio', 1, true, 'public-domain'));
    expect(pinocchio.arrived, isTrue);
    expect(stories.where((s) => !s.hasNative).length, 3);
    expect(stories.where((s) => s.arrived).length, 3);
    // A non-empty index is never refilled.
    expect(await dbLoadIndexFixture('{}'), isFalse);
  });

  test('index: lists and state', () async {
    final lists = await dbLists();
    expect(lists.genre(const GenreId('viaggio'), const LangId('pt-BR')), 'Viagem');
    expect(lists.genre(const GenreId('viaggio'), const LangId('it')), 'Viaggio');
    expect(lists.tag(const TagId('caffe'), const LangId('it')), 'Caffè');
    expect(lists.genre(const GenreId('sconosciuto'), const LangId('pt-BR')), '');
    expect(lists.author(const AuthorId('carlo-collodi')), 'Carlo Collodi');
    expect(lists.languages.map((l) => (l.id.v, l.target, l.translate)), [('en', false, false), ('it', true, false), ('pt-BR', false, true)]);
    final st = await dbIndexState();
    expect((st.target.v, st.native.v, st.newCount, st.resync, st.unknownFormat), ('it', 'pt-BR', 3, false, false));
  });

  test('index: arrival, new count and language switch', () async {
    final id = (await dbStories()).firstWhere((s) => s.arrived).id;
    expect(await dbArrivalOpened(id), isTrue);
    expect((await dbStories()).firstWhere((s) => s.id == id).arrived, isFalse);
    expect(await dbNewCountReset(), isTrue);
    expect((await dbIndexState()).newCount, 0);

    // A pair with no translations yet: same stories, none with a native one.
    expect(await dbSetLanguages(const LangId('it'), const LangId('en')), isTrue);
    final st = await dbIndexState();
    expect((st.native.v, st.cursor, st.resync), ('en', 0, true));
    final stories = await dbStories();
    expect(stories.length, 152);
    expect(stories.every((s) => !s.hasNative), isTrue);
    await dbSetLanguages(const LangId('it'), const LangId('pt-BR'));
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
