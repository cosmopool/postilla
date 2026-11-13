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
| ARQ-03 | Two repositories: `postilla` (Flutter app and app docs) and `postilla-content` (pipeline and story sources). | App and content have separate release cycles. The app gets new content without a new store version. |
| ARQ-04 | `postilla-content` is public. | The packages live in its Releases, and the app downloads them without a token. |
| ARQ-05 | Content packages are published as GitHub Releases of `postilla-content`. | No cost, and in the same place as the code that builds the packages. |
| ARQ-06 | The manifest URL bundled in the app is `https://postilla.kaiodelphino.com/content/manifest.json`. The manifest is served by the GitHub Pages of `postilla-content`, with that domain configured, and the package URLs inside it point straight to the Releases. | Changing host does not require a new app version: only the manifest URL is bundled. A domain cannot point by CNAME to a Release file, so the manifest lives on Pages. The `/content` leaves the root free for an app website. |
| ARQ-07 | `postilla-content` defines the contract between the repositories: schema of the content databases and manifest format. The app follows that contract. | Whoever produces the data documents the format. |
| ARQ-08 | [dictionary.md](dictionary.md) and [dictionary-pipeline.md](dictionary-pipeline.md) move to `postilla-content`. | The doc stays next to the code it describes. |

```
postilla-content (public)                      postilla
  pipeline (Zig)                                 app (Flutter)
  story sources                 Releases           bundled content
  contract (schema, manifest)   ─────────► manifest ─► update (section 3)
                                     custom domain
```

## 2. Content packages

| Id | Decision | Reason |
|---|---|---|
| ARQ-10 | Two packages, with independent versions: `dict` (dictionary) and `stories` (stories and translations). | A new story does not download the ~15 MB of the dictionary. |
| ARQ-11 | Each package is a single SQLite file compressed with zstd -19 (`dict-2.1.0.db.zst`). Version, sources and licenses live in the database's own `meta` table. In v1, the bundled package uses gzip -9 (`dict-2.1.0.db.gz`, ~21 MB); zstd comes back in v1.2 ([roadmap](roadmap.md)). | zstd has the best balance between size (~15 MB) and decompression speed. A single file simplifies download and verification. In v1, `dart:io` already decompresses gzip, with no package. |
| ARQ-12 | Each package version is SemVer: major changes when the schema becomes incompatible with old apps; minor, when new content comes in (new dump, new stories); patch, for one-off fixes (wrong gloss, error in the text). | The major tells the app whether it can read the package. |
| ARQ-13 | Each app build accepts a single major per package (e.g. `dict` 2.x, `stories` 1.x). A package of another major is ignored, and the app keeps the version it has. | Simple rule, checked without looking at anything but the version. |
| ARQ-14 | The initial bundled version (OFF-10) is not in git. A lock file in the app repo pins the version and sha256 of each package, and a script downloads the files from the Releases before `flutter build`. In v1, nothing is published: the lock points to `../postilla-content/out`, and the script copies the files from there. | No large binaries in the app repository. The lock makes the build reproducible. |
| ARQ-15 | Settings › About (OFF-13) shows the version of both packages and the date of the Wiktionary dump, read from the `meta` of `dict`. | The date tells the user when the dictionary is from; the SemVer identifies the package in an error report. |

## 3. Content updates

Behavior in OFF-20..24. Flow:

```
open the app ─► manifest (≤ 1×/day) ─► new version of the accepted major? ─► download .zst (resumable)
  ─► sha256 of the .zst ─► decompress into staging ─► sha256 of the .db ─► ready
next launch ─► swap the pointer to the ready version ─► delete the previous one
```

| Id | Decision | Reason |
|---|---|---|
| ARQ-20 | The manifest is a JSON with only the latest version of each package: version, URL, size, sha256 of the `.zst` and sha256 of the `.db`. | Minimal format. An app on an old major stops getting content until it is updated from the store (ARQ-13). |
| ARQ-21 | The manifest is not signed. Integrity comes from HTTPS and the sha256s. | The sha256 catches a corrupted download. Protecting against a swapped manifest was left out of v1. |
| ARQ-22 | The download happens only while the app is open. If it is interrupted, the next launch resumes where it stopped (HTTP Range). | No native background download code. Resuming avoids downloading the ~15 MB again. |
| ARQ-23 | Right after downloading and checking the `.zst`, the app decompresses the package into a staging folder and checks the sha256 of the `.db`. Only then is the package ready. | The next launch only swaps a pointer, without waiting for decompression. It costs ~90 MB extra until the swap. |
| ARQ-24 | The swap (OFF-22, OFF-23) happens on the following launch, before opening any content database: the app points to the ready version and deletes the previous one right away. | The swap is atomic and never happens with a story or entry open. No rollback. |
| ARQ-25 | Between the content bundled in a new app version and the content already downloaded, the higher version of the major the app accepts wins. If the app changed major, the downloaded content is deleted and the bundled one wins. | Updating the app from the store never takes the content back to an older version. |
| ARQ-26 | The `meta` of `stories` lists the stories added in each version. On the swap, the app adds up the stories added since the version it had and stores the number for the Library notice (OFF-24). | The package says what is new, without the app keeping the list of ids of the previous version. |

