// Integração (ARQ-90): dirige os widgets com os bancos reais do lock e um
// `user` novo por execução.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';
import 'package:postilla/dictionary/dictionary.dart';
import 'package:postilla/library/library.dart';
import 'package:postilla/main.dart';
import 'package:postilla/reader/paragraph.dart';
import 'package:postilla/reader/reader.dart';
import 'package:postilla/settings/settings.dart';

import 'content.dart';

/// Espera o isolate do banco responder entre os quadros.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
  }
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await openTestDbs();
    await loadSettings();
  });

  testWidgets('Biblioteca: catálogo, busca sem acento e filtro de nível', (t) async {
    await t.pumpWidget(const PostillaApp(home: Shell()));
    await settle(t);
    expect(find.text('Il treno per Bologna'), findsOneWidget);
    expect(find.text('Todas as histórias'.toUpperCase()), findsOneWidget);

    await t.enterText(find.byType(TextField), 'caffe');
    await settle(t);
    expect(find.text('Un caffè al banco'), findsOneWidget);
    expect(find.text('Il treno per Bologna'), findsNothing);
    expect(find.text('Resultados'.toUpperCase()), findsOneWidget);

    await t.enterText(find.byType(TextField), 'venezia');
    await settle(t);
    expect(find.text('Nenhuma história encontrada'), findsOneWidget);
    await t.tap(find.text('Limpar busca').last);
    await settle(t);

    await t.tap(find.text('B2'));
    await settle(t);
    expect(find.byType(StoryCard), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });

  testWidgets('Leitor: tocar numa palavra abre o verbete do lema, com "Na história"', (t) async {
    t.view.physicalSize = const Size(402 * 3, 874 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const PostillaApp(home: Shell()));
    await settle(t);
    await t.tap(find.text('Il treno per Bologna'));
    await settle(t);
    expect(find.byType(ReaderPage), findsOneWidget);

    // Toca no centro da palavra "serrande" (parágrafo 2) pelo RenderBox.
    final para = find.byType(ParagraphText).at(1);
    await t.ensureVisible(para);
    await t.pumpAndSettle();
    final box = t.renderObject<RenderParagraphBox>(para);
    final words = (await t.runAsync(() async {
      final stories = await dbStories();
      return dbParagraphs(stories.firstWhere((s) => s.title == 'Il treno per Bologna').id);
    }))!;
    final i = words[1].words.indexWhere((w) => words[1].it.substring(w.start, w.end) == 'serrande');
    final center = box.wordRect(i).center;
    await t.tapAt(t.getTopLeft(para) + center);
    await settle(t);

    expect(find.byType(EntryPage), findsOneWidget);
    expect(find.text('serranda'), findsWidgets);
    expect(find.text('Na história'.toUpperCase()), findsOneWidget);
  });

  test('próxima história: obra, mesmo nível, nível seguinte', () {
    Story s(String id, int level, {String work = '', int part = 0}) => Story(
        id: StoryId(id), title: id, subtitle: '', level: Level(level), genre: const GenreId('g'), work: work, part: part, words: 1, minutes: 1);
    final a1a = s('a1a', 1), a1b = s('a1b', 1), a2 = s('a2', 2), b1p1 = s('p1', 3, work: 'P', part: 1), b1x = s('b1x', 3);
    final b2 = s('b2', 4), b1p2 = s('p2', 4, work: 'P', part: 2);
    final cat = [a1a, a1b, a2, b1p1, b1x, b2, b1p2];
    expect(nextStory(a1a, cat).id, a1b.id);
    expect(nextStory(a1b, cat).id, a2.id);
    expect(nextStory(b1p1, cat).id, b1p2.id);
    expect(nextStory(b2, cat).id, b1p2.id);
    expect(nextStory(b1p2, cat).id.v, '');
  });

  test('filtro: "ou" no grupo, "e" entre grupos, busca no gênero', () {
    Story s(String id, int level, String genre) =>
        Story(id: StoryId(id), title: id, subtitle: '', level: Level(level), genre: GenreId(genre), work: '', part: 0, words: 1, minutes: 1);
    final genres = {const GenreId('v'): const Genre(GenreId('v'), 'Viagem', 'Viaggio'), const GenreId('f'): const Genre(GenreId('f'), 'Família', 'Famiglia')};
    final all = [s('a', 1, 'v'), s('b', 2, 'f'), s('c', 2, 'v')];
    expect(filterStories(all, genres, '', {1, 2}, {}, false).length, 3);
    expect(filterStories(all, genres, '', {2}, {const GenreId('v')}, false).map((x) => x.id.v), ['c']);
    expect(filterStories(all, genres, 'familia', {}, {}, false).map((x) => x.id.v), ['b']);
    expect(filterStories(all, genres, 'viaggio', {}, {}, true).length, 2);
  });
}
