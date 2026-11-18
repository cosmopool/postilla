// Builds the debug-only fixture for the stories index (ARQ-23) from the
// Library book's catalogue (docs/design/book-biblioteca.html, the RAW block)
// and the real stories in ../postilla-content/stories. Debug builds load it
// into an empty index on first launch, until sync fills the index for real.
//
//   dart run tool/make_index_fixture.dart
//
// Row: level | minutes | genre | tags | title | subtitle | flags.
// Flags (";"): n=m:ss narration · N arrived through a sync · x no native
// translation · a=author. p= and d (progress) are v1.1 and ignored.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Genre name in the book (pt-BR) → id, Italian, English. "Outros" is not a
/// genre: those rows get an id the list lacks, so the card shows BIB-11's "Outros".
const genres = {
  'Fábula': ['favola', 'Favola', 'Fable'],
  'Diálogo': ['dialogo', 'Dialogo', 'Dialogue'],
  'Cotidiano': ['quotidiano', 'Quotidiano', 'Everyday life'],
  'Conto': ['racconto', 'Racconto', 'Short story'],
  'Crônica': ['cronaca', 'Cronaca', 'Chronicle'],
  'Lenda': ['leggenda', 'Leggenda', 'Legend'],
  'Viagem': ['viaggio', 'Viaggio', 'Travel'],
  'Cartas': ['lettere', 'Lettere', 'Letters'],
  'Mistério': ['mistero', 'Mistero', 'Mystery'],
  'Poesia em prosa': ['poesia-in-prosa', 'Poesia in prosa', 'Prose poetry'],
  'Teatro': ['teatro', 'Teatro', 'Theatre'],
  'Biografia': ['biografia', 'Biografia', 'Biography'],
  'Notícia adaptada': ['notizia', 'Notizia adattata', 'Adapted news'],
  'Clássicos': ['classici', 'Classici', 'Classics'],
  'Ficção científica': ['fantascienza', 'Fantascienza', 'Science fiction'],
  'Romance (capítulo)': ['romanzo', 'Romanzo (capitolo)', 'Novel (chapter)'],
  'Ensaio curto': ['saggio', 'Saggio breve', 'Short essay'],
  'Família': ['famiglia', 'Famiglia', 'Family'],
};
const unknownGenre = 'sconosciuto';