## 4. On-device databases

The databases of OFF-34: `user` (user data), `stories`, `dict` and `log` (ARQ-70). The schema of `stories` and `dict` is defined in `postilla-content` (ARQ-07).

| Id | Decision | Reason |
|---|---|---|
| ARQ-30 | The app accesses SQLite through the `sqlite3` package (FFI), with hand-written SQL. | No code generation and no layer between the app and the SQL. |
| ARQ-31 | All queries, in all databases, run in a dedicated isolate. The UI receives the results by message. | `sqlite3` is synchronous. Outside the UI isolate, a slow query does not freeze the screen. |
| ARQ-32 | The `user` schema evolves through numbered SQL scripts (`001.sql`, `002.sql`…). `PRAGMA user_version` stores the last one applied, and each script runs in a transaction. Forward only. | Explicit migration, easy to review. |
| ARQ-33 | Every `user` record has a UUID v7 `id`, `created_at`, `updated_at` and `deleted_at`. Dates are integers in ms since the epoch, in UTC. `answer` has the same columns, but only receives inserts: there `updated_at` always equals `created_at`, and `deleted_at` is always 0 (ARQ-80). The local day (`answer.day`, `history.day`) is not a date in ms: it is the `localDay` of ARQ-84. | Ids unique across devices and comparable dates allow future sync without a model migration (OFF-31). |
| ARQ-34 | Removing a saved word or clearing the history fills `deleted_at`, and the lists filter those rows out. Neither touches `answer`: the removed word leaves Review through the ARQ-83 filter, and its answers stay in the log (REV-03). | Future sync knows what was removed. Removing does not erase what the learner already answered. |
| ARQ-35 | `user` never points to `entry.id`. A saved word is by lemma, as text (`"serranda"`), and also stores the part of speech of the entry where it was saved (`saved.pos`), which only decides which cards the saved word generates (D12). The history points to the entry by lemma + part of speech (`"binario"`, `"sostantivo"`). Answers point to lemma + part of speech and to the `rule.id` (ARQ-86). | `entry.id` changes with every `dict` build, and the lemma survives across versions. Outside the Reader the app does not know the tapped form, so the saved word is by lemma. Saving "binario" marks both "binario" entries (noun and adjective) as saved, but only the saved part of speech becomes a card (P05). The history has one row per entry (SAL-01), so it stores the part of speech. An entry that left `dict` falls under OFF-32. |
| ARQ-36 | Each story has a UUID written in the source, which never changes. Progress, saved words and history point to that UUID. | Renaming or fixing the story does not break the link. |
| ARQ-37 | Progress points to the paragraph by position. If the story shrinks, progress goes to the last paragraph that exists (OFF-32). The offset within the paragraph (LEI-07) is the index of the first visible character. | Position is the simplest. The character index survives changes in text size and rotation. An edit in the middle of the story shifts the progress, and that was accepted. |
| ARQ-38 | Settings live in a key-value table in `user`. Topics taken out of Review are also a setting, not a card column (ARQ-83). | They go into Export/Import (AJU-05) and future sync. |
| ARQ-39 | `dict` and `stories` are opened read-only (`mode=ro&immutable=1`). | No WAL or lock, and no accidental writes to the content. |

Tables of `user` (in addition to the ARQ-33 columns):

