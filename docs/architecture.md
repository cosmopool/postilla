# Postilla: architecture spec

How the app and the content pipeline are built. Behavior is in the [functional spec](functional-spec.md), and this spec only says how to implement it. Each decision has an id (`ARQ-03`) and a short reason.

Related documents:
- [functional-spec.md](functional-spec.md): what the app does.
- [dictionary.md](dictionary.md): entry fields and transformations.
- [dictionary-pipeline.md](dictionary-pipeline.md): how the dictionary is generated.

---

## 1. Overview

| Id | Decision | Reason |
|---|---|---|
| ARQ-01 | The app is built in Flutter, for iOS and Android. | One codebase for the two platforms the functional spec asks for. |
| ARQ-02 | The content pipeline is written in Zig 0.17. Dependencies come through Zig's package manager (`build.zig.zon`). | The pipeline reads the already-extracted kaikki.org JSONL and does not run wiktextract, so it does not need Python. The package manager pins each dependency by hash, with no other tool. Closes D23. |
| ARQ-03 | Three repositories: `postilla` (Flutter app and app docs), `postilla-content` (dictionary pipeline) and `postilla-backend` (story feed, drafts and the `.tilla` writer). | App, dictionary and stories have separate release cycles. The app gets new stories and a new dictionary without a new store version. |
| ARQ-04 | Every file the app downloads is in one public Cloudflare R2 bucket: `stories/…`, written by the backend, and `dict/…`, written by the `postilla-content` build. Every object is immutable except `dict/latest`, and none is ever deleted (handoff §2). | No token, no 404 for a file the feed or a `.tilla` named, and Cloudflare serves the bytes, not the backend's VPS. |
| ARQ-05 | Removed: content is no longer delivered through GitHub Releases (replaced by ARQ-04, 2026-11-13). The id is not reused. | — |
| ARQ-06 | The app has two base URLs built in: the API, `https://api.postilla.kaiodelphino.com` (Caddy in front of the backend), and the bucket, `https://content.postilla.kaiodelphino.com` (an R2 custom domain). Every download URL is the bucket base plus a key the app builds from a feed record or a `.tilla` (ARQ-20). There is no manifest. | Moving either host only needs a DNS change, not a new app version. Closes the backend's open question on where the app gets the bucket URL. |
| ARQ-07 | Whoever produces a format documents it, and the app follows it: `postilla-backend` defines the feed, the list bodies and `.tilla` (`docs/specification.md`, `docs/metadata.md`, `docs/tilla.md`, `docs/formats/*.ksy`); `postilla-content` defines `dict.db` and `dict/latest` (`CONTRACT.md`). What the app does with them is in the backend's `docs/app-handoff.md`, and this spec records how. | One owner per format. |
| ARQ-08 | [dictionary.md](dictionary.md) and [dictionary-pipeline.md](dictionary-pipeline.md) move to `postilla-content`. | The doc stays next to the code it describes. |

```
postilla-content (public)        postilla-backend                 postilla
  pipeline (Zig)                   drafts → .tilla writer            app (Flutter)
  dict.db ──► dict/<sha>.db.gz     stories/<id>/<lang>/… ──┐          seed (build)
              dict/latest ─────┐   GET /stories (FEED)     │          sync (section 3)
                               └──► R2 public bucket ◄─────┘ ───────► files
                                    API ─────────────────────────────► feed, lists
```

## 2. Content on the device

| Id | Decision | Reason |
|---|---|---|
| ARQ-10 | Two kinds of content, updated independently: the dictionary (one `dict.db`, the latest build) and stories (one `.tilla` per story and language, plus one `.opus` per narrated translation). | A new story does not download the ~21 MB of the dictionary, and a new dictionary does not touch a story. |
| ARQ-11 | `dict.db` arrives as `dict/<sha256>.db.gz` (gzip -9, ~21 MB) and a story as `stories/<id>/<lang>/<sha256>.tilla.gz` (deterministic gzip). The app checks the sha256 of the `.gz`, then keeps the file decompressed. The narration is `stories/<id>/<lang>/<opus_sha256>.opus`, kept as is. | `dart:io` already decompresses gzip, with no package. Decompressed files open without a step on each read. |
| ARQ-12 | `dict.db` has a SemVer version in `meta.version`: major changes when the schema becomes incompatible with old apps. Stories have no version: each body and each `.tilla` starts with its format version (handoff §9). | The major tells the app whether it can read the dictionary; the format version tells it whether it can read a file. |
| ARQ-13 | Each app build reads one major of `dict` and one version of each format (`FEED`, `GNRS`, `TAGS`, `AUTH`, `LANG`, `.tilla`). Anything else is not used: the app keeps what it has and shows the OFF-26 notice (ARQ-29). | Simple rule, checked without looking at anything but the version. The backend bumps a version only together with an app release that reads it. |
| ARQ-14 | The seed (OFF-10) is not in git. `content.lock` pins it: the feed cursor, every feed record at or below it for the default languages (`it`, `pt-BR`), with each translation's sha256 and `opus_sha256`, and the sha256 and size of `dict.db.gz`. `make seed` writes the lock from the live feed and `dict/latest`; `make fetch` downloads exactly those files from the bucket and checks them before `flutter build`. The list bodies (`GNRS`, `TAGS`, `AUTH`, `LANG`) are not files in the bucket, so `make seed` stores them next to the lock in the repo, a few KB (section 12). | No large binaries in the app repository. The lock makes the build reproducible. |
| ARQ-15 | Settings › About (OFF-13) shows the dictionary version and the date of the Wiktionary dump, read from the `meta` of `dict`, and the story count and stored cursor, read from the story index (ARQ-23). | The date tells the user when the dictionary is from; version, count and cursor identify the content in an error report. |

## 3. Content updates

Behavior in OFF-20..27; the app-side rules come from the backend's handoff (§1, §2, §6–§9). Flow:

```
Library visible (one sync at a time) ─► GET /stories?since=<cursor>&lang=<target>,<native>
  ─► group records by story id ─► per story: download every .tilla.gz into tmp/ ─► sha256 ─► gunzip ─► reader rules
  ─► one transaction: swap the story's rows, advance the cursor (ARQ-22) ─► delete superseded files
  ─► GET dict/latest ─► new sha? ─► download .db.gz (resumable) ─► size + sha256 ─► gunzip into staging ─► meta.version ─► swap live
  ─► ≥ 1 feed record? ─► GET /genres, /tags, /authors, /languages ─► replace the cached lists
```

