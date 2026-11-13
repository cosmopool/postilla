# Postilla: roadmap

Which version each requirement ships in. The specs ([functional-spec.md](functional-spec.md), [architecture.md](architecture.md), [dictionary.md](dictionary.md), [dictionary-pipeline.md](dictionary-pipeline.md)) still describe the whole product. This document gives the version of each id and how a requirement looks in a version that still lacks part of what it cites.

How to read:
- An id listed in a version ships as the spec describes it, except for the note in the "How it looks" table.
- When the spec, the architecture or a decision **Dn** says "v1" or "v1.1" about Review and Practice, the version is Review's, which is now v2. The "v1.1" in spec §10 (occurrence index, pre-teaching, link from the entry to Practice) goes to [Later](#later).

---

## v1 decisions

| Decision | Date |
|---|---|
| v1 has Library, Reader, Reader with translation, Dictionary and Settings, all offline. | 2026-10-26 |
| Out of v1: Review and Practice (§7A, §7B); History and Saved (§7) and the dotted underline; reading progress (LEI-07, BIB-02, BIB-03, Continue reading, story states); Report error (LEI-09) and Send diagnostics (AJU-06); TTS pronunciation (OFF-40, OFF-41); Export and Import (AJU-05); Share from the entry (DIC-08). | 2026-10-26 |
| No custom platform channel in v1 (ARQ-73), except the `audio` channel for narration (2026-11-13). Exception: the `path_provider` package, only to find the app support folder where the databases live. | 2026-10-27 |
| Tab bar with 3 tabs: Library · Dictionary · Settings. | 2026-10-26 |
| The pipeline is written in Zig 0.17, with dependencies through the Zig package manager (ARQ-02). Closes D23. | 2026-10-26 |
| Pipeline stage 5b (practice features, `rule`, `drill`, `rules.toml`, Morph-it!) is out entirely until v2. | 2026-10-26 |
| Frequency from NVdB (ARQ-64), band only (1 fondamentale · 2 alto uso · 3 alta disponibilità): the list has no per-word rank. The list has no reuse license (the Internazionale PDF says "Tutti i diritti riservati"); the owner decided to use it anyway. The bands were extracted once from the PDF into `nvdb.tsv` in `postilla-content`. | 2026-10-27 |
| PT gloss: WikDict it-pt + pivot through en.wiktionary (pipeline stage 4). | 2026-10-26 |
| A single corrections file, lemma + class + field → value. | 2026-10-26 |
| `entry.data` in JSON. | 2026-10-26 |
| The Imperative is the 5th tense of the entry's Conjugation (DIC-05). | 2026-10-26 |
| Credits in Settings › About: Wikizionario, en.wiktionary, WikDict and NVdB (AJU-04). | 2026-10-26 |
| Fixed source line on every entry: "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA" (DIC-09). | 2026-10-27 |
| The bundled package is compressed with gzip -9 (ARQ-11). zstd is now a `postilla-content` contract question (architecture section 12). | 2026-10-26 |
| The app lock pins the seed from the public bucket (ARQ-14). Replaces "the lock points to `../postilla-content/out`, nothing is published" (2026-10-26). | 2026-11-13 |
| No CI in v1: `dart analyze` and `flutter test` run on the machine (ARQ-94). | 2026-10-26 |
| `appLog` only writes to the console (ARQ-70). The `log` database comes back with Send diagnostics. | 2026-10-26 |
| Stories are drafts on `postilla-backend`, published as one `.tilla` per translation (ARQ-03, ARQ-50). Replaces the `.txt` source with a `chave: valor` header and IT and PT blocks (2026-10-26). | 2026-11-13 |
| Share from the entry ships in v1.1, with Export: both use the share sheet (ARQ-73). | 2026-10-27 |
| Story duration (BIB-01) computed from the words, by level: A1 60, A2 80, B1 100, B2 120, C1 140, C2 160 words/min, rounded up. C1 and C2 added 2026-11-13. | 2026-10-27 |
| Icons: Lucide paths (ISC) drawn by hand with a 1.5 stroke, no icon package. | 2026-10-27 |
| What the books don't draw: Reader without More options; dock with only "Mostrar tradução", on the right; Dictionary root with the search and the two tips; "Sem verbete no dicionário" in the standard toast; lemma choice page as a compact list (lemma + class); entry More options in a sheet (Copy · Back to story · Source); Settings with Reading, Immersion and About. In a conflict between books, the screen's own book wins. | 2026-10-27 |
| Stories, the dictionary and narration come from the backend's feed and the public R2 bucket (handoff in `postilla-backend/docs/app-handoff.md`). v1 ships an embedded seed and syncs from its cursor (OFF-10, OFF-20..27, ARQ-20..29). Content updates over the network move from v1.2 into v1. | 2026-11-13 |
| Narration ships in v1: Play/Pause in the dock, sentence marking, tap a sentence to jump (LEI-14, LEI-15). The audio downloads when the story opens, and Play appears once it's ready; seeded stories embed theirs. Playback through an own `audio` platform channel. | 2026-11-13 |
| Target and native language picker in Settings › Languages (AJU-08), from `GET /languages`. A switch resyncs from `since=0` and keeps the old language's files. | 2026-11-13 |
| Genre and tag names follow Immersion › Navigation (native or target column), not always native (BIB-06). | 2026-11-13 |
| The card shows tags, author and narration length; tags join search; filters list only values present; an unknown genre shows as "Outros" (BIB-01, BIB-05, BIB-06, BIB-11). The third chip group became the Tema facet the same day (below). | 2026-11-13 |
| Vocabulary coverage: one combined share at the story's start, not on the card (LEI-13). | 2026-11-13 |
| Story credit (author · adaptado · license) at the story's start, the license as plain text in v1 (LEI-13). Coverage and credit now sit in the title page's colophon (below). | 2026-11-13 |
| Sync on every Library visit, one at a time; updates (stories and dictionary) apply live (OFF-20, OFF-23). | 2026-11-13 |
| Story index: a writable local `stories` database plus `.tilla` and `.opus` files named by sha (ARQ-23). | 2026-11-13 |
| Base URLs `api.postilla.kaiodelphino.com` and `content.postilla.kaiodelphino.com`, built in; no manifest (ARQ-06). | 2026-11-13 |
| Unknown format: a quiet "update the app" notice in the Library (OFF-26). It moved from a banner into the status line the same day (below). | 2026-11-13 |
| Story without a native translation: "Sem tradução" note on the card, "Mostrar tradução" disabled (TRA-10). | 2026-11-13 |
| The dictionary credits stay hard-coded; `meta.license` and `meta.attribution` are not shown (AJU-04). | 2026-11-13 |
| About shows the story count and the stored cursor instead of a stories version (OFF-13). | 2026-11-13 |
| Design direction from the mock round in `docs/design/mocks/` (free-2, reader-1, library-2): the Library's status line is the one place where syncing speaks, with no toast and no banner; new stories carry "Chegou agora" until opened; the seed's stories never count as new (OFF-24, OFF-26, BIB-13, §11 #34). | 2026-11-13 |
| Library filter: facets Nível · Gênero · Tema under the search, each opening a sheet with a searchable checklist, story counts that apply the other facets, and zero values disabled, not hidden. Replaces the chip groups (BIB-05, BIB-08, BIB-14). | 2026-11-13 |
| Reader: the story opens on a title page with a colophon (credit, reading and narration, coverage, missing translation) (LEI-13). | 2026-11-13 |
| Narration transport in the dock: "Frase anterior" · Play/Pause · "Ouvir de novo"; the mark stays on pause; no "next sentence" (LEI-15). | 2026-11-13 |
| Translation button: the `languages` icon and its label, no outline; disabled per TRA-10, which is unchanged (design system). | 2026-11-13 |
| After a language switch, a story still downloading opens the Reader with a wait in place of the text; the "Baixando…" dialog is dropped (BIB-12). | 2026-11-13 |
| Settings opens with Idiomas ("Aprendo", "Traduções em") and About ends with the app's colophon (AJU-04, AJU-08). | 2026-11-13 |

## Versions

| Version | What goes in |
|---|---|
| v1 | Library, Reader, Reader with translation with narration, Dictionary (search and entry) and Settings (Reading, Immersion, Languages, About). Offline first, with an embedded seed, and synced from the backend. |
| v1.1 | History and Saved, dotted underline, reading progress, Export and Import, pronunciation (TTS), Report error, Send diagnostics and the `log` database, Share from the entry, backup exclusion (ARQ-79). Platform channels come in. |
| v1.2 | CI. |
| v2 | Review and Practice, with pipeline stage 5b. |
| Later | What the spec already defers from Review and Practice (§10). |

---

## v1

### Functional spec

| Area | Ids |
|---|---|
| Offline | OFF-01..05, OFF-10..13, OFF-20..27, OFF-30, OFF-31, OFF-33, OFF-34 |
| Navigation | NAV-01..06 |
| Library | BIB-01, BIB-04..14 |
| Reader | LEI-01..06, LEI-08, LEI-10..15 |
| Reader with translation | TRA-01..10 |
| Dictionary | DIC-01..11 |
| Settings | AJU-01..04, AJU-08 |
| Accessibility | ACE-01..06 |

### How it looks in v1

| Id | In v1 |
|---|---|
| OFF-04 | The only writes are the settings and the tips already seen. |
| OFF-25 | No user data points to a story in v1, so removal only deletes its files. |
| OFF-30 | Only reading settings, Immersion, translation ratio, the language pair and first-use tips already seen. |
| OFF-34 | Three databases: `user`, `stories` (the index) and `dict`. `log` ships in v1.1 (ARQ-70), and there is no Export or Import. |
| NAV-01 | Three tabs: Library · Dictionary · Settings. |
| NAV-06 | Tapping the active tab again: in Library, scrolls to the top; in Dictionary, goes back to the root. |
| OFF-26 | The notice has no "Atualizar na loja" link: opening a URL needs a platform channel, which comes in v1.1 (ARQ-73). |
| BIB-01 | The card has no reading state: title, subtitle, level, genre, tags, author, reading time, narration length, "Chegou agora" and the "Sem tradução" note. |
| BIB-04 | Fixed order by level, from A1 to C2, and within the same level from shortest to longest. No Continue reading and no finished stories at the end. |
| BIB-07 | "Resultados" follows the BIB-04 order. |
| BIB-09 | Every story opens at the beginning. |
| LEI-01 | App bar with back, title and Aa, without More options. Dock with the transport (once the narration is ready, LEI-15) and the translation button, without a progress line or "N% lido". |
| LEI-04 | Nothing saves: no gesture in the story, and the entry has no bookmark (DIC-08). |
| LEI-06 | The highlight stays the same. No dotted underline. |
| LEI-10 | End of the story with the "Próxima história" card and "Voltar à biblioteca", without a saved count or a link to Saved. The next one is the first candidate in this order: 1) the continuation of the work; 2) the next one at the same level, in BIB-04 order; 3) the first one at the next level (never two above). With no candidate, the card disappears. |
| DIC-08 | Entry app bar: back and More options (Copy · Back to story · Source). No bookmark and no Listen to pronunciation. |
| DIC-10 | Tab root with the search only: no `Histórico \| Salvas` and no More options. |
| ACE-02 | Without the session exception: when pushing, focus always goes to the back button of the new page. |