| Table | Fields | Requirements |
|---|---|---|
| `progress` | `story_id`, `paragraph` (position), `offset` (character), `status` (in progress \| read), `last_opened_at`. With no row, the story is new. | BIB-02, BIB-03, LEI-07 |
| `history` | `day` (`localDay`, rollover at 4 a.m., ARQ-84), `lemma`, `pos`, `story_id` (`''` outside a story), `origin` (0 story or search · 1 Review; open, section 12). Unique on `day` + `lemma` + `pos`. | SAL-01, D29, D30 |
| `saved` | `lemma` (text, unique key), `pos` (part of speech of the entry where it was saved: only it generates cards, D12), summary (part of speech, source story), `story_id`, `paragraph` and `sentence` (positions of the source sentence; they also open the excerpt page, D22), `form` (tapped form; `''` = no source sentence, as when saved from search). | SAL-02, OFF-32, LEI-10, REV-03 |
| `answer` | The insert-only log of Review and Practice answers (ARQ-80). Columns in the table below. | REV-17, TRE-05 |
| `setting` | `key`, `value` (JSON): reading, Immersion, translation ratio, Saved sort order, hints seen, new stories notice, Settings › Review (new words per day, origin) and topics taken out of Review. | OFF-30, ARQ-26, AJU-07 |

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
| ARQ-45 | One folder per screen (`library/`, `reader/`, `dictionary/`, `review/`, `settings/`), plus `db/` and `ui/` (design system components). Review and Practice share `review/`, because they use the same generator and the same grading. | Whoever works on a screen finds everything for it in a single folder. |
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
| ARQ-50 | The pipeline splits the text into words and sentences and writes to `stories`, per paragraph, the start and end of each word and each sentence, in Italian and in Portuguese. Elisions (l'aria, c'è) are a single word. The app only reads those spans. | A single tokenizer, in the pipeline, tested at build time. The word counts of LEI-07 and the sentence pairs of TRA-08 come out ready. |
| ARQ-51 | Each paragraph is its own `RenderBox` with a `TextPainter`. It does the layout, keeps each word's rectangle in an array, resolves tap and selection drag by the nearest rectangle (enlarged box), paints the highlight, the marked sentence and the dotted underline, and creates one semantics node per word. | The Reader is the center of the app: what matters stays big and in one place. No widget or recognizer per word, and semantics stays under control (ACE-03, ACE-04). |
| ARQ-52 | All paragraphs are laid out when the story opens, in a non-lazy column. The top of each paragraph is kept in an array. | With stories of up to ~2,000 words, the cost is acceptable. Progress (LEI-07), restoring the position (ARQ-37) and syncing the split screen (TRA-07) become a binary search on that array. |
| ARQ-53 | When the story opens, the app resolves form → lemma in a batch: one query on `dict` with the distinct forms of the story. The lemmas live in an array parallel to the word spans and serve tapping (LEI-02) and the dotted underline (SAL-05). | A single query per story. `stories` does not depend on the `dict` version, and the content stays without lemma annotation (LEI-02). |
| ARQ-54 | A word gets a dotted underline when any of the form's lemmas is saved. With "serranda" saved, "serrande" is underlined. With "portare" saved, every "porta" in the text is underlined, even when it is the noun. | Without lemma annotation, the app does not know the sense of the word in the text. The rule never fails to underline a saved word, and accepts underlining too much in ambiguous forms. |
| ARQ-55 | Progress is saved when scrolling stops, when pushing an entry and when the app goes to the background. | Few writes and none during the gesture. Covers LEI-07, including the system killing the app with an entry open. |
| ARQ-56 | In split screen (TRA-07), the leading half reports the top paragraph and the fraction of it already scrolled. The other half scrolls to the same paragraph and the same fraction. | Follows smoothly within the paragraph, even with Italian and Portuguese at different heights. |

## 7. Dictionary

| Id | Decision | Reason |
|---|---|---|
| ARQ-60 | A tap looks up only the tapped word. In "si siede", tapping "siede" opens *sedere*. *sedersi* opens through the expression (press and drag over "si siede", LEI-03) or through search. | A single rule for tapping, without looking at the neighboring word. |
| ARQ-61 | An elision is looked up first whole and then only the part after the apostrophe. "c'è" finds the phrase, if `dict` has it, and otherwise goes to "è" → *essere*. "l'aria" does not exist whole and goes to "aria". | Finds phrases with elision when they exist and falls back to the main word when they don't. All in the ARQ-53 batch. |
| ARQ-62 | A form is looked up as written and, with no result, in lowercase. "Bologna" finds the proper noun, and "Il" at the start of the sentence goes to "il". If both exist ("Rosa" and "rosa"), the exact spelling wins. | Proper nouns in `dict` are capitalized, and so is the word at the start of a sentence. |
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
| ARQ-73 | Everything the app asks of the system goes through its own platform channel, in Swift and Kotlin: TTS, email, share sheet and file picker. No plugin packages. | A single mechanism for the system, with no dependencies, and each native call stays visible in the code. |
| ARQ-74 | Pronunciation (OFF-40) uses `AVSpeechSynthesizer` on iOS and `TextToSpeech` on Android, with an `it-IT` voice. The channel lists the voices with each system's offline flag. With no offline Italian voice, the button is disabled (OFF-41). | The system voice works without a network. |
| ARQ-75 | The email of Report error (LEI-09) and Send diagnostics (AJU-06) opens through the channel: `MFMailComposeViewController` on iOS and `Intent.ACTION_SEND` with an attachment through `FileProvider` on Android. On iOS with no account in the Mail app, the app warns that it needs a configured email app. | A `mailto:` link does not attach a file, and diagnostics need the attachment. A single mechanism for both emails. |
| ARQ-76 | The exported file (AJU-05) and the diagnostics attachment (ARQ-72) are generated with `VACUUM INTO` into a temporary file, deleted after sharing. | A consistent, compact copy with the database open, with no pending WAL or deleted rows. |
| ARQ-77 | `user` writes a fixed Postilla `PRAGMA application_id`. On import, the app opens the file read-only, checks the id, accepts a `user_version` lower than or equal to its own and runs the missing migrations (ARQ-32). A file from a newer app is refused with a notice. | Refuses any SQLite that is not Postilla's and accepts exports from old versions. |
| ARQ-78 | Before importing, the app keeps a copy of the current `user` (`VACUUM INTO`) in the app folder. Only the latest one stays, replaced on each import. Undo swaps `user` for it. | Covers the AJU-05 undo without the space growing. |
| ARQ-79 | Only `user` goes into the system backup (OFF-33). `dict`, `stories`, the staging folder, `log` and the undo copy stay out (`NSURLIsExcludedFromBackupKey` on iOS, backup rules on Android). | Content comes back from the bundled package, and the user's iCloud does not get ~90 MB. Android Auto Backup has a 25 MB limit. |

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