| Id | Decision | Reason |
|---|---|---|
| ARQ-20 | The sync (OFF-20) runs in the database isolate (ARQ-31) with `dart:io`'s `HttpClient`, no package. It asks `GET /stories?since=<cursor>&lang=<target>,<native>` with the two ids exactly as `GET /languages` lists them (case-sensitive BCP 47). A file URL is `<bucket>/stories/<id>/<lang>/<sha256>.tilla.gz`, with `<id>` the UUID in written form and `<lang>` the record's 8-byte field with its zero padding stripped. A trigger while a sync runs is dropped, not queued. | The sync writes the story index, which lives in that isolate. Dropping the extra trigger keeps one path: the next Library visit syncs again. |
| ARQ-21 | Each `FEED` record is one translation: `id`, `lang`, `change`, `sha256`, `cursor`. `change` 1 (`published`) means download `sha256`; 2 (`removed`) means delete every translation of that story from the device. New and updated look the same: the app tells them apart by whether the id is in the index (ARQ-26). A `removed` record for an id the device doesn't have is ignored (they come in every sync, `since=0` included). Any other `change` value stops the sync like an unknown version (ARQ-29). A record whose sha256 equals the one on the device is already applied. | Follows handoff §2. The same-sha check makes re-applying after a crash a no-op. |
| ARQ-22 | The stored cursor is the highest cursor at or below which every record of the sync has been applied. A story that fails (download, sha, reader rule) is skipped for this sync: later stories still apply, but the cursor stops below its records, so the next sync returns them again. After a database restore on the backend, cursors may repeat for a while; the app does nothing special (handoff §2). Switching language (AJU-08) stores the new pair, sets the cursor to 0 and sets the resync flag: while it is on, a story without a file in the new language shows the BIB-12 dialog, and a sync that completes clears it. Files of the language left behind stay in the index and on disk, no longer updated. | Replaces "the app stores the largest cursor it received" (backend specification.md). A crash or a bad file never loses a record, and one bad story never blocks the others. After a switch, `since=0` returns every record of the new pair, and same-sha records cost nothing (ARQ-21). |
| ARQ-23 | The `stories` database is a writable local index the app owns (not a downloaded package). Tables: `translation` (key `story_id`, `lang`; `sha256`, `file`, and the header fields the card and Reader need: `title`, `subtitle`, `level`, `genre`, `work`, `part`, `author`, `adapted`, `license`, `words`, `band_words` ×4, `audio_ms`, `opus_sha256`, `opus_size`), `translation_tag` (`story_id`, `tag`; a story's tags are read in tag id order, BIB-01), `list` (`kind` genre · tag · author · language, `id`, `lang`, `name`, plus `target` and `translate` for languages) and `state` (`key`, `value`: cursor, language pair the cursor belongs to, dictionary sha256, new-stories count, unknown-format flag, resync flag) and `arrival` (`story_id` of each story that arrived through a sync and was not opened yet, for "Chegou agora", OFF-24). Files live beside it, named by sha so old and new never collide: `stories/<id>/<lang>/<sha256>.tilla` and `audio/<id>/<lang>/<opus_sha256>.opus`. Applying a story: download its translations into `tmp/`, check each, decompress, parse with the reader rules, move the files into place, then one transaction that upserts its rows and advances the cursor. Superseded files are deleted after the commit. At cold start, files the index doesn't name are deleted. | One transaction makes a story atomic (OFF-22) and ties the cursor to what was applied (ARQ-22). The Library reads cards from the index without opening a file. The cold-start sweep covers a crash between moving the files and the commit. |
| ARQ-24 | Dictionary (handoff §8): the app reads `<bucket>/dict/latest`, one ASCII line: the lowercase hex sha256 of the `.gz`, a space, its size in bytes. When the sha differs from the one in `state`, it downloads `dict/<sha256>.db.gz` (resumed with HTTP Range if interrupted), checks size and sha256, decompresses into a staging file and opens it read-only to check `meta.version` (ARQ-13). Then it swaps live (OFF-23): between two queries, the database isolate closes the old file, opens the new one, writes the new sha to `state` and deletes the old file. The form → lemma batch of an open story (ARQ-53) and the trie (ARQ-66) are thrown away and rebuilt on next use; an entry already on screen keeps its struct. | Words are looked up by form, so a new build never breaks a story. Staging costs ~90 MB until the swap. |
| ARQ-25 | First launch copies the seed in (OFF-11): `dict.db`, every seeded `.tilla` and `.opus`, the lists and the seed cursor. A later app version whose seed is newer is treated as a sync page: records above the stored cursor are applied like feed records, and its `dict.db` replaces the device's only if its `meta.version` is higher. | Updating the app from the store never takes content back to an older version, and the seed reuses the sync's apply code. |
| ARQ-26 | The new-stories count (OFF-24) is the number of story ids a sync applied that were not in the index before. In the same apply transaction it is added to `state` and each such id goes into `arrival`. The Library zeroes the count when the learner leaves it after the status line showed it (BIB-13); opening a story deletes its `arrival` row, and removing a story deletes it too. Applying the seed (ARQ-25) adds to neither. | The index says what is new without the app keeping a list of ids. Content updates never touch `user` (OFF-34). |
| ARQ-27 | Lists (handoff §7): `GET /genres`, `/tags`, `/authors` and `/languages` are refetched, all four, when a sync returned at least one feed record, and each replaces its cached rows in one transaction. A genre or tag name column is the language id lowercased with `-` turned into `_` (`pt-BR` → `pt_br`); the app stores names as (`id`, `lang`, `name`) rows, so a new language column needs no schema change. Unknown ids follow BIB-11. | A new genre, tag or author arrives with the first story that uses it. A rename alone produces no feed record, so it shows at the next sync that returns one, and that is accepted. |
| ARQ-28 | Narration (LEI-14, handoff §6): opening a narrated story whose `audio/<id>/<lang>/<opus_sha256>.opus` is missing downloads `<bucket>/stories/<id>/<lang>/<opus_sha256>.opus` in the background, checks `opus_size` and `opus_sha256`, and moves it into place. The Reader shows Play when the file is there. Applying a translation with a new `opus_sha256` deletes the old `.opus`; an edit that kept the audio keeps the file. Playback goes through the `audio` platform channel (ARQ-73): `load(path)`, `play`, `pause`, `seek(ms)` and a position stream. The Reader maps the position to a sentence by binary search over the `start_ms` values. | No audio bytes for a story nobody opens. Sentence times are milliseconds from the start of the decoded audio, so a position needs no conversion. |
| ARQ-29 | Every body and every `.tilla` is parsed at the boundary (ARQ-48), starting with its magic and version. An unknown version, or an unknown `change`, stops the sync and sets the unknown-format flag in `state`, which shows the OFF-26 notice in the Library's status line. A sync that completes with every format known clears it. 4xx bodies (a one-line English reason) only go to the log. A 429 keeps its `Retry-After` in the isolate's memory, and backend calls before that instant are skipped (OFF-27). Network errors are silent (OFF-05) and logged. | One parse function per format and one error path: the sync either applies a record or leaves it for the next sync. |

## 4. On-device databases

The databases of OFF-34: `user` (user data), `stories` (the local story index, ARQ-23), `dict` and `log` (ARQ-70). The schema of `dict` is defined in `postilla-content` (ARQ-07); `stories` is the app's own.

| Id | Decision | Reason |
|---|---|---|
| ARQ-30 | The app accesses SQLite through the `sqlite3` package (FFI), with hand-written SQL. | No code generation and no layer between the app and the SQL. |
| ARQ-31 | All queries, in all databases, run in a dedicated isolate. The UI receives the results by message. | `sqlite3` is synchronous. Outside the UI isolate, a slow query does not freeze the screen. |
| ARQ-32 | The `user` schema evolves through numbered SQL scripts (`001.sql`, `002.sql`…). `PRAGMA user_version` stores the last one applied, and each script runs in a transaction. Forward only. | Explicit migration, easy to review. |
| ARQ-33 | Every `user` record has a UUID v7 `id`, `created_at`, `updated_at` and `deleted_at`. Dates are integers in ms since the epoch, in UTC. `answer` has the same columns, but only receives inserts: there `updated_at` always equals `created_at`, and `deleted_at` is always 0 (ARQ-80). The local day (`answer.day`, `history.day`) is not a date in ms: it is the `localDay` of ARQ-84. | Ids unique across devices and comparable dates allow future sync without a model migration (OFF-31). |
| ARQ-34 | Removing a saved word or clearing the history fills `deleted_at`, and the lists filter those rows out. Neither touches `answer`: the removed word leaves Review through the ARQ-83 filter, and its answers stay in the log (REV-03). | Future sync knows what was removed. Removing does not erase what the learner already answered. |
| ARQ-35 | `user` never points to `entry.id`. A saved word is by lemma, as text (`"serranda"`), and also stores the part of speech of the entry where it was saved (`saved.pos`), which only decides which cards the saved word generates (D12). The history points to the entry by lemma + part of speech (`"binario"`, `"sostantivo"`). Answers point to lemma + part of speech and to the `rule.id` (ARQ-86). | `entry.id` changes with every `dict` build, and the lemma survives across versions. Outside the Reader the app does not know the tapped form, so the saved word is by lemma. Saving "binario" marks both "binario" entries (noun and adjective) as saved, but only the saved part of speech becomes a card (P05). The history has one row per entry (SAL-01), so it stores the part of speech. An entry that left `dict` falls under OFF-32. |
| ARQ-36 | Each story has a UUID, given by its first draft on the backend and carried in every `.tilla` header, which never changes. Progress, saved words and history point to that UUID. | Renaming or fixing the story does not break the link. |
| ARQ-37 | Progress points to the paragraph by position. If the story shrinks, progress goes to the last paragraph that exists (OFF-32); a saved sentence position is clamped the same way within its paragraph. The offset within the paragraph (LEI-07) is the index of the first visible character of the paragraph's text (its sentences joined by a space). | Position is the simplest. The character index survives changes in text size and rotation. An edit in the middle of the story shifts the progress, and that was accepted. |
| ARQ-38 | Settings live in a key-value table in `user`. Topics taken out of Review are also a setting, not a card column (ARQ-83). | They go into Export/Import (AJU-05) and future sync. |
| ARQ-39 | `dict` is opened read-only (`mode=ro&immutable=1`), and replaced as a whole file (ARQ-24). `stories` is a normal read-write database in WAL mode, written only by the sync. | `dict` needs no WAL or lock and gets no accidental writes. The index changes with every applied story. |

Tables of `user` (in addition to the ARQ-33 columns):

| Table | Fields | Requirements |
|---|---|---|
| `progress` | `story_id`, `paragraph` (position), `offset` (character), `status` (in progress \| read), `last_opened_at`. With no row, the story is new. | BIB-02, BIB-03, LEI-07 |
| `history` | `day` (`localDay`, rollover at 4 a.m., ARQ-84), `lemma`, `pos`, `story_id` (`''` outside a story), `origin` (0 story or search · 1 Review; open, section 12). Unique on `day` + `lemma` + `pos`. | SAL-01, D29, D30 |
| `saved` | `lemma` (text, unique key), `pos` (part of speech of the entry where it was saved: only it generates cards, D12), summary (part of speech, source story), `story_id`, `paragraph` and `sentence` (positions of the source sentence; they also open the excerpt page, D22), `form` (tapped form; `''` = no source sentence, as when saved from search). | SAL-02, OFF-32, LEI-10, REV-03 |
| `answer` | The insert-only log of Review and Practice answers (ARQ-80). Columns in the table below. | REV-17, TRE-05 |
| `setting` | `key`, `value` (JSON): reading, Immersion, translation ratio, Saved sort order, hints seen, target and native language ids (AJU-08), Settings › Review (new words per day, origin) and topics taken out of Review. The new-stories count lives in the `stories` index, not here (ARQ-26). | OFF-30, AJU-07, AJU-08 |

Columns of `answer`, in addition to those of ARQ-33. Every column is `NOT NULL`, and zero (`0` or `''`) means "none".

| Column | What it stores |
|---|---|
| `at` | Instant of the answer (ms, UTC), the one that counts for FSRS. A row with `replaces` inherits the `at` of the replaced row (section 12) |
| `day` | `localDay` of the answer (ARQ-84): `20261016` |
| `replaces` | Id of the row this one replaces (ARQ-80) |
| `kind` | 0 word card · 1 pattern card |
| `rule` | `kind` 1: the card; `kind` 0: the member's pattern; `''` in Word |
| `lemma`, `pos` | `kind` 0: the card's word; `kind` 1: the current word |
| `skill`, `tense`, `person` | Fixed enums of ARQ-86. `tense`: 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo |
| `cue` | Curated item: the question of the `drill` row (`le chiavi ___`) |
| `format` | 0 typed · 1 choice |
| `verdict` | 1 intro · 2 known · 3 void · 4 wrong · 5 dontKnow · 6 almost · 7 ok |
| `reason`, `hinted` | Reason for the notice, the Almost or the Wrong; whether the hint was used |
| `mode` | 1 Review · 2 Practice. Only for the quotas and for auditing: no FSRS rule looks at the door |
| `origin` | Only on a word `intro`: 1 saved · 2 NVdB |
| `typed`, `elapsed_ms` | What was typed (up to 64 characters) and the time until answering |

- **Card key:** `kind` 1 → `rule`; `kind` 0 → `lemma·pos·skill·tense`. In Dart, an `extension type CardKey` (ARQ-47). The `cue` is not part of the key.
- **Indexes:** `(kind, rule, lemma, pos, skill, tense, at)` for the per-card fold, `(day)` for the quotas and a partial `(replaces)`, only where it is not `''`.
- **Size:** with 100 answers a day, ~36 thousand rows and ~3.5 MB a year (section 12).
- The Review book planned `review_card`, `review_log`, `known_word` and `word_image`. None of them is used: the state comes from the log (ARQ-81), "Já sei" is a `known` row and images were left for after v1 (D24).

## 5. Flutter app

The app and pipeline code follows the Core Principles of [AGENTS.md](../AGENTS.md). The naming conventions there do not apply here (ARQ-95). The decisions below say how some of them become concrete choices.

| Id | Decision | Reason |
|---|---|---|
| ARQ-40 | There are no layers between the screen and the SQL. The `db` module has one function per query (`dbSavedList`, `dbProgressSet`…), which sends the SQL to the isolate (ARQ-31) and returns structs. The screen calls those functions directly. There is no repository, use case or interface. | Less code and fewer concepts. You can follow a screen action down to the SQL in the debugger. |
| ARQ-41 | Each screen's state lives in the `State` of its own `StatefulWidget`. A separate state class only appears where sharing state between screens is needed, case by case. | Flutter already provides `State`, so no new concept per screen. |
| ARQ-42 | Settings that apply to the whole app (theme, reading, Immersion) live in an immutable `Settings` struct, in a `ValueNotifier<Settings>` at the root, exposed through `InheritedNotifier`. Changing a setting writes to `db` and swaps the value. | A single global state, with what Flutter already has. Theme and Immersion change right away (LEI-08, AJU-03). |
| ARQ-43 | After popping a screen, the screen left underneath rereads the saved words (`await` of the push). There is no global set of saved words. | One indexed query solves SAL-05, with no shared state to keep in sync with the database. |
| ARQ-44 | Navigation is done by hand: an `IndexedStack` with one `Navigator` per tab, and the root `Navigator` for the Reader, the Reader's entry and the full-screen Review or Practice session. Android back goes through `NavigatorPopHandler`. | No package and no route table. The push goes straight to the widget, with typed arguments. The app has no deep links. |
| ARQ-45 | One folder per screen (`library/`, `reader/`, `dictionary/`, `review/`, `settings/`), plus `db/` and `ui/` (design system components). Review and Practice share `review/`, because they use the same generator and the same grading. The sync, the `.tilla` and list parsers and the story index live in `db/`, next to the isolate that runs them (ARQ-20). | Whoever works on a screen finds everything for it in a single folder. |
| ARQ-46 | Interface texts follow the pattern abstract class + one class per language + swappable global, with one class per Immersion area that has text: `NavStrings nav`, `UiStrings ui` and `DictStrings dict`, each with a `Portuguese` and an `Italian` version. When Immersion changes, the app swaps the globals and then notifies the `ValueNotifier<Settings>`. The Glosses area has no text: it only decides whether the gloss appears. Rule names and texts are not a class: they come from `dict` in PT and IT (`rule.name_*`, `rule.text_*`), and the app picks the column by the Labels and buttons area (D14). | No code generation. The compiler prevents using a text from the wrong area. |
| ARQ-47 | Ids and units have distinct types, made with `extension type` (`StoryId`, `ParagraphIndex`, `CharOffset`, `WordKey`…). | The compiler prevents mixing a `StoryId` with any `String`, with no runtime allocation. |
| ARQ-48 | The SQLite row and the entry JSON (`entry.data`) become a struct in the database isolate, which sends the finished structs to the UI. | Parse at the boundary: the UI never sees a raw row or JSON, and parsing the entry does not weigh on the UI isolate. |
| ARQ-49 | A `db` function never returns `null` or throws an exception. If it finds nothing or fails, it returns the zero value: a const sentinel (`Story.nil`, `Entry.nil`) or an empty list. The failure goes to the log (ARQ-70). | The caller has a single path, with no `if (x == null)` or `try/catch` in the screen. |

```
Root Navigator
 ├─ Shell: IndexedStack + tab bar
 │   ├─ Library Navigator
 │   ├─ Dictionary Navigator   (tab entries, up to 20, DIC-06)
 │   ├─ Review Navigator       (root → topic → rule, D5)
 │   └─ Settings Navigator
 ├─ Reader                     (push on root, no bar)
 ├─ Reader entry               (push on root, no bar)
 └─ Session (Review or Practice) (push on root, no bar)
     ├─ Session entry          (goes into History with origin Review, D29)
     ├─ Session rule           (no "Treinar")
     └─ Story excerpt          (paragraph only, no Reader; does not save progress, D22)
```

```dart
NavStrings  nav  = NavPortuguese();
UiStrings   ui   = UiPortuguese();
DictStrings dict = DictPortuguese();

Text(nav.library)
Text(dict.synonyms)   // Sinonimi | Sinônimos
```

## 6. Reader

| Id | Decision | Reason |
|---|---|---|
| ARQ-50 | The backend's worker splits the text into paragraphs, sentences and words and writes them to each `.tilla`: every sentence is its own text with its word spans, in every language. Elisions (l'aria, c'è) are a single word. Only the target language's spans are tappable (handoff §5). Spans count UTF-8 bytes of the sentence text; Dart indexes a `String` in UTF-16 units, so the parse builds a byte → index table once per sentence (one unit per UTF-8 lead byte, two for a 4-byte sequence) and stores the spans as `String` indices. | A single tokenizer, in the backend, the same rule as `dict`'s forms (backend CONTRACT.md). The word counts of LEI-07 and the sentence pairs of TRA-08 come out ready. The table costs ~0.1 ms for a 5,000-word story and gives the indices the highlight needs; decoding each word separately is ~3× slower. |
| ARQ-51 | Each paragraph is its own `RenderBox` with a `TextPainter`. It does the layout, keeps each word's rectangle in an array, resolves tap and selection drag by the nearest rectangle (enlarged box), paints the highlight, the marked sentence and the dotted underline, and creates one semantics node per word. | The Reader is the center of the app: what matters stays big and in one place. No widget or recognizer per word, and semantics stays under control (ACE-03, ACE-04). |
| ARQ-52 | All paragraphs are laid out when the story opens, in a non-lazy column. The top of each paragraph is kept in an array. | With stories of up to ~2,000 words, the cost is acceptable. Progress (LEI-07), restoring the position (ARQ-37) and syncing the split screen (TRA-07) become a binary search on that array. |
| ARQ-53 | When the story opens, the app resolves form → lemma in a batch: one query on `dict` with the distinct forms of the target-language file. The lemmas live in an array parallel to the word spans and serve tapping (LEI-02) and the dotted underline (SAL-05). The app never stores `entry.id` (ARQ-35). | A single query per story. A `.tilla` never names a dictionary entry, so a new `dict` never breaks a story, and the content stays without lemma annotation (LEI-02). |
| ARQ-54 | A word gets a dotted underline when any of the form's lemmas is saved. With "serranda" saved, "serrande" is underlined. With "portare" saved, every "porta" in the text is underlined, even when it is the noun. | Without lemma annotation, the app does not know the sense of the word in the text. The rule never fails to underline a saved word, and accepts underlining too much in ambiguous forms. |
| ARQ-55 | Progress is saved when scrolling stops, when pushing an entry and when the app goes to the background. | Few writes and none during the gesture. Covers LEI-07, including the system killing the app with an entry open. |
| ARQ-56 | In split screen (TRA-07), the leading half reports the top paragraph and the fraction of it already scrolled. The other half scrolls to the same paragraph and the same fraction. | Follows smoothly within the paragraph, even with Italian and Portuguese at different heights. |

## 7. Dictionary

| Id | Decision | Reason |
|---|---|---|
| ARQ-60 | A tap looks up only the tapped word. In "si siede", tapping "siede" opens *sedere*. *sedersi* opens through the expression (press and drag over "si siede", LEI-03) or through search. | A single rule for tapping, without looking at the neighboring word. |
| ARQ-61 | An elision is looked up first whole and then only the part after the apostrophe. "c'è" finds the phrase, if `dict` has it, and otherwise goes to "è" → *essere*. "l'aria" does not exist whole and goes to "aria". | Finds phrases with elision when they exist and falls back to the main word when they don't. All in the ARQ-53 batch. |
| ARQ-62 | A form is looked up in `form.form` as written and, with no result, in `form.form_norm` (lowercase, no accents) (handoff §5). Every lemma the matching rows lead to is a candidate (LEI-02). "Bologna" finds the proper noun, and "Il" at the start of the sentence goes to "il". If both exist ("Rosa" and "rosa"), the exact spelling wins. | Proper nouns in `dict` are capitalized, and so is the word at the start of a sentence. The normalized column already exists for search (ARQ-63). |
| ARQ-63 | Search (DIC-11) ignores accents and case: "citta" finds "città". `dict` has a normalized column (lowercase, no accents), indexed, on `entry.word` and on `form.form`. Search queries both tables and merges the results. | The Portuguese keyboard does not always have à and ù at hand. |
| ARQ-64 | Suggestions come in this order: equal to what was typed, then by frequency (NVdB: fondamentale → alto uso → alta disponibilità → rest), then alphabetical. `dict` stores in each `entry` this rank and the NVdB band (0 outside · 1 fondamentale · 2 alto uso · 3 alta disponibilità). | "casa" and "caso" come before "casella". Review uses the band to know what is "among the most common" and the rank for the order of new NVdB words (D26); Practice, for the words outside the learner's own. The rank alone does not say where the NVdB ends. |
| ARQ-65 | Wildcards (`?` one letter, `*` several) become a `GLOB` over the normalized column. | SQLite's `GLOB` already uses those two wildcards. |
| ARQ-66 | "Você quis dizer" uses a trie of the normalized lemmas, walked with the rows of the OSA distance (`osa()`, ARQ-85: Levenshtein where swapping two adjacent letters counts as 1 edit) and pruned above 2 edits. OSA keeps the previous row and the one before it. Candidates are sorted by distance and then by the ARQ-64 rank. The trie is built in the database isolate on first use and stays in memory until the app closes. | No new data in `dict` and no SQLite extension. Catches up to two errors in any position, and *finsetrino* for *finestrino* counts as a single error. A single distance in the app, the same as in grading. Opening the app does not pay for the build. |

The current `dict` does not have the normalized column (ARQ-63), the NVdB rank and band (ARQ-64), the practice features in `entry.data`, or the `rule` and `drill` tables (ARQ-86, ARQ-87). All of them are change requests to the `postilla-content` contract (ARQ-07), listed in section 10.

## 8. System integrations

### Diagnostics

| Id | Decision | Reason |
|---|---|---|
| ARQ-70 | The app log (`appLog`) is written to a fourth database, `log`, separate from `user`. It is not part of Export/Import (AJU-05) or of the system backup. In v1, `appLog` only writes to the console; the `log` database comes in v1.1, with Send diagnostics. | A corrupted `user` does not take the log down with it, and the log does not mix with the user data. |
| ARQ-71 | `log` keeps the last 30 days. Older rows are deleted on write. | Covers the usual gap between a problem and the user deciding to report it. |
| ARQ-72 | The log only leaves the device if the user sends it: Settings › About › Send diagnostics (AJU-06) opens the system email with the `log` attached. | No telemetry (OFF-03). The user sees the email before sending it. |

### System

| Id | Decision | Reason |
|---|---|---|
| ARQ-73 | Everything the app asks of the system goes through its own platform channel, in Swift and Kotlin: narration audio (ARQ-28), TTS, email, share sheet, file picker and opening a URL. No plugin packages. On Android the `audio` channel plays with ExoPlayer (Media3); on iOS, with `AVAudioPlayer`/`AVPlayer`, whose Ogg Opus support is still to be checked on a device (section 12). | A single mechanism for the system, with no dependencies, and each native call stays visible in the code. |
| ARQ-74 | Pronunciation (OFF-40) uses `AVSpeechSynthesizer` on iOS and `TextToSpeech` on Android, with an `it-IT` voice. The channel lists the voices with each system's offline flag. With no offline Italian voice, the button is disabled (OFF-41). | The system voice works without a network. |
| ARQ-75 | The email of Report error (LEI-09) and Send diagnostics (AJU-06) opens through the channel: `MFMailComposeViewController` on iOS and `Intent.ACTION_SEND` with an attachment through `FileProvider` on Android. On iOS with no account in the Mail app, the app warns that it needs a configured email app. | A `mailto:` link does not attach a file, and diagnostics need the attachment. A single mechanism for both emails. |
| ARQ-76 | The exported file (AJU-05) and the diagnostics attachment (ARQ-72) are generated with `VACUUM INTO` into a temporary file, deleted after sharing. | A consistent, compact copy with the database open, with no pending WAL or deleted rows. |
| ARQ-77 | `user` writes a fixed Postilla `PRAGMA application_id`. On import, the app opens the file read-only, checks the id, accepts a `user_version` lower than or equal to its own and runs the missing migrations (ARQ-32). A file from a newer app is refused with a notice. | Refuses any SQLite that is not Postilla's and accepts exports from old versions. |
| ARQ-78 | Before importing, the app keeps a copy of the current `user` (`VACUUM INTO`) in the app folder. Only the latest one stays, replaced on each import. Undo swaps `user` for it. | Covers the AJU-05 undo without the space growing. |
| ARQ-79 | Only `user` goes into the system backup (OFF-33). `dict`, `stories` with its story and audio folders, `tmp/`, the staging file, `log` and the undo copy stay out (`NSURLIsExcludedFromBackupKey` on iOS, backup rules on Android). | Content comes back from the seed and the next sync, and the user's iCloud does not get ~90 MB. Android Auto Backup has a 25 MB limit. |

## 9. Review and Practice

Behavior in the `REV-` and `TRE-` requirements of the functional spec, based on the [Review and Practice proposal](propostas/revisao-treino.md) and the [decisions](propostas/revisao-treino-decisoes.md) (cited as **Dn**). One log, one fold, one generator, one grading and two doors: in Review the app picks the cards; in Practice, the learner picks the topic.

```
dict (read-only)                        user
  entry.data: article, plural, conj       saved ── lemma + pos + source sentence
  rule: pattern catalog                   answer ── insert-only log
  drill: members and curated items           │
     │                                       ▼
     └──► exercise generator ◄──── log fold in the isolate (FSRS, weakness, quotas, repeats)
                  │
        Review door · Practice door
                  │
            grade() ─► INSERT into answer
```

| Id | Decision | Reason |
|---|---|---|
| ARQ-80 | Answers live in the `answer` table of `user`, insert-only: no row changes or is deleted. "Contar como certa" writes `ok`, "Desfazer" writes `void` and "Já sei" writes `known` (undone by a `void`). The row that corrects or undoes another points to it in `replaces` and inherits its `at` and `day` (section 12). A row is effective when no effective row replaces it: read from newest to oldest, a `void` cancels the row it replaces, and the previous one counts again. Skip and Ambiguous (G5) write nothing. | P08, P09. The log is the source of truth, and future sync only adds rows, with no edited-row conflict (OFF-31). Undo is a single case: one more row. |
| ARQ-81 | State is a fold of the log, done in the database isolate (ARQ-31) and kept in memory: FSRS state of each card (S, D, lapses, due date), weakness of each pattern (ARQ-89), the day's quotas, the repeats queue, introduced words and "Já sei". The fold reads the effective rows in `(at, id)` order when Review or Practice opens. A new answer is applied only to its card; one that replaces another rebuilds the card from its rows. Nothing from the fold is stored. | P08. No mutable column to keep in sync with the log. Changing the algorithm or the grade table recomputes everything, with no migration. The repeats queue comes from the log and survives the app being killed. Estimated cost in the tens of ms, ~0.3 s with 5 years of use, to be measured (section 12). |
| ARQ-82 | Scheduling is FSRS-6 (21 parameters) as in Anki. Every effective answer in the card's own format, from any door (Review, repeats, reinforcement, Practice), updates S and D: the first of the day is a normal review, with the real days since the previous one (early, if the card was not due); the others on the same day use the FSRS-6 short-term formula. The first counted answer creates the card, with initial S and D (D9). The lapse counter goes up only on the first Again of the day of a card in review. The card's format comes from `skill` (choice in `genere`, typed in the others); Practice's form choice does not count (D2b), nor do `intro`, `known` and `void`. The grade comes from `(verdict, reason, hinted, format)` through a table in the code. The interval is in whole days, at least 1, with Anki's fuzz on a fixed seed (ARQ-88). | D2, D2b. A single rule, with no `if` per door. As in Anki, the behavior is known and can be checked against the reference implementation. The grade is not stored, so changing the table needs no migration. |
| ARQ-83 | An active card is a filter, never a column. A card is active when the source exists (saved word with `deleted_at = 0` and the card's `pos`, or NVdB word introduced by Review; pattern with some answer and `rule.retired = 0`), the card exists in `dict` (`entry` or `drill` row), the lemma is not in "Já sei", the topic was not taken out of Review (`setting`) and, only at the Review door, the card is unlocked. `user` attaches `dict` read-only (`ATTACH 'file:…?mode=ro&immutable=1'`) to join `saved` and `drill` in one query; the rest comes from the fold. | Suspending, removing and taking out a topic do not edit or delete any answer (OFF-34, REV-03). An entry or pattern that leaves `dict` disappears from Review on its own, as in OFF-32. An NVdB word answered only in Practice does not pass the source check and never becomes due in Review (D9). |
| ARQ-84 | A single day, the `localDay`: the device's local date with the rollover at 4 a.m., as an integer `AAAAMMDD` (`20261016`). It applies to `answer.day`, `history.day`, the quotas, the FSRS "same day" and the due date (due = `due ≤ today`). It is written at the time of the row and never recomputed: changing time zone does not move old answers. | D30. It is Anki's default rollover: someone reviewing at midnight does not get a new day in the middle of the session. One day concept, not two. |
| ARQ-85 | Grading is a single function, `grade()`, at both doors: it takes the exercise and what was typed or tapped and returns `verdict` and `reason`, by rules G1–G9 and the per-skill table of the proposal. It runs in the database isolate, because G2 and G5 look up what was typed in `dict` (form → lemma → gloss) and G4 compares by the normalized column (ARQ-63). G6's "one letter different" is measured by `osa()`, the OSA distance, which ARQ-66 now also uses. | One generator and one grading for Review and Practice. A single distance in the app: *finsetrino* is one error, not two. |
| ARQ-86 | The pattern catalog is the `rule` table of `dict`, generated from `rules.toml` in `postilla-content` (D14). The `rule.id` (`pl.co_go`) is the pattern card key: append-only, never renamed or removed. A pattern that is dropped gets `retired = 1`; a pattern that is split gets new ids, and the history starts over on them. `position` is the *Dai! 1* order in which Review introduces the patterns (D4) and the order within the topic. The enums `skill`, `tense` (with the imperative as 5) and `person` have fixed values after v1, with Italian names, and only get additions. | D1: renaming an id would erase the learner's history. A rule's text is fixed in a content patch, with no new app version and no per-pattern `switch` in the code. |
| ARQ-87 | `drill` is the membership index: one row per noun × skill (`genere`, `articolo`, `plurale`, `preposizione`), per verb × tense (plus one for `imper.neg`) and per curated item, each with its own `rule`. In the curated items (`accordo`, `possessivo`, `piacere`), the row carries the question (`cue`) and the answer (`answer`); in the others, the answer comes from `entry.data` (`plural`, `article*`, `conj`). `user` never stores `drill.entry_id` (ARQ-35): the card is `lemma·pos·skill·tense` or the `rule.id`. | The generator has one case per skill and reads the curated items from their own row. The app does not decide who is a member of which pattern: the pipeline classifies once, at build time (section 10). |
| ARQ-88 | No choice in selection or in the generator uses `Random`. Batch tie-breaks, current word, person asked, order of the options in choices and Practice's weighted draw come from `fnv1a32` over the card key and the `localDay` (plus the item position, in Practice). The FSRS fuzz uses `fnv1a32(card + reps)`. | State and batch are a function of the log and the day: the same log on the same day always gives the same batch. Tests (ARQ-90, ARQ-93) stay reproducible with no injected seed. |
| ARQ-89 | Each pattern's weakness is computed in the same fold, by the formula below. A pattern's target is the answers of the pattern card (`regra`) or of the member cards (`lista`), from any door, including form choice, with weight 0.5 (D2b). Vocabulary has no weakness in v1 (D25). | FSRS retention says whether the learner remembers now; weakness says how much they get right. A pattern reviewed yesterday has high retention even when half the answers are wrong. The thresholds are assumptions, to be tuned after the simulation (section 12). |

```
for each effective graded answer whose target is pattern p:
  w   = 0.5 ^ (age_days / 30)                -- age in localDay; 30-day half-life
        × (0.5 if choice, 1 if typed)
  bad += w   if Again (Wrong, Don't know)
  ok  += w   if Good or Hard
  n   += 1

weakness(p) = (bad + 1) / (ok + bad + 4)      -- Beta(1, 3) prior: 25% error with no data
weak(p)     = n >= 5  and  weakness(p) >= 0.35
weakest     = the weak one with the highest weakness; tie-break by lowest FSRS retention, then by id
```

## 10. Pipeline

The dictionary pipeline and its contract live in `postilla-content`; the story formats live in `postilla-backend` (ARQ-07, ARQ-08). This section only lists what the app requires from them, with the decision that asks for each item.

| Where | The app requires | Requested by |
|---|---|---|
| `dict` | One SQLite file, `dict/<sha256>.db.gz` (gzip -9) in the public bucket, and the `dict/latest` pointer, uploaded after the file | ARQ-11, ARQ-24 |
| `dict` | SemVer `meta.version`, with major = incompatible schema | ARQ-12 |
| Backend | `GET /stories?since=&lang=` (`FEED`) with per-translation records, `change` and a cursor shared by every translation | ARQ-20..22 |
| Backend | `GET /genres`, `/tags`, `/authors`, `/languages` (`GNRS`, `TAGS`, `AUTH`, `LANG`) | ARQ-27, AJU-08 |
| Backend | 429 with `Retry-After` once rate limiting ships | ARQ-29 |
| `.tilla` | Fixed UUID per story | ARQ-36 |
| `.tilla` | Title, subtitle, level (1–6), genre, tags, work and part, author, adapted, license, words, `band_words`, `audio_ms`, `opus_sha256`, `opus_size` | BIB-01, LEI-10, LEI-13, LEI-14 |
| `.tilla` | Per sentence: text, word spans in UTF-8 bytes, `start_ms` and `end_ms`; paragraph and sentence counts equal across a story's translations | ARQ-50, TRA-08, LEI-15 |
| Bucket | Every file immutable and never deleted; the `.opus` keyed by its own sha256 | ARQ-04, ARQ-28 |
| `dict` | `meta` with the version and date of the Wiktionary dump | ARQ-15 |
| `dict` | `entry.word` and `form.form` with the original spelling (capitals and accents) | ARQ-62 |
| `dict` | Normalized column (lowercase, no accents), indexed, on `entry.word` and on `form.form` | ARQ-63 |
| `dict` | Frequency rank per `entry` (NVdB) | ARQ-64 |
| `dict` | Forms with clitic in `form` ("si siede" → *sedersi*) | ARQ-60, DIC-01 |
| `dict` | NVdB band per `entry` (0 outside · 1 fondamentale · 2 alto uso · 3 alta disponibilità) | ARQ-64, REV-02 |
| `dict` | In `entry.data` of nouns: `gender`, `article`, `article_indef`, `article_pl`, `plural` (list; invariable = the word itself) and `plural_src` (`wikt` · `enwikt` · `morphit`). Nothing generated by rule: with no source, the field stays empty. The article comes from the gender and the initial sound, with an exceptions file | ARQ-87, D15, D19 |
| `dict` | In `entry.data` of verbs: `conj_class` (`group`, `isc`, `pronominal`, `aux`) and flat `conj` (`tense`, `person`, `forms`), with the imperative as `tense` 5 | ARQ-87, D11e |
| `dict` | `rule` table, generated from `rules.toml`: append-only `id`, `skill`, `type` (regra · lista), `level`, `position`, `neighbor`, `name_pt/it`, `text_pt/it`, `examples` ("lemma right wrong" lines) and `retired` | ARQ-86, D1, D14 |
| `dict` | `drill` table: `entry_id`, `skill`, `tense`, `rule`, and `cue` and `answer` in the curated items. Members cut by the A1 lists of `rules.toml` | ARQ-87, D11c |
| `dict` | Curated items of `accordo`, `possessivo` and `piacere` and the kinship list of `poss.famiglia`, written in `rules.toml` and checked against the dictionary (gender, number, adjective form) | ARQ-87, D11e |
| `dict` | `meta` with license and attribution of the new sources (en.wiktionary for the features; Morph-it!, if it comes in) | AJU-04, D19 |
| Pipeline | Report of disagreements between the sources on each build, outside the package, for manual review | D19 |
| Pipeline | The build fails if a `rule.id` of the previous published version disappears from `rules.toml` | ARQ-86 |

## 11. Build, CI and tests

| Id | Decision | Reason |
|---|---|---|
| ARQ-90 | Tests are integration tests: they start from the UI (`flutter_test`, driving the widgets) and use real SQLite, one temporary file per test. Only HTTP calls and IO errors are simulated: sync tests run against a local fake server that serves recorded `FEED` and list bodies and files from the seed, including bad sha256s, unknown versions, 429s and dropped connections. | Tests the app as it runs, with no mock of an internal layer, since there are no layers (ARQ-40). |
| ARQ-91 | Unit tests only for heavy logic (Library sorting, the ARQ-66 trie, `grade()` and `osa()`, FSRS-6 and the log fold, and the like). Each one also gets an integration test that goes through it. | The unit test covers the hard cases of the logic. The integration test checks that it works wired to the rest. |
| ARQ-92 | For now there is no on-device end-to-end test (`integration_test`). | Running an emulator or device in CI is slow and expensive for v1. |
| ARQ-93 | Tests use the production seed pinned by the build lock (ARQ-14): the same `dict.db`, `.tilla` and `.opus` files. There is no test content. Updating the lock runs the tests against the new content, and the bump only goes in with the tests passing. | Mock as little as possible. The test sees exactly the data the user sees. |
| ARQ-94 | The app CI runs on GitHub Actions, on Linux, on every push and PR: it downloads the lock packages, runs `dart analyze` and `flutter test`. Store builds stay out of CI for now. In v1 there is no CI: `dart analyze` and `flutter test` run on the machine. CI comes in v1.2. | Catches analysis and test errors before the merge, with no macOS runner. |
| ARQ-95 | The analyzer uses the default `flutter_lints`, with no tweaks. Names follow Dart style. | No custom rules to maintain. |
| ARQ-96 | Until sync fills the index, Android has two flavors: `dev` bundles a story fixture (`assets/dev/index_fixture.json`, written by `tool/make_index_fixture.dart` from the Library book's catalogue and the real stories) and loads it into an empty index; `prod` ships without it and starts empty. `make run` uses `dev`. iOS has no `dev` scheme yet, so an iOS run starts empty. The fixture, its loader and the flavors go away when the seed (ARQ-25) fills the index. | The UI can be built and seen with realistic data while the backend publishes nothing, and no release build carries invented stories. |

## 12. Open decisions

Review left this section: its architecture is in section 9 (ARQ-80…89). What remains are its technical open items, from section 12.2 of the [proposal](propostas/revisao-treino.md), and the ones that came up while writing section 9. The content open items (sources, disagreements, Morph-it! license) are in the open decisions of [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto).

| Topic | What is missing | Recommendation |
|---|---|---|
| Reader semantics | ACE-03 asks for reading by paragraph and each word as a button. How the RenderBox (ARQ-51) builds the semantics nodes to meet both can only be validated on a device, with VoiceOver and TalkBack. | — |
| Requests to `postilla-content` | The section 10 `dict` items it does not have yet need to be accepted there: NVdB rank (ARQ-64), practice features in `entry.data`, `rule` and `drill` (ARQ-86, ARQ-87). The normalized columns and the band are already in CONTRACT.md. | — |
| Ogg Opus on iOS (ARQ-28, ARQ-73) | Android plays Ogg Opus natively. Whether `AVAudioPlayer`/`AVPlayer` play an Ogg Opus file on the iOS versions the app supports is unverified. Options: (a) check on a device and, if it works, nothing changes; (b) the backend also publishes a CAF/M4A copy for iOS; (c) decode with a vendored libopus in the channel. | Check on a device first. If it fails, (b): the backend already encodes from PCM, and the app keeps one channel API. |
| List bodies in the seed (ARQ-14) | `GNRS`, `TAGS`, `AUTH` and `LANG` are API responses, not bucket files, so the lock can't pin them by key. Options: (a) `make seed` stores the four bodies in the repo next to the lock (a few KB); (b) `make fetch` asks the API at build time, unpinned. | (a): the build stays reproducible, and the tests (ARQ-93) see fixed names. |
| `stories` index schema | The index is the app's own database (ARQ-23), so it needs migrations too. Options: (a) numbered scripts like `user` (ARQ-32); (b) on a schema change, drop the index and every file, reset the cursor to 0 and resync. | (a): (b) loses every story offline until the next sync, which breaks OFF-01. |
| A `dict` of another major (ARQ-13, ARQ-24) | `dict/latest` carries no version, so the app learns the major only after downloading ~21 MB, and would do it again on every sync. | Remember the rejected sha in `state` and skip it until `dict/latest` changes. |
| zstd (ARQ-11) | The roadmap had zstd for v1.2, but the delivery format is now `postilla-content`'s (gzip -9, CONTRACT.md). | Drop zstd from the app's plans; reopen it only as a contract change in `postilla-content`. |
| Load and weakness numbers (D7) | Batch of 20, quotas 5 · 2 · 1, brake at 60, 2 repeats and the ARQ-89 thresholds (30 days, Beta(1, 3), n ≥ 5, 0.35, weight 0.5) come from assumptions. The old simulation was FSRS-4.5 with a different design and does not hold. | Constants in a single place in the code; settle the numbers after the proposal's FSRS-6 simulation (9.3). |
| FSRS-6 parameters | "Same as Anki" (D2) does not say whether the 21 parameters are the defaults or optimized per learner, nor the desired retention. Options: (a) default parameters and retention 0.9, fixed; (b) on-device optimizer, from the log, after N answers. | (a) in v1. The log keeps everything, so the optimizer can come in later and recompute the fold with no migration. |
| Anki learning steps | Anki uses steps in minutes for new cards and for lapses. Here, the session repeats (D21) play that role. Options: (a) no steps: interval in whole days, minimum 1, due date by `localDay`; (b) imitate Anki's steps in minutes. | (a): it is what ARQ-82 and ARQ-84 describe, and D21 already sends the card to tomorrow after 2 repeats. |
| Checking "same as Anki" | Without a test, the app's FSRS can diverge from Anki's without anyone noticing. | Unit test (ARQ-91) with vectors generated by the reference implementation (fsrs-rs or py-fsrs): same sequence of grades and dates, same S, D and interval. |
| Fold cost (ARQ-81) | Estimated, not measured. Options if it gets slow: (a) accept it; (b) a derived cache in a separate file, disposable and out of the backup, like `log`; (c) state snapshots in `user`, which goes back to P08. | Measure on a basic Android device with a synthetic 5-year log. If opening goes over ~200 ms, (b). |
| `answer` size × backup | ~3.5 MB a year with 100 answers a day. Android Auto Backup has 25 MB (ARQ-79): a diligent learner goes over the limit in ~6 years. | Accept in v1. If it gets close, shorten `typed` or compact old rows into a separate file. |
| `at` of the replacing row (ARQ-80) | The proposal has `at` and `created_at`, but does not say what value the `at` of "Contar como certa" gets. Options: (a) it inherits the `at` and `day` of the replaced row; (b) the instant of the correction. | (a): the correction does not change when the learner answered, and that is the only reason `at` and `created_at` exist separately. |
| Replacement chain (ARQ-80) | The proposal says "effective is the row that no other replaces". Taken literally, Wrong ← Count as right ← Undo would leave the Wrong not counting. | Effective is the row that no **effective** row replaces, read from newest to oldest. It is what ARQ-80 describes. |
| Resuming an interrupted batch | "Continuar revisão · 9 de 20 · +1" requires knowing which cards were in the batch, and the log does not say. Options: (a) the batch in progress in a `setting` key, deleted at the end; (b) a `session` column in `answer`; (c) rebuild the batch through the fold up to the instant it started. | (a): it is screen state, like the Reader progress, and does not need a new column in the log. |
| 4 a.m. rollover mid-session | A session that crosses 4 a.m.: which day do the quotas and answers belong to? | Each answer stores the `localDay` of the moment it happened. The batch already built stays the same; the quotas of the new day apply from the next batch. |
| Level filter (D4, D32) | In v1 the whole catalog is A1, and the "level ≤ reading level" filter cuts nothing (proposal 12.2, item 8). | Do not implement in v1: one codepath fewer. It comes in with the A2 content. |
| Excerpt by position (D22) | `saved.paragraph` and `saved.sentence` are positions, like progress (ARQ-37). An edit to the story shifts the excerpt. | The same rule as ARQ-37: without the paragraph, the last one that exists is used. If the `form` is no longer in the sentence, the paragraph shows with no highlight. |
| "Review" origin in History (D29) | `history` only has `story_id`. Options: (a) a `history.origin` column (0 story or search · 1 Review); (b) a reserved `story_id`. | (a): `story_id` is its own type (ARQ-47) and should not carry a special value. |
| Accent that changes the word (G4b) | *e* × *è*, *da* × *dà*, *la* × *là*. Options: (a) a fixed list in the code; (b) the typed word without the accent exists in `dict` as a form of another lemma. | (b), restricted to NVdB forms, so that *pero* (pear tree, rare) does not turn *però* without the accent into Wrong. |