### Architecture

| Area | Ids |
|---|---|
| Overview | ARQ-01..04, ARQ-06..08 |
| Content | ARQ-10..15 |
| Updates | ARQ-20..29 |
| Databases | ARQ-30..33, ARQ-36, ARQ-38, ARQ-39 |
| App | ARQ-40..42, ARQ-44..49 |
| Reader | ARQ-50..53, ARQ-56 |
| Dictionary | ARQ-60..66 |
| Diagnostics | ARQ-70 |
| System | ARQ-73 (the `audio` channel only) |
| Tests | ARQ-90..93, ARQ-95 |

| Id | In v1 |
|---|---|
| ARQ-33, `user` tables | `user` only has `setting`: reading, Immersion, translation ratio, language pair and tips seen. `progress`, `history` and `saved` ship in v1.1; `answer`, in v2. |
| ARQ-38 | No topics taken out of Review. |
| ARQ-44 | Three tab `Navigator`s. The root one only pushes the Reader and the Reader's entry. |
| ARQ-45 | No `review/` folder. |
| ARQ-49, ARQ-70 | Failures go to the console. No `log` database. |
| ARQ-51, ARQ-53 | No dotted underline. The batch's lemmas only serve taps. |
| ARQ-64 | Only the NVdB band, for search suggestions and "Você quis dizer". No rank within the band. |
| ARQ-93 | Tests use the seed pinned by the lock (ARQ-14). |
| ARQ-94 | No CI. `dart analyze` and `flutter test` run on the machine. |