/// Tag name in the book (pt-BR) → id, Italian, English.
const tags = {
  'Família': ['famiglia', 'Famiglia', 'Family'],
  'Comida': ['cibo', 'Cibo', 'Food'],
  'Mar': ['mare', 'Mare', 'Sea'],
  'Cidade': ['citta', 'Città', 'City'],
  'Animais': ['animali', 'Animali', 'Animals'],
  'Roma': ['roma', 'Roma', 'Rome'],
  'Trabalho': ['lavoro', 'Lavoro', 'Work'],
  'Sicília': ['sicilia', 'Sicilia', 'Sicily'],
  'Campo': ['campagna', 'Campagna', 'Countryside'],
  'Amizade': ['amicizia', 'Amicizia', 'Friendship'],
  'Segredo': ['segreto', 'Segreto', 'Secret'],
  'Trem': ['treno', 'Treno', 'Train'],
  'Infância': ['infanzia', 'Infanzia', 'Childhood'],
  'Nápoles': ['napoli', 'Napoli', 'Naples'],
  'Memória': ['memoria', 'Memoria', 'Memory'],
  'Mercado': ['mercato', 'Mercato', 'Market'],
  'Café': ['caffe', 'Caffè', 'Coffee'],
  'Casa': ['casa', 'Casa', 'Home'],
  'Nonna': ['nonna', 'Nonna', 'Grandma'],
  'Escola': ['scuola', 'Scuola', 'School'],
  'Turismo': ['turismo', 'Turismo', 'Tourism'],
  'Verão': ['estate', 'Estate', 'Summer'],
  'Natal': ['natale', 'Natale', 'Christmas'],
  'Veneza': ['venezia', 'Venezia', 'Venice'],
  'Noite': ['notte', 'Notte', 'Night'],
  'Arte': ['arte', 'Arte', 'Art'],
  'Florença': ['firenze', 'Firenze', 'Florence'],
  'Cozinha': ['cucina', 'Cucina', 'Cooking'],
  'Emília-Romanha': ['emilia-romagna', 'Emilia-Romagna', 'Emilia-Romagna'],
  'Montanha': ['montagna', 'Montagna', 'Mountains'],
  'Vizinhos': ['vicini', 'Vicini', 'Neighbours'],
  'Música': ['musica', 'Musica', 'Music'],
  'Milão': ['milano', 'Milano', 'Milan'],
  'Ciência': ['scienza', 'Scienza', 'Science'],
  'Guerra': ['guerra', 'Guerra', 'War'],
  'Magia': ['magia', 'Magia', 'Magic'],
  'Polícia': ['polizia', 'Polizia', 'Police'],
  'Língua': ['lingua', 'Lingua', 'Language'],
  'Futuro': ['futuro', 'Futuro', 'Future'],
  'Amor': ['amore', 'Amore', 'Love'],
  'Futebol': ['calcio', 'Calcio', 'Football'],
  'Nonno': ['nonno', 'Nonno', 'Grandpa'],
  'Inverno': ['inverno', 'Inverno', 'Winter'],
  'Alpes': ['alpi', 'Alpi', 'Alps'],
  'Turim': ['torino', 'Torino', 'Turin'],
  'Festas': ['feste', 'Feste', 'Holidays'],
  'Bicicleta': ['bicicletta', 'Bicicletta', 'Bicycle'],
  'Puglia': ['puglia', 'Puglia', 'Apulia'],
  'Chuva': ['pioggia', 'Pioggia', 'Rain'],
  'Trieste': ['trieste', 'Trieste', 'Trieste'],
  'Sardenha': ['sardegna', 'Sardegna', 'Sardinia'],
  'Livros': ['libri', 'Libri', 'Books'],
  'Bolonha': ['bologna', 'Bologna', 'Bologna'],
  'Tecnologia': ['tecnologia', 'Tecnologia', 'Technology'],
  'Fotografia': ['fotografia', 'Fotografia', 'Photography'],
  'Hotel': ['albergo', 'Albergo', 'Hotel'],
  'Neve': ['neve', 'Neve', 'Snow'],
  'Toscana': ['toscana', 'Toscana', 'Tuscany'],
  'Gênova': ['genova', 'Genova', 'Genoa'],
  'Ópera': ['opera', 'Opera', 'Opera'],
  'Robôs': ['robot', 'Robot', 'Robots'],
  'Imigração': ['immigrazione', 'Immigrazione', 'Immigration'],
  'Azeite': ['olio', 'Olio d’oliva', 'Olive oil'],
  'Pesca': ['pesca', 'Pesca', 'Fishing'],
  'Cinema': ['cinema', 'Cinema', 'Cinema'],
  'Estrelas': ['stelle', 'Stelle', 'Stars'],
  'Restaurante': ['ristorante', 'Ristorante', 'Restaurant'],
  'Sorvete': ['gelato', 'Gelato', 'Ice cream'],
  'Pão': ['pane', 'Pane', 'Bread'],
  'Floresta': ['bosco', 'Bosco', 'Forest'],
  'Saúde': ['salute', 'Salute', 'Health'],
  'Irmãos': ['fratelli', 'Fratelli', 'Siblings'],
  'Aniversário': ['compleanno', 'Compleanno', 'Birthday'],
  'Cavalo': ['cavallo', 'Cavallo', 'Horse'],
  'Telefone': ['telefono', 'Telefono', 'Telephone'],
  'Liberdade': ['liberta', 'Libertà', 'Freedom'],
  'Correio': ['posta', 'Posta', 'Post'],
  'Vespa': ['vespa', 'Vespa', 'Vespa'],
  'Moda': ['moda', 'Moda', 'Fashion'],
  'Carnaval': ['carnevale', 'Carnevale', 'Carnival'],
  'Museu': ['museo', 'Museo', 'Museum'],
  'Ilha': ['isola', 'Isola', 'Island'],
  'Lagos': ['laghi', 'Laghi', 'Lakes'],
  'Gestos': ['gesti', 'Gesti', 'Gestures'],
  'Humor': ['umorismo', 'Umorismo', 'Humour'],
  'Rádio': ['radio', 'Radio', 'Radio'],
  'Jornal': ['giornale', 'Giornale', 'Newspaper'],
  'Dialeto': ['dialetto', 'Dialetto', 'Dialect'],
  'Casamento': ['matrimonio', 'Matrimonio', 'Wedding'],
  'Lua': ['luna', 'Luna', 'Moon'],
  'Barco': ['barca', 'Barca', 'Boat'],
  'Fábrica': ['fabbrica', 'Fabbrica', 'Factory'],
};

