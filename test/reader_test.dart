// Reader title page, colophon, wait, local error and choice page (LEI-02,
// LEI-13, LEI-16, TRA-10, BIB-12), with the real databases of the lock.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';
import 'package:postilla/dictionary/dictionary.dart';
import 'package:postilla/main.dart';
import 'package:postilla/reader/paragraph.dart';
import 'package:postilla/reader/reader.dart';
import 'package:postilla/reader/titlepage.dart';
import 'package:postilla/settings/settings.dart';
import 'package:postilla/strings.dart';

import 'content.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
  }
  await t.pumpAndSettle();
}

const lists = Lists(
  genres: {
    GenreId('viaggio'): {LangId('pt-BR'): 'Viagem', LangId('it'): 'Viaggio'},
  },
  tags: {
    TagId('treno'): {LangId('pt-BR'): 'Trem', LangId('it'): 'Treno'},
  },
  authors: {AuthorId('collodi'): 'Carlo Collodi'},
);

/// The real "Il treno per Bologna" with the header fields the fixture would carry.
Future<Story> treno(WidgetTester t, {bool hasNative = true, String license = 'CC-BY-SA-4.0'}) async {
  final all = (await t.runAsync(dbStories))!;
  final s = all.firstWhere((s) => s.title == 'Il treno per Bologna');
  return Story(
    id: s.id,
    title: s.title,
    subtitle: s.subtitle,
    level: s.level,
    genre: s.genre,
    tags: const [TagId('treno'), TagId('sconosciuto')],
    author: const AuthorId('collodi'),
    adapted: true,
    license: license,
    words: 149,
    bandWords: const [12, 100, 25, 12],
    hasNative: hasNative,
  );
}