### Pipeline

- Stages 1 to 7 of [dictionary-pipeline.md](dictionary-pipeline.md), without 5b.
- Sources: kaikki.org for it.wiktionary, the it.wiktionary dump, WikDict it-pt and en-pt, kaikki.org for en.wiktionary (gloss pivot only) and NVdB.
- Hand-written files: only the corrections file.
- Output in `out/`, compressed with gzip -9, and published to the public bucket as `dict/<sha256>.db.gz` plus `dict/latest` (`postilla-content` CONTRACT.md).
- From architecture section 10, everything goes in, except what is in v2 below.
- Stories come from `postilla-backend`, not from the pipeline.

---

## v1.1

| Id | What goes in |
|---|---|
| OFF-32 | Saved and progress survive content updates. |
| OFF-34 | The `log` database and Export and Import of `user`. |
| OFF-40, OFF-41 | Listen to pronunciation (TTS). |
| BIB-02, BIB-03 | Story states and Continue reading. |
| BIB-04, BIB-07, BIB-09 | The order with Continue reading and finished stories at the end; "Resultados" by state; opening at the last paragraph read. |
| LEI-01 | Dock with progress and "N% lido"; More options. |
| LEI-04, LEI-06 | Saving through the entry bookmark; dotted underline. |
| LEI-07 | Reading progress. |
| LEI-09 | Restart from the beginning and Report error in the text. |
| LEI-10 | Saved count and link to Saved. The next story skips finished ones. |
| DIC-08 | Bookmark, Listen to pronunciation and Share. |
| DIC-10 | `Histórico \| Salvas` selector and More options. |
| SAL-01..05 | History and Saved, without the "Revisão" origin (D29, v2). |
| AJU-05 | Export and Import. |
| AJU-06 | Send diagnostics. |
| ARQ-34, ARQ-35 | `saved` and `history`, without the `answer` part. |
| ARQ-37, ARQ-55 | `progress`. |
| ARQ-43, ARQ-54 | Rereading saved items and dotted underline. |
| ARQ-70..72 | `log` database and diagnostics. |
| LEI-13 | The license name becomes a link (ARQ-73). |
| ARQ-73..78 | Platform channel: TTS, e-mail, share sheet, file picker, opening a URL; Export and Import. |
| ARQ-79 | `dict`, `stories` with its story and audio folders, and `log` out of the system backup. |
| ARQ-84 | Only `history.day`, with the rollover at 4 a.m. (D30). |