The pipeline, the story source format and the contract live in `postilla-content` (ARQ-07, ARQ-08). This section only lists what the app requires from the content, with the decision that asks for each item.

| Where | The app requires | Requested by |
|---|---|---|
| Packages | One SQLite file per package, compressed with zstd -19 (gzip -9 in v1) | ARQ-11 |
| Packages | SemVer version, with major = incompatible schema | ARQ-12 |
| Manifest | JSON with the latest version of each package: version, URL, size, sha256 of the `.zst` and sha256 of the `.db` | ARQ-20 |
| `stories` | Fixed UUID per story | ARQ-36 |
| `stories` | Title, subtitle, level, genre, duration, work and position in the work | BIB-01, LEI-10 |
| `stories` | Name of each genre in Portuguese and in Italian. The Library card, filters and search (BIB-06) use the language of the Immersion Navigation area | AJU-02, BIB-05 |
| `stories` | Per paragraph: text in Italian and in Portuguese, word and sentence spans in both, sentences aligned 1:1 | ARQ-50, TRA-08 |
| `stories` | Word count per paragraph | ARQ-50, LEI-07 |
| `stories` | `meta` with the stories added in each version | ARQ-26 |
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
| ARQ-90 | Tests are integration tests: they start from the UI (`flutter_test`, driving the widgets) and use real SQLite, one temporary file per test. Only HTTP calls and IO errors are simulated. | Tests the app as it runs, with no mock of an internal layer, since there are no layers (ARQ-40). |
| ARQ-91 | Unit tests only for heavy logic (Library sorting, the ARQ-66 trie, `grade()` and `osa()`, FSRS-6 and the log fold, and the like). Each one also gets an integration test that goes through it. | The unit test covers the hard cases of the logic. The integration test checks that it works wired to the rest. |
| ARQ-92 | For now there is no on-device end-to-end test (`integration_test`). | Running an emulator or device in CI is slow and expensive for v1. |
| ARQ-93 | Tests use the same production `dict` and `stories`, at the versions pinned by the build lock (ARQ-14). There is no test content database. Updating the lock runs the tests against the new content, and the bump only goes in with the tests passing. | Mock as little as possible. The test sees exactly the data the user sees. |
| ARQ-94 | The app CI runs on GitHub Actions, on Linux, on every push and PR: it downloads the lock packages, runs `dart analyze` and `flutter test`. Store builds stay out of CI for now. In v1 there is no CI: `dart analyze` and `flutter test` run on the machine. CI comes in v1.2. | Catches analysis and test errors before the merge, with no macOS runner. |
| ARQ-95 | The analyzer uses the default `flutter_lints`, with no tweaks. Names follow Dart style. | No custom rules to maintain. |

## 12. Open decisions

Review left this section: its architecture is in section 9 (ARQ-80…89). What remains are its technical open items, from section 12.2 of the [proposal](propostas/revisao-treino.md), and the ones that came up while writing section 9. The content open items (sources, disagreements, Morph-it! license) are in the open decisions of [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto).

| Topic | What is missing | Recommendation |
|---|---|---|
| Reader semantics | ACE-03 asks for reading by paragraph and each word as a button. How the RenderBox (ARQ-51) builds the semantics nodes to meet both can only be validated on a device, with VoiceOver and TalkBack. | — |
| Requests to `postilla-content` | The section 10 items that `dict` and `stories` do not have yet need to be accepted there: normalized column (ARQ-63), NVdB rank and band (ARQ-64), genre names in Portuguese and Italian, word and sentence spans (ARQ-50), stories added per version (ARQ-26), practice features in `entry.data`, `rule` and `drill` (ARQ-86, ARQ-87). | — |
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