/// One tag the cached list lacks, so the card and the Tema facet hide it (BIB-11).
const unknownTag = 'etichetta-nuova';

/// "Pinocchio, capitolo secondo" → work "Pinocchio", part 2.
const ordinals = ['primo', 'secondo', 'terzo', 'quarto', 'quinto'];
(String, int) workOf(String title) {
  final m = RegExp(r'^(.+), capitolo (\w+)').firstMatch(title);
  if (m == null) return ('', 0);
  final n = ordinals.indexOf(m.group(2)!);
  return n < 0 ? ('', 0) : (m.group(1)!, n + 1);
}

const levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
const wpm = [60, 80, 100, 120, 140, 160];

/// Stable pseudo-random number from a string.
int seed(String s) {
  final d = sha256.convert(utf8.encode(s)).bytes;
  return (d[0] << 16) | (d[1] << 8) | d[2];
}

String hex(String s) => sha256.convert(utf8.encode(s)).toString();

/// UUID v4 layout from a hash, so ids stay stable across runs.
String uuidOf(String s) {
  final h = hex('story:$s');
  final v = '4${h.substring(13, 16)}';
  final r = ((int.parse(h[16], radix: 16) & 0x3) | 0x8).toRadixString(16) + h.substring(17, 20);
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-$v-$r-${h.substring(20, 32)}';
}

String slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[àáâã]'), 'a')
    .replaceAll(RegExp('[èéê]'), 'e')
    .replaceAll(RegExp('[ìí]'), 'i')
    .replaceAll(RegExp('[òóô]'), 'o')
    .replaceAll(RegExp('[ùú]'), 'u')
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

/// Title key that matches the book's row to a real story ("L’ultimo" = "L'ultimo",
/// "(adattato)" dropped).
String titleKey(String t) => slug(t.replaceAll('’', "'").replaceAll(' (adattato)', ''));

class Real {
  Real(this.id, this.title, this.subtitle, this.level, this.genre, this.work, this.part, this.words);
  final String id, title, subtitle, genre, work;
  final int level, part, words;
}

/// The real stories: header and Italian word count from the source `.txt`.
Map<String, Real> readReal(Directory dir) {
  final out = <String, Real>{};
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.txt') || f.path.endsWith('genres.txt')) continue;
    final blocks = f.readAsStringSync().split(RegExp(r'\n\s*\n'));
    final head = <String, String>{};
    for (final line in blocks.first.split('\n')) {
      final i = line.indexOf(': ');
      if (i > 0) head[line.substring(0, i)] = line.substring(i + 2);
    }
    var words = 0;
    for (final b in blocks.skip(1)) {
      final it = b.split('\n--\n').first;
      words += RegExp(r"[\p{L}\p{N}]+(?:['’][\p{L}]+)*", unicode: true).allMatches(it).length;
    }
    final r = Real(head['uuid']!, head['title']!, head['subtitle']!, levels.indexOf(head['level']!.toLowerCase()) + 1,
        head['genre']!, head['work'] ?? '', int.parse(head['part'] ?? '0'), words);
    out[titleKey(r.title)] = r;
  }
  return out;
}

