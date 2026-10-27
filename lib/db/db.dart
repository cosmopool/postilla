// Bancos do app: `user` (ajustes), `stories` e `dict` (só leitura).
// Todas as consultas rodam num isolate dedicado (ARQ-31); a tela chama uma
// função `db…` por consulta, que devolve structs prontos (ARQ-40, ARQ-48).
// Nenhuma função devolve null nem lança: falha vira valor zero e vai para o
// log (ARQ-49).
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'trie.dart';

/// Log do app (v1: só o console; o banco `log` volta com o diagnóstico).
void appLog(String msg) => debugPrint('[postilla] $msg');

// ---------------------------------------------------------------- tipos

extension type const StoryId(String v) {}
extension type const GenreId(String v) {}

/// Nível A1…B2 como 1…4.
extension type const Level(int v) {
  static const names = ['A1', 'A2', 'B1', 'B2'];
  String get name => v >= 1 && v <= 4 ? names[v - 1] : '';
}

class Genre {
  const Genre(this.id, this.pt, this.it);
  final GenreId id;
  final String pt;
  final String it;
}

class Story {
  const Story({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.genre,
    required this.work,
    required this.part,
    required this.words,
    required this.minutes,
  });
  final StoryId id;
  final String title;
  final String subtitle;
  final Level level;
  final GenreId genre;
  final String work; // '' fora de obra dividida
  final int part;
  final int words;
  final int minutes;

  static const nil = Story(
      id: StoryId(''), title: '', subtitle: '', level: Level(0), genre: GenreId(''), work: '', part: 0, words: 0, minutes: 0);
}

/// Span em unidades UTF-16 do texto do parágrafo.
class Span {
  const Span(this.start, this.end);
  final int start;
  final int end;
  @override
  bool operator ==(Object other) => other is Span && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

class Paragraph {
  const Paragraph(this.it, this.pt, this.words, this.itSents, this.ptSents);
  final String it;
  final String pt;
  final List<Span> words;
  final List<Span> itSents;
  final List<Span> ptSents;
}

/// Lema + classe: como o app aponta para um verbete (ARQ-35).
class EntryRef {
  const EntryRef(this.lemma, this.pos, [this.meta = '']);
  final String lemma;
  final String pos;
  final String meta; // "sostantivo maschile", para listas
  @override
  bool operator ==(Object other) => other is EntryRef && other.lemma == lemma && other.pos == pos;
  @override
  int get hashCode => Object.hash(lemma, pos);
}

class Sense {
  const Sense(this.gloss, this.labels, this.examples);
  final String gloss;
  final List<String> labels;
  final List<String> examples;
}

class Flex {
  const Flex(this.form, this.tags);
  final String form;
  final String tags;
}

class Conj {
  const Conj(this.tense, this.person, this.forms);
  final int tense; // 1 presente · 2 passato prossimo · 3 imperfetto · 4 futuro · 5 imperativo
  final int person; // 1 io … 6 loro
  final List<String> forms;
}

class Link {
  const Link(this.word, [this.note = '']);
  final String word;
  final String note;
}

/// Verbete inteiro, já parseado do JSON no isolate do banco.
class Entry {
  const Entry({
    required this.word,
    required this.pos,
    this.tags = const [],
    this.valency = '',
    this.aux = '',
    this.flex = const [],
    this.syll = const [],
    this.ipa = '',
    this.gloss = const [],
    this.glossSrc = '',
    this.senses = const [],
    this.conj = const [],
    this.participle = '',
    this.gerund = '',
    this.etym = '',
    this.syn = const [],
    this.ant = const [],
    this.derived = const [],
    this.related = const [],
    this.altered = const [],
    this.confusables = const [],
  });
  final String word;
  final String pos;
  final List<String> tags;
  final String valency;
  final String aux;
  final List<Flex> flex;
  final List<String> syll;
  final String ipa;
  final List<String> gloss;
  final String glossSrc;
  final List<Sense> senses;
  final List<Conj> conj;
  final String participle;
  final String gerund;
  final String etym;
  final List<Link> syn;
  final List<Link> ant;
  final List<Link> derived;
  final List<String> related;
  final List<Link> altered; // note = tipo (diminutivo…)
  final List<String> confusables;

