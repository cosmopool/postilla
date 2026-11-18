// Library filters (BIB-05, BIB-06, BIB-08, BIB-11, BIB-14): the pure rules in
// facets.dart and the facet sheet, with in-memory stories (no database).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';
import 'package:postilla/library/facets.dart';
import 'package:postilla/library/sheet.dart';
import 'package:postilla/strings.dart';
import 'package:postilla/ui/theme.dart';

const pt = LangId('pt-BR');
const it = LangId('it');

Story story(String id, int level, String genre, List<String> tags, {String author = ''}) => Story(
      id: StoryId(id),
      title: 'Titolo $id',
      subtitle: '',
      level: Level(level),
      genre: GenreId(genre),
      tags: [for (final t in tags) TagId(t)],
      author: AuthorId(author),
      words: 100,
    );

Map<LangId, String> names(String p, String i) => {pt: p, it: i};

final lists = Lists(
  genres: {GenreId('v'): names('Viagem', 'Viaggio'), GenreId('f'): names('Família', 'Famiglia')},
  tags: {
    TagId('trem'): names('Trem', 'Treno'),
    TagId('roma'): names('Roma', 'Roma'),
    TagId('nonna'): names('Nonna', 'Nonna'),
    TagId('mar'): names('Mar', 'Mare'),
    TagId('sic'): names('Sicília', 'Sicilia'),
  },
  authors: {AuthorId('collodi'): 'Carlo Collodi'},
);

final stories = [
  story('a', 1, 'v', ['trem', 'roma'], author: 'collodi'),
  story('e', 1, 'f', []),
  story('b', 2, 'f', ['nonna']),
  story('c', 2, 'v', ['trem', 'nonna', 'mar']),
  story('d', 3, 'x', ['ghost', 'mar', 'sic']), // unknown genre and tag (BIB-11)
];

LibIndex index([LangId lang = pt]) => LibIndex(stories, lists, lang, 'Outros');

List<String> ids(List<Story> l) => [for (final s in l) s.id.v];

LibQuery q({String text = '', Set<String> level = const {}, Set<String> genre = const {}, Set<String> tag = const {}}) =>
    LibQuery(text: text, sel: {Facet.level: {...level}, Facet.genre: {...genre}, Facet.tag: {...tag}});