`setting` gains the Saved sort order.

## v1.2

| Id | What goes in |
|---|---|
| ARQ-94 | CI on GitHub Actions. |

## v2

| Where | What goes in |
|---|---|
| Functional spec | §7A (REV-*) and §7B (TRE-*); NAV-01 with the 4th tab; NAV-06 on the Review tab; NAV-07; the "Revisão" origin of SAL-01 (D29); the SAL-02 cards (REV-03); the answers in OFF-30 and OFF-32; AJU-07; the session exception in ACE-02; ACE-07. |
| Architecture | ARQ-80..89; the `answer` part of ARQ-35; the ARQ-38 topics taken out of Review; the rest of ARQ-84; the `answer` table; the Review open items in section 12. |
| Pipeline | Stage 5b: practice features, `rule`, `drill`, `rules.toml`, article exceptions, Morph-it! and the divergence report. In architecture section 10, the rows for `entry.data`, `rule`, `drill`, curated items, new sources, report and `rule.id`. The open decisions for 5b in [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto). |
| Decisions | D1–D10, D11, D11b–D11d, D12–D17, D19–D22, D25, D27, D29, D32–D36. From D11e, only Practice: the Imperative in the entry is already in v1. |
| Open | Items #12 to #23 and #25 to #29 of spec §11. |

## Later

- What spec §10 defers from Review and Practice: images on the card (D24); occurrence index (D18, D31); pre-teaching of the next story (D26); link from the entry to Practice; content above A1 (D11, D28, D32); dedicated handling for a word that falls into Again repeatedly (D25).
- The rest of §10 stays out of scope, with no version.
