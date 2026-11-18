// App databases: `user` (settings), `stories` and `dict` (read-only).
// Every query runs on a dedicated isolate (ARQ-31); the screen calls one
// `db…` function per query, which returns ready structs (ARQ-40, ARQ-48).
// No function returns null or throws: failure becomes a zero value and goes to the
// log (ARQ-49).
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'trie.dart';

/// App log (v1: console only; the `log` database returns with diagnostics).
void appLog(String msg) => debugPrint('[postilla] $msg');

// ---------------------------------------------------------------- types

extension type const StoryId(String v) {}
extension type const GenreId(String v) {}
extension type const TagId(String v) {}
extension type const AuthorId(String v) {}

/// BCP 47 id exactly as `GET /languages` lists it (`it`, `pt-BR`).
extension type const LangId(String v) {}

/// Level A1…C2 as 1…6 (`.tilla` header).
extension type const Level(int v) {
  static const names = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const wordsPerMinute = [60, 80, 100, 120, 140, 160];
  String get name => v >= 1 && v <= 6 ? names[v - 1] : '';

  /// Reading time (BIB-01): words ÷ the level's speed, rounded up.
  int minutes(int words) => v >= 1 && v <= 6 ? (words + wordsPerMinute[v - 1] - 1) ~/ wordsPerMinute[v - 1] : 0;
}

/// One story as the Library and the Reader see it: the story-level fields plus
/// the target translation's header (ARQ-23), for the language pair in `state`.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.genre,
    this.tags = const [],
    this.work = '',
    this.part = 0,
    this.author = const AuthorId(''),
    this.adapted = false,
    this.license = 'LicenseRef-Postilla',
    required this.words,
    this.bandWords = const [0, 0, 0, 0],
    this.audioMs = 0,
    this.hasNative = true,
    this.arrived = false,
  });
  final StoryId id;
  final String title; // target language, never translated
  final String subtitle;
  final Level level;
  final GenreId genre;
  final List<TagId> tags; // feed order
  final String work; // '' outside a split work
  final int part;
  final AuthorId author; // '' for a story written for Postilla
  final bool adapted;
  final String license; // SPDX id, `public-domain` or `LicenseRef-Postilla`
  final int words;
  final List<int> bandWords; // NVdB bands 0..3; all 0 outside Italian
  final int audioMs; // 0: not narrated
  final bool hasNative; // false: no translation in the native language (TRA-10)
  final bool arrived; // "Chegou agora" (OFF-24, ARQ-26)

  int get minutes => level.minutes(words);

  static const nil = Story(id: StoryId(''), title: '', subtitle: '', level: Level(0), genre: GenreId(''), words: 0);
}

class Language {
  const Language(this.id, this.name, {this.target = false, this.translate = false});
  final LangId id;
  final String name; // the language's own name
  final bool target; // can be learned
  final bool translate; // stories are translated into it
}

/// Cached lists (ARQ-27). A name lookup returns '' for an id the cache lacks:
/// the caller applies BIB-11 (genre → "Outros", tag hidden, author left off).
class Lists {
  const Lists({this.genres = const {}, this.tags = const {}, this.authors = const {}, this.languages = const []});
  final Map<GenreId, Map<LangId, String>> genres;
  final Map<TagId, Map<LangId, String>> tags;
  final Map<AuthorId, String> authors;
  final List<Language> languages;

  String genre(GenreId id, LangId lang) => genres[id]?[lang] ?? '';
  String tag(TagId id, LangId lang) => tags[id]?[lang] ?? '';
  String author(AuthorId id) => authors[id] ?? '';

  static const nil = Lists();
}

/// The index's `state` table (ARQ-23).
class IndexState {
  const IndexState({
    this.cursor = 0,
    this.target = const LangId('it'),
    this.native = const LangId('pt-BR'),
    this.newCount = 0,
    this.unknownFormat = false,
    this.resync = false,
  });
  final int cursor;
  final LangId target;
  final LangId native;
  final int newCount; // OFF-24
  final bool unknownFormat; // OFF-26
  final bool resync; // after a language switch (ARQ-22, BIB-12)

  /// Language of genre and tag names: Immersion › Navigation (BIB-06).
  LangId nav(bool navTarget) => navTarget ? target : native;

  static const nil = IndexState();
}

/// Span in UTF-16 units of the paragraph text.
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

/// Lemma + class: how the app points to an entry (ARQ-35).
class EntryRef {
  const EntryRef(this.lemma, this.pos, [this.meta = '']);
  final String lemma;
  final String pos;
  final String meta; // "sostantivo maschile", for lists
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

/// Whole entry, already parsed from JSON on the database isolate.
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
  final List<Link> altered; // note = kind (diminutivo…)
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
  final String dumpDate; // YYYY-MM-DD
  static const nil = ContentInfo('', '', '');
}