  static const nil = Entry(word: '', pos: '');
  bool get isNil => word.isEmpty;

  /// "sostantivo maschile", "verbo intransitivo pronominale".
  String get classLine => [pos, ...tags, if (valency.isNotEmpty) valency].join(' ');
}

class SearchHit {
  const SearchHit(this.ref, this.exact);
  final EntryRef ref;
  final bool exact;
}

class ContentInfo {
  const ContentInfo(this.dictVersion, this.storiesVersion, this.dumpDate);
  final String dictVersion;
  final String storiesVersion;
  final String dumpDate; // AAAA-MM-DD
  static const nil = ContentInfo('', '', '');
}

// ---------------------------------------------------------------- isolate

/// O que vive no isolate do banco.
class Dbs {
  Dbs(this.user, this.stories, this.dict);
  final Database user;
  final Database stories;
  final Database dict;
  Trie? trie; // "Você quis dizer", montada no primeiro uso (ARQ-66)
}

class _Request {
  _Request(this.fn, this.reply);
  final Object? Function(Dbs) fn;
  final SendPort reply;
}

SendPort? _port;

/// Abre os três bancos no isolate. `dir` tem `user.db`; `dictPath` e
/// `storiesPath` são os pacotes já descompactados.
Future<void> dbOpen({required String userPath, required String dictPath, required String storiesPath}) async {
  final ready = ReceivePort();
  await Isolate.spawn(_main, (ready.sendPort, userPath, dictPath, storiesPath), debugName: 'db');
  _port = await ready.first as SendPort;
}

void _main((SendPort, String, String, String) args) {
  final (ready, userPath, dictPath, storiesPath) = args;
  final user = sqlite3.open(userPath);
  _migrate(user);
  final stories = sqlite3.open('file:$storiesPath?mode=ro&immutable=1', uri: true, mode: OpenMode.readOnly);
  final dict = sqlite3.open('file:$dictPath?mode=ro&immutable=1', uri: true, mode: OpenMode.readOnly);
  final dbs = Dbs(user, stories, dict);
  final requests = ReceivePort();
  ready.send(requests.sendPort);
  requests.listen((msg) {
    final r = msg as _Request;
    try {
      r.reply.send(r.fn(dbs));
    } catch (e, st) {
      appLog('db: $e\n$st');
      r.reply.send(_Failed());
    }
  });
}

class _Failed {}

/// Roda `fn` no isolate do banco. Em falha, devolve `zero`.
Future<T> _run<T>(T Function(Dbs) fn, T zero) async {
  final port = _port;
  if (port == null) return zero;
  final reply = ReceivePort();
  port.send(_Request(fn, reply.sendPort));
  final res = await reply.first;
  reply.close();
  return res is _Failed ? zero : res as T;
}

// ---------------------------------------------------------------- user: migrações e ajustes

const _appId = 0x506f7374; // "Post" (ARQ-77)

/// Scripts numerados, só para frente (ARQ-32). O índice + 1 é o user_version.
const _migrations = [
  '''
  CREATE TABLE setting (
    id TEXT NOT NULL UNIQUE,
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER NOT NULL DEFAULT 0
  );
  ''',
];

void _migrate(Database db) {
  db.execute('PRAGMA journal_mode = WAL');
  db.execute('PRAGMA application_id = $_appId');
  for (var v = db.userVersion; v < _migrations.length; v++) {
    db.execute('BEGIN');
    db.execute(_migrations[v]);
    db.userVersion = v + 1;
    db.execute('COMMIT');
  }
}

/// UUID v7: 48 bits de ms + aleatório (ARQ-33).
String uuidV7() {
  final rnd = Random.secure();
  final b = Uint8List(16);
  final ms = DateTime.now().millisecondsSinceEpoch;
  for (var i = 0; i < 6; i++) {
    b[i] = (ms >> (8 * (5 - i))) & 0xff;
  }
  for (var i = 6; i < 16; i++) {
    b[i] = rnd.nextInt(256);
  }
  b[6] = 0x70 | (b[6] & 0x0f);
  b[8] = 0x80 | (b[8] & 0x3f);
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Todos os ajustes gravados, chave → JSON.
Future<Map<String, Object?>> dbSettingsLoad() => _run((d) {
      final out = <String, Object?>{};
      for (final r in d.user.select('SELECT key, value FROM setting WHERE deleted_at = 0')) {
        out[r['key'] as String] = jsonDecode(r['value'] as String);
      }
      return out;
    }, const {});

Future<bool> dbSettingSet(String key, Object? value) => _run((d) {
      final now = DateTime.now().millisecondsSinceEpoch;
      d.user.execute(
        'INSERT INTO setting (id, key, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at, deleted_at = 0',
        [uuidV7(), key, jsonEncode(value), now, now],
      );
      return true;
    }, false);

// ---------------------------------------------------------------- stories

Future<List<Genre>> dbGenres() => _run(
      (d) => [
        for (final r in d.stories.select('SELECT id, name_pt, name_it FROM genre'))
          Genre(GenreId(r['id'] as String), r['name_pt'] as String, r['name_it'] as String),
      ],
      const [],
    );

/// Catálogo na ordem fixa do BIB-04: nível, depois da mais curta para a mais longa.
Future<List<Story>> dbStories() => _run(
      (d) => [
        for (final r in d.stories.select(
            'SELECT id, title, subtitle, level, genre, work, part, words, minutes FROM story ORDER BY level, words, title'))
          Story(
            id: StoryId(r['id'] as String),
            title: r['title'] as String,
            subtitle: r['subtitle'] as String,
            level: Level(r['level'] as int),
            genre: GenreId(r['genre'] as String),
            work: r['work'] as String,
            part: r['part'] as int,
            words: r['words'] as int,
            minutes: r['minutes'] as int,
          ),
      ],
      const [],
    );

List<Span> _spans(Uint8List blob) {
  final bd = ByteData.sublistView(blob);
  return [
    for (var i = 0; i + 4 <= blob.length; i += 4) Span(bd.getUint16(i, Endian.little), bd.getUint16(i + 2, Endian.little)),
  ];
}

Future<List<Paragraph>> dbParagraphs(StoryId id) => _run(
      (d) => [
        for (final r in d.stories.select(
            'SELECT it, pt, it_words, it_sents, pt_sents FROM paragraph WHERE story_id = ? ORDER BY pos', [id.v]))
          Paragraph(
            r['it'] as String,
            r['pt'] as String,
            _spans(r['it_words'] as Uint8List),
            _spans(r['it_sents'] as Uint8List),
            _spans(r['pt_sents'] as Uint8List),
          ),
      ],
      const [],
    );

Future<ContentInfo> dbContentInfo() => _run((d) {
      String meta(Database db, String key) {
        final rs = db.select('SELECT value FROM meta WHERE key = ?', [key]);
        return rs.isEmpty ? '' : rs.first['value'] as String;
      }

      return ContentInfo(meta(d.dict, 'version'), meta(d.stories, 'version'), meta(d.dict, 'wiktionary_dump'));
    }, ContentInfo.nil);

// ---------------------------------------------------------------- dict: forma → lema

/// Variantes de uma forma, na ordem de procura (ARQ-61, ARQ-62): como está
/// escrita, em minúsculas; numa elisão, depois só a parte após o apóstrofo.
List<String> formCandidates(String form) {
  final f = form.replaceAll('’', "'");
  final out = <String>[f];
  final lower = f.toLowerCase();
  if (lower != f) out.add(lower);
  final apo = f.indexOf("'");
  if (apo > 0 && apo < f.length - 1) {
    final tail = f.substring(apo + 1);
    out.add(tail);
    if (tail.toLowerCase() != tail) out.add(tail.toLowerCase());
  }
  return out;
}

/// Lemas de uma forma exatamente como escrita: verbete com essa palavra e
/// verbetes de que ela é forma. Verbete próprio primeiro.
List<EntryRef> _lemmasExact(Database dict, String s) {
  final out = <EntryRef>[];
  for (final r in dict.select(
      'SELECT word, pos, data FROM entry WHERE word = ?1 '
      'UNION ALL SELECT e.word, e.pos, e.data FROM form f JOIN entry e ON e.id = f.entry_id WHERE f.form = ?1',
      [s])) {
    final ref = EntryRef(r['word'] as String, r['pos'] as String, _metaOf(r['data'] as String));
    if (!out.contains(ref)) out.add(ref);
  }
  return out;
}

String _metaOf(String data) {
  final m = jsonDecode(data) as Map<String, dynamic>;
  return [m['pos'], ...((m['tags'] as List?) ?? const []), if (m['valency'] != null) m['valency']].join(' ');
}

List<EntryRef> _lemmas(Database dict, String form) {
  for (final c in formCandidates(form)) {
    final got = _lemmasExact(dict, c);
    if (got.isNotEmpty) return got;
  }
  return const [];
}

/// Resolve em lote as formas distintas de uma história (ARQ-53).
Future<Map<String, List<EntryRef>>> dbLemmasOf(List<String> forms) => _run((d) {
      return {for (final f in forms) f: _lemmas(d.dict, f)};
    }, const {});

/// Lemas de uma forma ou expressão ("si siede" → sedersi).
Future<List<EntryRef>> dbLemmas(String form) => _run((d) => _lemmas(d.dict, form), const []);

// ---------------------------------------------------------------- dict: verbete

Future<Entry> dbEntry(EntryRef ref) => _run((d) {
      final rs = d.dict.select('SELECT data FROM entry WHERE word = ? AND pos = ? LIMIT 1', [ref.lemma, ref.pos]);
      if (rs.isEmpty) return Entry.nil;
      return parseEntry(rs.first['data'] as String);
    }, Entry.nil);

/// Parse na borda (ARQ-48): o JSON de `entry.data` vira `Entry`.
Entry parseEntry(String data) {
  final m = jsonDecode(data) as Map<String, dynamic>;
  List<String> strs(String k) => [for (final x in (m[k] as List?) ?? const []) x as String];
  List<Link> links(String k, String note) => [
        for (final x in (m[k] as List?) ?? const [])
          Link((x as Map<String, dynamic>)['word'] as String, (x[note] as String?) ?? ''),
      ];
  return Entry(
    word: m['word'] as String,
    pos: m['pos'] as String,
    tags: strs('tags'),
    valency: (m['valency'] as String?) ?? '',
    aux: (m['aux'] as String?) ?? '',
    flex: [
      for (final x in (m['flex'] as List?) ?? const [])
        Flex((x as Map<String, dynamic>)['form'] as String, x['tags'] as String),
    ],
    syll: strs('syll'),
    ipa: (m['ipa'] as String?) ?? '',
    gloss: strs('gloss'),
    glossSrc: (m['gloss_src'] as String?) ?? '',
    senses: [
      for (final x in (m['senses'] as List?) ?? const [])
        Sense(
          (x as Map<String, dynamic>)['gloss'] as String,
          [for (final l in (x['labels'] as List?) ?? const []) l as String],
          [for (final e in (x['examples'] as List?) ?? const []) e as String],
        ),
    ],
    conj: [
      for (final x in (m['conj'] as List?) ?? const [])
        Conj(
          (x as Map<String, dynamic>)['tense'] as int,
          x['person'] as int,
          [for (final f in x['forms'] as List) f as String],
        ),
    ],
    participle: (m['participle'] as String?) ?? '',
    gerund: (m['gerund'] as String?) ?? '',
    etym: (m['etym'] as String?) ?? '',
    syn: links('syn', 'note'),
    ant: links('ant', 'note'),
    derived: links('derived', 'note'),
    related: strs('related'),
    altered: links('altered', 'kind'),
    confusables: strs('confusables'),
  );
}

// ---------------------------------------------------------------- dict: busca

/// Minúscula e sem acento (ARQ-63), igual à coluna `*_norm` do pipeline.
String normalize(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = switch (r) {
      >= 0x41 && <= 0x5A => r + 32,
      >= 0xC0 && <= 0xC5 || >= 0xE0 && <= 0xE5 => 0x61,
      >= 0xC8 && <= 0xCB || >= 0xE8 && <= 0xEB => 0x65,
      >= 0xCC && <= 0xCF || >= 0xEC && <= 0xEF => 0x69,
      >= 0xD2 && <= 0xD6 || >= 0xF2 && <= 0xF6 => 0x6F,
      >= 0xD9 && <= 0xDC || >= 0xF9 && <= 0xFC => 0x75,
      0xC7 || 0xE7 => 0x63,
      0xD1 || 0xF1 => 0x6E,
      0x2019 => 0x27,
      _ => r,
    };
    b.writeCharCode(c);
  }
  return b.toString();
}

const searchLimit = 30;

/// Sugestões da busca (DIC-11, ARQ-63..65): lemas e formas, sem acento nem
/// maiúscula, com `?` e `*`. Ordem: igual ao digitado, faixa do NVdB, alfabética.
Future<List<SearchHit>> dbSearch(String query) => _run((d) {
      final q = normalize(query.trim());
      if (q.isEmpty) return const <SearchHit>[];
      final wild = q.contains('?') || q.contains('*');
      // GLOB: escapa os metacaracteres que o aluno não digitou como curinga.
      final pattern = wild ? q.replaceAll('[', '[[]') : '${q.replaceAll('[', '[[]').replaceAll('*', '[*]').replaceAll('?', '[?]')}*';
      final rs = d.dict.select('''
        SELECT word, pos, data, band, MIN(exact) AS exact FROM (
          SELECT word, pos, data, band, word_norm != ?2 AS exact FROM entry WHERE word_norm GLOB ?1
          UNION ALL
          SELECT e.word, e.pos, e.data, e.band, f.form_norm != ?2 AS exact
            FROM form f JOIN entry e ON e.id = f.entry_id WHERE f.form_norm GLOB ?1
        )
        GROUP BY word, pos
        ORDER BY exact, CASE band WHEN 0 THEN 9 ELSE band END, length(word), word
        LIMIT $searchLimit''', [pattern, q]);
      return [
        for (final r in rs)
          SearchHit(EntryRef(r['word'] as String, r['pos'] as String, _metaOf(r['data'] as String)), r['exact'] == 0),
      ];
    }, const []);

/// "Você quis dizer" (ARQ-66): lemas a até 2 edições (OSA), por distância e faixa.
Future<List<EntryRef>> dbDidYouMean(String query) => _run((d) {
      final q = normalize(query.trim());
      if (q.isEmpty) return const <EntryRef>[];
      final trie = d.trie ??= _buildTrie(d.dict);
      final hits = trie.search(q, 2);
      final out = <EntryRef>[];
      for (final h in hits.take(8)) {
        for (final r in d.dict.select('SELECT word, pos, data FROM entry WHERE word_norm = ? ORDER BY band = 0, band LIMIT 2', [h.word])) {
          out.add(EntryRef(r['word'] as String, r['pos'] as String, _metaOf(r['data'] as String)));
        }
      }
      return out.take(8).toList();
    }, const []);

Trie _buildTrie(Database dict) {
  final t = Trie();
  for (final r in dict.select('SELECT word_norm, MIN(CASE band WHEN 0 THEN 9 ELSE band END) AS rank FROM entry GROUP BY word_norm')) {
    t.insert(r['word_norm'] as String, r['rank'] as int);
  }
  return t;
}
