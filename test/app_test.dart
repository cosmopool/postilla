// Integração (ARQ-90): dirige os widgets com os bancos reais do lock e um
// `user` novo por execução.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';
import 'package:postilla/dictionary/dictionary.dart';
import 'package:postilla/library/card.dart';
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
    expect(find.byType(StoryCard), findsWidgets);
    expect(find.text('Todas as histórias'.toUpperCase()), findsOneWidget);

    await t.enterText(find.byType(TextField), 'caffe al banco');
    await settle(t);
    expect(find.text('Un caffè al banco'), findsOneWidget);
    expect(find.text('Il treno per Bologna'), findsNothing);
    expect(find.text('Resultados'.toUpperCase()), findsOneWidget);

    await t.enterText(find.byType(TextField), 'xyzzy');
    await settle(t);
    expect(find.text('Nenhuma história encontrada'), findsOneWidget);
    await t.tap(find.text('Limpar busca').last);
    await settle(t);

    // Nível sheet: B2 filters the list live; "Ver 1 história" closes the sheet.
    await t.tap(find.text('Nível'));
    await settle(t);
    await t.tap(find.text('B2'));
    await settle(t);
    await t.tap(find.textContaining(RegExp(r'^Ver \d+ histór')));
    await settle(t);
    expect(find.byType(StoryCard), findsWidgets);
    expect(find.text('Limpar filtros'), findsOneWidget);
    expect(find.text('B2'), findsWidgets); // the facet summarizes its one value
  });

  testWidgets('Card: kicker com "+N", autor, narração, "Sem tradução" e "Chegou agora"', (t) async {
    await t.pumpWidget(const PostillaApp(home: Shell()));
    await settle(t);
    // Pinocchio (seed fixture): author, narration 8:05, arrived through a sync.
    await t.enterText(find.byType(TextField), 'capitolo primo');
    await settle(t);
    expect(find.text('Carlo Collodi'), findsOneWidget);
    expect(find.text('8:05'), findsOneWidget);
    expect(find.text('Chegou agora'), findsWidgets);
    // Lettera da Trieste: no Portuguese translation (TRA-10).
    await t.enterText(find.byType(TextField), 'lettera da trieste');
    await settle(t);
    expect(find.text('Sem tradução'), findsOneWidget);
    // La nonna e il basilico: genre + 2 of 3 tags, then "+1".
    await t.enterText(find.byType(TextField), 'nonna e il basilico');
    await settle(t);
    expect(find.text('FAMÍLIA · NONNA · COZINHA · +1'), findsOneWidget);
  });

  testWidgets('Leitor: tocar numa palavra abre o verbete do lema, com "Na história"', (t) async {
    t.view.physicalSize = const Size(402 * 3, 874 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const PostillaApp(home: Shell()));
    await settle(t);
    await t.enterText(find.byType(TextField), 'treno per bologna');
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
        id: StoryId(id), title: id, subtitle: '', level: Level(level), genre: const GenreId('g'), work: work, part: part, words: 1);
    final a1a = s('a1a', 1), a1b = s('a1b', 1), a2 = s('a2', 2), b1p1 = s('p1', 3, work: 'P', part: 1), b1x = s('b1x', 3);
    final b2 = s('b2', 4), b1p2 = s('p2', 4, work: 'P', part: 2);
    final cat = [a1a, a1b, a2, b1p1, b1x, b2, b1p2];
    expect(nextStory(a1a, cat).id, a1b.id);
    expect(nextStory(a1b, cat).id, a2.id);
    expect(nextStory(b1p1, cat).id, b1p2.id);
    expect(nextStory(b2, cat).id, b1p2.id);
    expect(nextStory(b1p2, cat).id.v, '');
  });

  test('card kicker: genre + 2 tags in feed order + "+N"; unknown genre "Outros", unknown tag hidden', () {
    const lists = Lists(
      genres: {GenreId('viaggio'): {LangId('pt-BR'): 'Viagem', LangId('it'): 'Viaggio'}},
      tags: {
        TagId('treno'): {LangId('pt-BR'): 'Trem', LangId('it'): 'Treno'},
        TagId('roma'): {LangId('pt-BR'): 'Roma', LangId('it'): 'Roma'},
        TagId('mare'): {LangId('pt-BR'): 'Mar', LangId('it'): 'Mare'},
        TagId('notte'): {LangId('pt-BR'): 'Noite', LangId('it'): 'Notte'},
      },
    );
    Story s(String genre, List<String> tags) => Story(
        id: const StoryId('x'),
        title: '',
        subtitle: '',
        level: const Level(1),
        genre: GenreId(genre),
        tags: [for (final t in tags) TagId(t)],
        words: 1);
    const pt = LangId('pt-BR'), it = LangId('it');
    expect(cardKicker(s('viaggio', []), lists, pt, 'Outros'), (text: 'Viagem', more: 0));
    expect(cardKicker(s('viaggio', ['treno', 'roma']), lists, it, 'Altro'), (text: 'Viaggio · Treno · Roma', more: 0));
    expect(cardKicker(s('viaggio', ['treno', 'roma', 'mare', 'notte']), lists, pt, 'Outros'),
        (text: 'Viagem · Trem · Roma', more: 2));
    expect(cardKicker(s('nuovo', ['ignoto', 'mare']), lists, pt, 'Outros'), (text: 'Outros · Mar', more: 0));
    expect(clock(485000), '8:05');
  });

  test('reading time: words ÷ the level\'s speed, rounded up (A1 60 … C2 160)', () {
    expect(const Level(1).minutes(60), 1);
    expect(const Level(1).minutes(61), 2);
    expect(const Level(2).minutes(149), 2);
    expect(const Level(6).minutes(1600), 10);
    expect(const Level(5).name, 'C1');
    expect(const Level(7).minutes(100), 0);
  });
}