// ---------------------------------------------------------------- isolate

/// What lives on the database isolate.
class Dbs {
  Dbs(this.user, this.stories, this.dict, this.index);
  final Database user;
  final Database stories; // bundled package: paragraph text until the .tilla reader
  final Database dict;
  final Database index; // story index (ARQ-23), read-write
  Trie? trie; // "Did you mean", built on first use (ARQ-66)
}

class _Request {
  _Request(this.fn, this.reply);
  final Object? Function(Dbs) fn;
  final SendPort reply;
}

SendPort? _port;

/// Opens the databases on the isolate: `user.db` and the story index
/// (`indexPath`, created on first open), plus the already-decompressed
/// packages `dictPath` and `storiesPath`.
Future<void> dbOpen({
  required String userPath,
  required String dictPath,
  required String storiesPath,
  required String indexPath,
}) async {
  final ready = ReceivePort();
  await Isolate.spawn(_main, (ready.sendPort, userPath, dictPath, storiesPath, indexPath), debugName: 'db');
  _port = await ready.first as SendPort;
}

void _main((SendPort, String, String, String, String) args) {
  final (ready, userPath, dictPath, storiesPath, indexPath) = args;
  final user = sqlite3.open(userPath);
  _migrate(user, _migrations);
  final index = sqlite3.open(indexPath);
  _migrate(index, _indexMigrations);
  final stories = sqlite3.open('file:$storiesPath?mode=ro&immutable=1', uri: true, mode: OpenMode.readOnly);
  final dict = sqlite3.open('file:$dictPath?mode=ro&immutable=1', uri: true, mode: OpenMode.readOnly);
  final dbs = Dbs(user, stories, dict, index);
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

/// Runs `fn` on the database isolate. On failure, returns `zero`.
Future<T> _run<T>(T Function(Dbs) fn, T zero) async {
  final port = _port;
  if (port == null) return zero;
  final reply = ReceivePort();
  port.send(_Request(fn, reply.sendPort));
  final res = await reply.first;
  reply.close();
  return res is _Failed ? zero : res as T;
}

// ---------------------------------------------------------------- user: migrations and settings

const _appId = 0x506f7374; // "Post" (ARQ-77)

/// Numbered scripts, forward only (ARQ-32). Index + 1 is the user_version.
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

/// Story index (ARQ-23), written only by sync and, in debug builds, by the
/// fixture. Same forward-only scripts as `user` (ARQ-32).
const _indexMigrations = [
  '''
  CREATE TABLE translation (
    story_id TEXT NOT NULL,
    lang TEXT NOT NULL,
    sha256 TEXT NOT NULL,
    file TEXT NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    level INTEGER NOT NULL,
    genre TEXT NOT NULL,
    work TEXT NOT NULL,
    part INTEGER NOT NULL,
    author TEXT NOT NULL,
    adapted INTEGER NOT NULL,
    license TEXT NOT NULL,
    words INTEGER NOT NULL,
    band0 INTEGER NOT NULL,
    band1 INTEGER NOT NULL,
    band2 INTEGER NOT NULL,
    band3 INTEGER NOT NULL,
    audio_ms INTEGER NOT NULL,
    opus_sha256 TEXT NOT NULL,
    opus_size INTEGER NOT NULL,
    PRIMARY KEY (story_id, lang)
  ) WITHOUT ROWID;
  CREATE INDEX translation_lang ON translation (lang, level, words);
  CREATE TABLE translation_tag (
    story_id TEXT NOT NULL,
    pos INTEGER NOT NULL, -- feed order
    tag TEXT NOT NULL,
    PRIMARY KEY (story_id, pos)
  ) WITHOUT ROWID;
  CREATE TABLE list (
    kind TEXT NOT NULL, -- genre · tag · author · language
    id TEXT NOT NULL,
    lang TEXT NOT NULL, -- '' for author and language
    name TEXT NOT NULL,
    target INTEGER NOT NULL DEFAULT 0,
    translate INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (kind, id, lang)
  ) WITHOUT ROWID;
  CREATE TABLE state (key TEXT PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID;
  CREATE TABLE arrival (story_id TEXT PRIMARY KEY) WITHOUT ROWID;
  ''',
];

void _migrate(Database db, List<String> migrations) {
  db.execute('PRAGMA journal_mode = WAL');
  db.execute('PRAGMA application_id = $_appId');
  for (var v = db.userVersion; v < migrations.length; v++) {
    db.execute('BEGIN');
    db.execute(migrations[v]);
    db.userVersion = v + 1;
    db.execute('COMMIT');
  }
}

/// UUID v7: 48 bits of ms + random (ARQ-33).
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

/// Every stored setting, key → JSON.
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

// The Library and the Reader read stories from the index (ARQ-23); paragraph
// text still comes from the bundled stories.db until the .tilla reader exists.

/// `state` keys.
const _stCursor = 'cursor', _stTarget = 'target', _stNative = 'native';
const _stNewCount = 'new_count', _stUnknownFormat = 'unknown_format', _stResync = 'resync';

IndexState _indexState(Database index) {
  final m = {for (final r in index.select('SELECT key, value FROM state')) r['key'] as String: r['value'] as String};
  int n(String k) => int.tryParse(m[k] ?? '') ?? 0;
  return IndexState(
    cursor: n(_stCursor),
    target: LangId(m[_stTarget] ?? IndexState.nil.target.v),
    native: LangId(m[_stNative] ?? IndexState.nil.native.v),
    newCount: n(_stNewCount),
    unknownFormat: n(_stUnknownFormat) == 1,
    resync: n(_stResync) == 1,
  );
}

void _setState(Database index, String key, Object value) => index.execute(
    'INSERT INTO state (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value', [key, '$value']);

/// Every story of the current language pair, in BIB-04 order: level, then
/// shortest to longest, then title. A story is listed by its target-language
/// translation; one without it can't be read and is left out.
Future<List<Story>> dbStories() => _run((d) {
      final st = _indexState(d.index);
      final tags = <String, List<TagId>>{};
      for (final r in d.index.select('SELECT story_id, tag FROM translation_tag ORDER BY story_id, pos')) {
        (tags[r['story_id'] as String] ??= []).add(TagId(r['tag'] as String));
      }
      return [
        for (final r in d.index.select('''
          SELECT t.*,
            EXISTS (SELECT 1 FROM translation n WHERE n.story_id = t.story_id AND n.lang = ?2) AS has_native,
            EXISTS (SELECT 1 FROM arrival a WHERE a.story_id = t.story_id) AS arrived
          FROM translation t WHERE t.lang = ?1
          ORDER BY t.level, t.words, t.title''', [st.target.v, st.native.v]))
          Story(
            id: StoryId(r['story_id'] as String),
            title: r['title'] as String,
            subtitle: r['subtitle'] as String,
            level: Level(r['level'] as int),
            genre: GenreId(r['genre'] as String),
            tags: tags[r['story_id'] as String] ?? const [],
            work: r['work'] as String,
            part: r['part'] as int,
            author: AuthorId(r['author'] as String),
            adapted: r['adapted'] == 1,
            license: r['license'] as String,
            words: r['words'] as int,
            bandWords: [r['band0'] as int, r['band1'] as int, r['band2'] as int, r['band3'] as int],
            audioMs: r['audio_ms'] as int,
            hasNative: r['has_native'] == 1,
            arrived: r['arrived'] == 1,
          ),
      ];
    }, const []);

/// Genres, tags, authors and languages from the cache (ARQ-27).
Future<Lists> dbLists() => _run((d) {
      final genres = <GenreId, Map<LangId, String>>{};
      final tags = <TagId, Map<LangId, String>>{};
      final authors = <AuthorId, String>{};
      final languages = <Language>[];
      for (final r in d.index.select('SELECT kind, id, lang, name, target, translate FROM list ORDER BY kind, id, lang')) {
        final id = r['id'] as String, lang = LangId(r['lang'] as String), name = r['name'] as String;
        switch (r['kind']) {
          case 'genre':
            (genres[GenreId(id)] ??= {})[lang] = name;
          case 'tag':
            (tags[TagId(id)] ??= {})[lang] = name;
          case 'author':
            authors[AuthorId(id)] = name;
          case 'language':
            languages.add(Language(LangId(id), name, target: r['target'] == 1, translate: r['translate'] == 1));
        }
      }
      return Lists(genres: genres, tags: tags, authors: authors, languages: languages);
    }, Lists.nil);

Future<IndexState> dbIndexState() => _run((d) => _indexState(d.index), IndexState.nil);

/// Opening a story deletes its `arrival` row (ARQ-26).
Future<bool> dbArrivalOpened(StoryId id) => _run((d) {
      d.index.execute('DELETE FROM arrival WHERE story_id = ?', [id.v]);
      return true;
    }, false);

/// The Library zeroes the new-stories count when the learner leaves it (BIB-13).
Future<bool> dbNewCountReset() => _run((d) {
      _setState(d.index, _stNewCount, 0);
      return true;
    }, false);

/// Language switch (AJU-08, ARQ-22): stores the pair, cursor 0, resync on.
/// Files of the language left behind stay in the index.
Future<bool> dbSetLanguages(LangId target, LangId native) => _run((d) {
      d.index.execute('BEGIN');
      _setState(d.index, _stTarget, target.v);
      _setState(d.index, _stNative, native.v);
      _setState(d.index, _stCursor, 0);
      _setState(d.index, _stResync, 1);
      d.index.execute('COMMIT');
      return true;
    }, false);

/// Debug builds only: fills an empty index from `assets/dev/index_fixture.json`
/// (written by `tool/make_index_fixture.dart`). Does nothing once the index
/// has a story, so sync and the fixture never mix. Returns whether it loaded.
Future<bool> dbLoadIndexFixture(String json) => _run((d) => _loadIndexFixture(d.index, json), false);

bool _loadIndexFixture(Database index, String json) {
  if (index.select('SELECT 1 FROM translation LIMIT 1').isNotEmpty) return false;
  final m = jsonDecode(json) as Map<String, dynamic>;
  index.execute('BEGIN');
  try {
    for (final MapEntry(:key, :value) in (m['state'] as Map<String, dynamic>).entries) {
      _setState(index, key, value as Object);
    }
    final list = index.prepare('INSERT OR REPLACE INTO list (kind, id, lang, name, target, translate) VALUES (?, ?, ?, ?, ?, ?)');
    for (final r in m['lists'] as List) {
      final row = r as List;
      list.execute([row[0], row[1], row[2], row[3], row.length > 4 ? row[4] : 0, row.length > 5 ? row[5] : 0]);
    }
    list.close();
    final tr = index.prepare(
        "INSERT OR REPLACE INTO translation VALUES (?, ?, ?, '', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    final tag = index.prepare('INSERT OR REPLACE INTO translation_tag (story_id, pos, tag) VALUES (?, ?, ?)');
    for (final x in m['stories'] as List) {
      final s = x as Map<String, dynamic>;
      final id = s['id'] as String;
      final tags = s['tags'] as List;
      for (var i = 0; i < tags.length; i++) {
        tag.execute([id, i, tags[i]]);
      }
      for (final y in s['translations'] as List) {
        final t = y as Map<String, dynamic>;
        final b = t['band_words'] as List;
        tr.execute([
          id, t['lang'], t['sha256'], t['title'], t['subtitle'], s['level'], s['genre'], s['work'], s['part'], //
          s['author'], s['adapted'], s['license'], t['words'], b[0], b[1], b[2], b[3], //
          t['audio_ms'], t['opus_sha256'], t['opus_size'],
        ]);
      }
    }
    tr.close();
    tag.close();
    final arrival = index.prepare('INSERT OR IGNORE INTO arrival (story_id) VALUES (?)');
    for (final id in m['arrivals'] as List) {
      arrival.execute([id]);
    }
    arrival.close();
    index.execute('COMMIT');
    return true;
  } catch (_) {
    index.execute('ROLLBACK');
    rethrow;
  }
}

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

// ---------------------------------------------------------------- dict: form → lemma

/// Variants of a form, in lookup order (ARQ-61, ARQ-62): as
/// written, lowercase; on an elision, then only the part after the apostrophe.
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

/// Lemmas of a form exactly as written: entry with that word and
/// entries it is a form of. Own entry first.
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

/// Resolves a story's distinct forms in batch (ARQ-53).
Future<Map<String, List<EntryRef>>> dbLemmasOf(List<String> forms) => _run((d) {
      return {for (final f in forms) f: _lemmas(d.dict, f)};
    }, const {});

/// Lemmas of a form or expression ("si siede" → sedersi).
Future<List<EntryRef>> dbLemmas(String form) => _run((d) => _lemmas(d.dict, form), const []);

// ---------------------------------------------------------------- dict: entry

Future<Entry> dbEntry(EntryRef ref) => _run((d) {
      final rs = d.dict.select('SELECT data FROM entry WHERE word = ? AND pos = ? LIMIT 1', [ref.lemma, ref.pos]);
      if (rs.isEmpty) return Entry.nil;
      return parseEntry(rs.first['data'] as String);
    }, Entry.nil);

/// Parse at the boundary (ARQ-48): the JSON in `entry.data` becomes `Entry`.
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

// ---------------------------------------------------------------- dict: search

/// Lowercase and accent-free (ARQ-63), same as the pipeline's `*_norm` column.
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

/// Search suggestions (DIC-11, ARQ-63..65): lemmas and forms, accent- and
/// case-insensitive, with `?` and `*`. Order: exact match, NVdB band, alphabetical.
Future<List<SearchHit>> dbSearch(String query) => _run((d) {
      final q = normalize(query.trim());
      if (q.isEmpty) return const <SearchHit>[];
      final wild = q.contains('?') || q.contains('*');
      // GLOB: escapes the metacharacters the learner didn't type as wildcards.
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

/// "Did you mean" (ARQ-66): lemmas within 2 edits (OSA), by distance and band.
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