void main() {
  group('match', () {
    test('"or" within a facet, "and" across facets', () {
      final i = index();
      expect(ids(i.filter(q(level: {'1', '2'}))), ['a', 'e', 'b', 'c']);
      expect(ids(i.filter(q(level: {'2'}, genre: {'v'}))), ['c']);
      expect(ids(i.filter(q(tag: {'trem', 'nonna'}))), ['a', 'b', 'c']);
    });

    test('search covers title, genre, tags and author, without accents or case', () {
      final i = index();
      expect(ids(i.filter(q(text: 'familia'))), ['e', 'b']);
      expect(ids(i.filter(q(text: 'NONNA'))), ['b', 'c']);
      expect(ids(i.filter(q(text: 'collodi'))), ['a']);
      expect(ids(i.filter(q(text: 'titolo d'))), ['d']);
      expect(ids(i.filter(q(text: 'sicilia'))), ['d']);
      expect(i.filter(q(text: 'ghost')), isEmpty); // an unknown tag is never shown
    });

    test('names follow the Navigation language', () {
      final i = index(it);
      expect(ids(i.filter(q(text: 'viaggio'))), ['a', 'c']);
      expect(i.label(Facet.tag, 'trem'), 'Treno');
    });

    test('an unknown genre becomes "Outros"; an unknown tag is not offered', () {
      final i = index();
      expect(i.present(Facet.genre), contains(otherGenre));
      expect(i.label(Facet.genre, otherGenre), 'Outros');
      expect(ids(i.filter(q(genre: {otherGenre}))), ['d']);
      expect(i.present(Facet.tag), isNot(contains('ghost')));
      expect(ids(i.filter(q(text: 'outros'))), ['d']);
    });
  });

  group('counts and order (BIB-14)', () {
    test('a count applies the other facets and the search, not its own facet', () {
      final i = index();
      final sel = q(level: {'2'}, tag: {'trem'});
      expect(i.count(sel, Facet.tag, 'nonna'), 2); // A2 with nonna, own facet ignored
      expect(i.count(sel, Facet.genre, 'v'), 1); // A2 and trem
      expect(i.count(sel, Facet.level, '1'), 1); // trem at A1
      final searched = q(text: 'titolo c', tag: {'trem'});
      expect(i.count(searched, Facet.tag, 'nonna'), 1);
    });

    test('checking a value never changes the numbers of its own facet', () {
      final i = index();
      final before = i.order(q(level: {'2'}), Facet.tag).counts;
      final after = i.order(q(level: {'2'}, tag: {'nonna'}), Facet.tag).counts;
      expect(after, before);
    });

    test('checked on top, then most stories, ties by name; zeros apart by name', () {
      final i = index();
      final o = i.order(q(level: {'2'}, tag: {'mar'}), Facet.tag);
      expect(o.top, ['mar']);
      expect(o.rest, ['nonna', 'trem']); // 2, 1
      expect(o.zero, ['roma', 'sic']); // no A2 story has them
      final none = i.order(q(), Facet.tag);
      expect(none.top, isEmpty);
      expect(none.rest, ['mar', 'nonna', 'trem', 'roma', 'sic']); // 2, 2, 2, then 1, 1 by name
    });

    test('"Outros" is last among genres', () {
      final o = index().order(q(), Facet.genre);
      expect(o.rest.last, otherGenre);
    });

    test('levels keep A1 → C2 order with checked ones in place', () {
      final o = index().order(q(level: {'2'}, genre: {'f'}), Facet.level);
      expect(o.top, isEmpty);
      expect(o.rest, ['1', '2']);
      expect(o.zero, ['3']);
    });

    test('a checked value a sync left with no story stays, never hidden', () {
      final o = index().order(q(genre: {'gone'}), Facet.genre);
      expect(o.top, contains('gone'));
    });

    test('the sheet search finds names without accents, zeros included', () {
      final i = index();
      final o = i.order(q(level: {'2'}), Facet.tag);
      expect(i.find(o, Facet.tag, 'sicilia'), ['sic']);
      expect(o.zero, contains('sic'));
      expect(i.find(o, Facet.tag, 'fantasma'), isEmpty);
    });

    test('the match range of a search inside a name with accents', () {
      expect(matchRange('Sicília', 'cili'), (2, 6));
      expect(matchRange('Roma', 'x'), isNull);
    });
  });

  group('sheet note (BIB-14)', () {
    test('names the facets and the search, never the values', () {
      final i = index();
      final sel = q(text: 'x', level: {'2'}, genre: {'v'});
      expect(i.noteFacets(sel, Facet.tag), [Facet.level, Facet.genre]);
      expect(ui.sheetNote(['Nível', 'Gênero'], true), 'Números contam os filtros de Nível e Gênero e a busca.');
      expect(ui.sheetNote(['Nível'], false), 'Números contam o filtro de Nível.');
      expect(ui.sheetNote([], true), 'Números contam a busca.');
    });
  });

  group('facet sheet', () {
    Future<void> pump(WidgetTester t, LibIndex i, LibQuery sel, Facet f, {VoidCallback? onChanged}) async {
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(Tokens.light),
        home: Scaffold(body: FacetSheet(index: i, query: sel, facet: f, onChanged: onChanged ?? () {})),
      ));
    }

    testWidgets('nothing checked: no group label; checking filters live', (t) async {
      final sel = q();
      var changes = 0;
      await pump(t, index(), sel, Facet.tag, onChanged: () => changes++);
      expect(find.text('MARCADOS'), findsNothing);
      expect(find.text('Mais histórias primeiro'.toUpperCase()), findsNothing);
      expect(find.text('Ver 5 histórias'), findsOneWidget);
      await t.tap(find.text('Roma'));
      await t.pump();
      expect(sel.sel[Facet.tag], {'roma'});
      expect(changes, 1);
      expect(find.text('Ver 1 história'), findsOneWidget);
    });

    testWidgets('checked values on top, the note names the other facets', (t) async {
      await pump(t, index(), q(level: {'2'}, tag: {'mar'}), Facet.tag);
      expect(find.text('MARCADOS'), findsOneWidget);
      expect(find.text('OUTROS TEMAS'), findsOneWidget);
      expect(find.textContaining('Números contam o filtro de Nível.', findRichText: true), findsOneWidget);
    });

    testWidgets('zeros are collapsed, then disabled with "0 de N"', (t) async {
      final sel = q(level: {'2'});
      await pump(t, index(), sel, Facet.tag);
      expect(find.text('Roma'), findsNothing);
      await t.tap(find.text('2 temas sem histórias com esses filtros'));
      await t.pump();
      expect(find.text('Roma'), findsOneWidget);
      expect(find.text('0 de 1'), findsNWidgets(2));
      await t.tap(find.text('Roma'));
      await t.pump();
      expect(sel.sel[Facet.tag], isEmpty);
    });

    testWidgets('"Limpar" clears only this facet', (t) async {
      final sel = q(level: {'2'}, tag: {'mar'});
      await pump(t, index(), sel, Facet.tag);
      await t.tap(find.text('Limpar'));
      await t.pump();
      expect(sel.sel[Facet.tag], isEmpty);
      expect(sel.sel[Facet.level], {'2'});
    });

    testWidgets('"Ver 0 histórias" when the list is already empty', (t) async {
      await pump(t, index(), q(text: 'fantasma', level: {'2'}), Facet.genre);
      expect(find.text('Ver 0 histórias'), findsOneWidget);
    });

    testWidgets('more than 12 values: own search; a miss is one line', (t) async {
      final many = Lists(
        genres: lists.genres,
        tags: {for (var k = 0; k < 14; k++) TagId('t$k'): names('Tema $k', 'Tema $k')},
      );
      final i = LibIndex([
        for (var k = 0; k < 14; k++) story('s$k', 1, 'v', ['t$k']),
      ], many, pt, 'Outros');
      await pump(t, i, q(), Facet.tag);
      expect(find.byType(TextField), findsOneWidget);
      await t.enterText(find.byType(TextField), 'fantasma');
      await t.pump();
      expect(find.text('Nenhum tema com “fantasma”.'), findsOneWidget);
      expect(find.textContaining('Sem acento'), findsNothing);
      expect(find.textContaining(' de 14 temas'.toUpperCase()), findsNothing);
      await t.enterText(find.byType(TextField), 'tema 1');
      await t.pump();
      expect(find.text('5 DE 14 TEMAS'), findsOneWidget); // 1, 10..13
      expect(find.textContaining('Sem acento'), findsOneWidget);
    });
  });
}