void main(List<String> args) {
  final html = File('docs/design/book-biblioteca.html').readAsStringSync();
  final start = html.indexOf('const RAW = `') + 'const RAW = `'.length;
  final rows = html.substring(start, html.indexOf('`', start)).trim().split('\n').where((r) => r.trim().isNotEmpty);
  final contentDir = args.isNotEmpty ? args.first : '../postilla-content/stories';
  final real = readReal(Directory(contentDir));

  final lists = <List<Object>>[];
  void names(String kind, List<String> v) {
    lists.add([kind, v[0], 'it', v[1]]);
    lists.add([kind, v[0], 'pt-BR', '']); // filled below
    lists.add([kind, v[0], 'en', v[2]]);
  }

  for (final MapEntry(key: pt, value: v) in genres.entries) {
    names('genre', v);
    lists[lists.length - 2] = ['genre', v[0], 'pt-BR', pt];
  }
  for (final MapEntry(key: pt, value: v) in tags.entries) {
    names('tag', v);
    lists[lists.length - 2] = ['tag', v[0], 'pt-BR', pt];
  }
  lists.addAll([
    ['language', 'it', '', 'Italiano', 1, 0],
    ['language', 'pt-BR', '', 'Português brasileiro', 0, 1],
    ['language', 'en', '', 'English', 0, 0],
  ]);

  final authors = <String, String>{};
  final stories = <Map<String, Object>>[];
  final arrivals = <String>[];
  final usedReal = <String>{};
  var row = 0;
  for (final line in rows) {
    final p = line.split('|');
    final flags = {for (final f in (p.length > 6 ? p[6] : '').split(';')) if (f.isNotEmpty) f.split('=').first: f.contains('=') ? f.substring(f.indexOf('=') + 1) : ''};
    final r = real[titleKey(p[4])];
    final id = r?.id ?? uuidOf(p[4]);
    if (r != null) usedReal.add(r.id);
    final lv = r?.level ?? levels.indexOf(p[0]) + 1;
    final minutes = int.parse(p[1]);
    final words = r?.words ?? (minutes - 1) * wpm[lv - 1] + 1 + seed(id) % wpm[lv - 1];
    final genre = r?.genre ?? (p[2] == 'Outros' ? unknownGenre : genres[p[2]]![0]);
    final tagIds = [for (final t in p[3].split(',')) if (t.isNotEmpty) tags[t]![0]];
    if (row++ % 37 == 5) tagIds.add(unknownTag); // a few stories carry a tag the cache lacks
    final (work, part) = r == null ? workOf(p[4]) : (r.work, r.part);
    final authorName = flags['a'] ?? '';
    final author = authorName.isEmpty ? '' : slug(authorName);
    if (author.isNotEmpty) authors[author] = authorName;
    final audio = flags['n'] ?? '';
    final audioMs = audio.isEmpty ? 0 : (int.parse(audio.split(':')[0]) * 60 + int.parse(audio.split(':')[1])) * 1000;
    // Coverage: the share of NVdB words drops with the level.
    final covered = (words * (0.97 - 0.03 * lv - (seed('$id:c') % 4) / 100)).floor();
    final b1 = (covered * 0.75).floor(), b2 = (covered * 0.17).floor(), b3 = covered - b1 - b2;
    Map<String, Object> translation(String lang, int w, List<int> bands) => {
          'lang': lang,
          'sha256': hex('$id:$lang'),
          'title': r?.title ?? p[4],
          'subtitle': r?.subtitle ?? p[5],
          'words': w,
          'band_words': bands,
          'audio_ms': lang == 'it' ? audioMs : 0,
          'opus_sha256': lang == 'it' && audioMs > 0 ? hex('$id:$lang:opus') : '',
          'opus_size': lang == 'it' ? audioMs * 3 : 0,
        };
    stories.add({
      'id': id,
      'level': lv,
      'genre': genre,
      'tags': tagIds,
      'work': work,
      'part': part,
      'author': author,
      'adapted': author.isEmpty ? 0 : 1,
      // Goldoni's stories stand in for a CC BY-SA adaptation, so the colophon's
      // licence line is exercised; the other classics are public domain.
      'license': author.isEmpty ? 'LicenseRef-Postilla' : (authorName == 'Carlo Goldoni' ? 'CC-BY-SA-4.0' : 'public-domain'),
      'translations': [
        translation('it', words, [words - covered, b1, b2, b3]),
        if (!flags.containsKey('x')) translation('pt-BR', (words * 1.08).round(), [0, 0, 0, 0]),
      ],
    });
    if (flags.containsKey('N')) arrivals.add(id);
  }
  for (final r in real.values) {
    if (!usedReal.contains(r.id)) stderr.writeln('real story not in the catalogue: ${r.title}');
  }
  for (final MapEntry(key: id, value: name) in authors.entries) {
    lists.add(['author', id, '', name]);
  }

  final out = {
    'state': {'target': 'it', 'native': 'pt-BR', 'cursor': 0, 'new_count': arrivals.length},
    'lists': lists,
    'stories': stories,
    'arrivals': arrivals,
  };
  File('assets/dev/index_fixture.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(out)}\n');
  stdout.writeln('${stories.length} stories, ${usedReal.length} real, ${arrivals.length} arrived → assets/dev/index_fixture.json');
}