Future<void> openPage(WidgetTester t, Story story, {IndexState state = IndexState.nil, bool targetFile = true, bool nativeFile = true}) async {
  t.view.physicalSize = const Size(402 * 3, 874 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(PostillaApp(
    home: ReaderPage(story: story, catalog: [story], lists: lists, state: state, targetFile: targetFile, nativeFile: nativeFile),
  ));
  // The database isolate answers in real time, which a loaded machine stretches:
  // wait for an outcome (text, local error or wait) instead of a fixed time.
  bool done() =>
      find.byType(ParagraphText).evaluate().isNotEmpty ||
      find.textContaining('Não foi possível').evaluate().isNotEmpty ||
      find.textContaining('ainda está chegando').evaluate().isNotEmpty;
  for (var i = 0; i < 100 && !done(); i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await t.pump(const Duration(milliseconds: 50));
  }
  await settle(t);
}

void main() {
  setUpAll(() async {
    await openTestDbs();
    await loadSettings();
  });

  test('coverage: bands 1–3 over all words, rounded down; nothing without band data', () {
    expect(coveragePercent(const [12, 100, 25, 12], 149), 91);
    expect(coveragePercent(const [0, 0, 0, 0], 149), -1);
    expect(coveragePercent(const [1, 1, 0, 0], 0), -1);
  });

  test('license names: SPDX table, public domain, unknown as is', () {
    expect(licenseName('CC-BY-SA-4.0'), 'CC BY-SA 4.0');
    expect(licenseName('public-domain'), 'Domínio público');
    expect(licenseName('MIT'), 'MIT');
  });

  test('title meta: unknown genre is "Outros", unknown tag is left out (BIB-11)', () {
    const s = Story(
      id: StoryId('x'),
      title: '',
      subtitle: '',
      level: Level(1),
      genre: GenreId('nuovo'),
      tags: [TagId('treno'), TagId('sconosciuto')],
      words: 1,
    );
    expect(titleMeta(s, lists, IndexState.nil, false), 'Outros · Trem');
    expect(titleMeta(s, lists, IndexState.nil, true), 'Outros · Treno');
  });

  test('opening: text unless a resync is still bringing the files (BIB-12)', () {
    const on = IndexState(resync: true);
    expect(readerOpening(IndexState.nil, targetFile: false, nativeFile: false), ReaderOpening.text);
    expect(readerOpening(on, targetFile: true, nativeFile: true), ReaderOpening.text);
    expect(readerOpening(on, targetFile: true, nativeFile: false), ReaderOpening.waitNative);
    expect(readerOpening(on, targetFile: false, nativeFile: false), ReaderOpening.waitStory);
  });

  test('choice page count reads as words', () {
    expect(ui.formLeadsTo(2), 'Esta forma leva a duas palavras.');
    expect(ui.formLeadsTo(3), 'Esta forma leva a três palavras.');
    expect(ui.formLeadsTo(12), 'Esta forma leva a 12 palavras.');
  });

  testWidgets('title page: meta, colophon rows, then the text (LEI-13)', (t) async {
    await openPage(t, await treno(t));
    expect(find.text('Viagem · Trem'), findsOneWidget);
    expect(find.text('TEXTO'), findsOneWidget);
    expect(find.text('Carlo Collodi · adaptado'), findsOneWidget);
    expect(find.text('Licença CC BY-SA 4.0'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('91% das palavras são do vocabulário básico'), findsOneWidget);
    expect(find.text('Nuovo vocabolario di base, De Mauro (NVdB)'), findsOneWidget);
    expect(find.text('TRADUÇÃO'), findsNothing);
    expect(find.byType(ParagraphText), findsWidgets);
    await t.tap(find.text('Mostrar tradução'));
    await settle(t);
    expect(find.text(ui.portuguese.toUpperCase()), findsOneWidget);
  });

  testWidgets('a story written for Postilla has no "Texto" row', (t) async {
    await openPage(t, await treno(t, license: 'LicenseRef-Postilla'));
    expect(find.text('TEXTO'), findsNothing);
    expect(find.text('LEITURA'), findsOneWidget);
  });

  testWidgets('no native translation: colophon row and a disabled button (TRA-10)', (t) async {
    await openPage(t, await treno(t, hasNative: false));
    expect(find.text('Ainda não existe em português'), findsOneWidget);
    await t.tap(find.text('Mostrar tradução'));
    await settle(t);
    expect(find.text(ui.portuguese.toUpperCase()), findsNothing);
    expect(find.bySemanticsLabel('Mostrar tradução'), findsOneWidget);
  });

  testWidgets('a story with no text shows the local error (LEI-16)', (t) async {
    const ghost = Story(id: StoryId('00000000-0000-0000-0000-000000000000'), title: 'Fantasma', subtitle: '', level: Level(1), genre: GenreId('viaggio'), words: 10);
    await openPage(t, ghost);
    expect(find.text('Não foi possível abrir esta história'), findsOneWidget);
    expect(find.text('Escolha outra na biblioteca.'), findsOneWidget);
    expect(find.text('Voltar à biblioteca'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.text('Mostrar tradução'), findsNothing);
  });

  testWidgets('wait with the target here: "Ler sem tradução" opens target-only (BIB-12)', (t) async {
    await openPage(t, await treno(t), state: const IndexState(resync: true), nativeFile: false);
    expect(find.text('O português ainda está chegando'), findsOneWidget);
    expect(find.byType(ParagraphText), findsNothing);
    expect(find.text('Viagem · Trem'), findsOneWidget);
    await t.tap(find.text('Ler sem tradução'));
    await settle(t);
    expect(find.byType(ParagraphText), findsWidgets);
    await t.tap(find.text('Mostrar tradução'));
    await settle(t);
    expect(find.text(ui.portuguese.toUpperCase()), findsNothing);
  });

  testWidgets('wait with the target missing: story-level copy, only "Voltar à biblioteca"', (t) async {
    await openPage(t, await treno(t), state: const IndexState(resync: true), targetFile: false, nativeFile: false);
    expect(find.text('Esta história ainda está chegando'), findsOneWidget);
    expect(find.text('Você trocou de idioma. Quando os arquivos terminarem de baixar, ela abre sozinha.'), findsOneWidget);
    expect(find.text('Ler sem tradução'), findsNothing);
    expect(find.text('Voltar à biblioteca'), findsOneWidget);
  });

  testWidgets('choice page from a story: form, count, one row per lemma and class (LEI-02)', (t) async {
    const story = StoryContext(title: 'T', paragraph: 0, sentence: 'parte', hlStart: 0, hlEnd: 5, form: 'parte');
    await t.pumpWidget(const PostillaApp(
      home: ChoicePage(
        refs: [EntryRef('partire', 'verbo', 'verbo intransitivo'), EntryRef('parte', 'sostantivo', 'sostantivo femminile')],
        backLabel: 'Voltar à história',
        story: story,
      ),
    ));
    await settle(t);
    expect(find.text('Dicionário'), findsOneWidget);
    expect(find.text('Esta forma leva a duas palavras.'), findsOneWidget);
    expect(find.text('partire'), findsOneWidget);
    expect(find.text('verbo intransitivo'), findsOneWidget);
    expect(find.text('sostantivo femminile'), findsOneWidget);
  });
}
