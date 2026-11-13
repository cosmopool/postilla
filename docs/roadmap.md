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
| Out of v1: Review and Practice (§7A, §7B); History and Saved (§7) and the dotted underline; reading progress (LEI-07, BIB-02, BIB-03, Continue reading, story states); content updates over the network (OFF-20..24, ARQ-20..26, manifest); Report error (LEI-09) and Send diagnostics (AJU-06); TTS pronunciation (OFF-40, OFF-41); Export and Import (AJU-05); Share from the entry (DIC-08). | 2026-10-26 |
| No custom platform channel in v1 (ARQ-73): nothing that stays needs the system. Exception: the `path_provider` package, only to find the app support folder where the databases live. | 2026-10-27 |
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
| The bundled package is compressed with gzip -9 (ARQ-11). zstd comes back in v1.2. | 2026-10-26 |
| The app lock points to `../postilla-content/out` (ARQ-14). Nothing is published. | 2026-10-26 |
| No CI in v1: `dart analyze` and `flutter test` run on the machine (ARQ-94). | 2026-10-26 |
| `appLog` only writes to the console (ARQ-70). The `log` database comes back with Send diagnostics. | 2026-10-26 |
| Each story is a `.txt`: a `chave: valor` header, an IT block and a PT block, one sentence per line, aligned across the blocks. | 2026-10-26 |
| Share from the entry ships in v1.1, with Export: both use the share sheet (ARQ-73). | 2026-10-27 |
| Story duration (BIB-01) computed from the words, by level: A1 60, A2 80, B1 100, B2 120 words/min, rounded up. | 2026-10-27 |
| Icons: Lucide paths (ISC) drawn by hand with a 1.5 stroke, no icon package. | 2026-10-27 |
| What the books don't draw: Reader without More options; dock with only "Mostrar tradução", on the right; Dictionary root with the search and the two tips; "Sem verbete no dicionário" in the standard toast; lemma choice page as a compact list (lemma + class); entry More options in a sheet (Copy · Back to story · Source); Settings with Reading, Immersion and About. In a conflict between books, the screen's own book wins. | 2026-10-27 |

## Versions

| Version | What goes in |
|---|---|
| v1 | Library, Reader, Reader with translation, Dictionary (search and entry) and Settings (Reading, Immersion, About). Offline, with bundled content. |
| v1.1 | History and Saved, dotted underline, reading progress, Export and Import, pronunciation (TTS), Report error, Send diagnostics and the `log` database, Share from the entry, backup exclusion (ARQ-79). Platform channels come in. |
| v1.2 | Content updates over the network, Releases, manifest, zstd and CI. |
| v2 | Review and Practice, with pipeline stage 5b. |
| Later | What the spec already defers from Review and Practice (§10). |

---

## v1

### Functional spec

| Area | Ids |
|---|---|
| Offline | OFF-01..04, OFF-10..13, OFF-30, OFF-31, OFF-33, OFF-34 |
| Navigation | NAV-01..06 |
| Library | BIB-01, BIB-04..10 |
| Reader | LEI-01..06, LEI-08, LEI-10..12 |
| Reader with translation | TRA-01..09 |
| Dictionary | DIC-01..11 |
| Settings | AJU-01..04 |
| Accessibility | ACE-01..06 |

### How it looks in v1

| Id | In v1 |
|---|---|
| OFF-04 | The only writes are the settings and the tips already seen. |
| OFF-10 | With gzip -9, the package is ~21 MB, not ~15 MB (ARQ-11). |
| OFF-30 | Only reading settings, Immersion, translation ratio and first-use tips already seen. |
| OFF-34 | Three databases: `user`, `stories` and `dict`. `log` ships in v1.1 (ARQ-70), and there is no Export or Import. |
| NAV-01 | Three tabs: Library · Dictionary · Settings. |
| NAV-06 | Tapping the active tab again: in Library, scrolls to the top; in Dictionary, goes back to the root. |
| BIB-01 | The card has no state: title, subtitle, level, genre and duration. |
| BIB-04 | Fixed order by level, from A1 to B2, and within the same level from shortest to longest. No Continue reading and no finished stories at the end. |
| BIB-07 | "Resultados" follows the BIB-04 order. |
| BIB-09 | Every story opens at the beginning. |
| LEI-01 | App bar with back, title and Aa, without More options. Dock with only "Mostrar tradução", without a progress line or "N% lido". |
| LEI-04 | Nothing saves: no gesture in the story, and the entry has no bookmark (DIC-08). |
| LEI-06 | The highlight stays the same. No dotted underline. |
| LEI-10 | End of the story with the "Próxima história" card and "Voltar à biblioteca", without a saved count or a link to Saved. The next one is the first candidate in this order: 1) the continuation of the work; 2) the next one at the same level, in BIB-04 order; 3) the first one at the next level (never two above). With no candidate, the card disappears. |
| DIC-08 | Entry app bar: back and More options (Copy · Back to story · Source). No bookmark and no Listen to pronunciation. |
| DIC-10 | Tab root with the search only: no `Histórico \| Salvas` and no More options. |
| ACE-02 | Without the session exception: when pushing, focus always goes to the back button of the new page. |

### Architecture

| Area | Ids |
|---|---|
| Overview | ARQ-01..03, ARQ-07, ARQ-08 |
| Packages | ARQ-10..12, ARQ-14, ARQ-15 |
| Databases | ARQ-30..33, ARQ-36, ARQ-38, ARQ-39 |
| App | ARQ-40..42, ARQ-44..49 |
| Reader | ARQ-50..53, ARQ-56 |
| Dictionary | ARQ-60..66 |
| Diagnostics | ARQ-70 |
| Tests | ARQ-90..93, ARQ-95 |

| Id | In v1 |
|---|---|
| ARQ-11 | The bundled package is `dict-<versão>.db.gz` and `stories-<versão>.db.gz`, with gzip -9. |
| ARQ-14 | The lock pins the version and sha256 of the files in `../postilla-content/out`, and the script copies from there. |
| ARQ-33, `user` tables | `user` only has `setting`: reading, Immersion, translation ratio and tips seen. `progress`, `history` and `saved` ship in v1.1; `answer`, in v2. |
| ARQ-38 | No topics taken out of Review. |
| ARQ-44 | Three tab `Navigator`s. The root one only pushes the Reader and the Reader's entry. |
| ARQ-45 | No `review/` folder. |
| ARQ-49, ARQ-70 | Failures go to the console. No `log` database. |
| ARQ-51, ARQ-53 | No dotted underline. The batch's lemmas only serve taps. |
| ARQ-64 | Only the NVdB band, for search suggestions and "Você quis dizer". No rank within the band. |
| ARQ-93 | Test packages come from the local lock (ARQ-14). |
| ARQ-94 | No CI. `dart analyze` and `flutter test` run on the machine. |

### Pipeline

- Stages 1 to 7 of [dictionary-pipeline.md](dictionary-pipeline.md), without 5b.
- Sources: kaikki.org for it.wiktionary, the it.wiktionary dump, WikDict it-pt and en-pt, kaikki.org for en.wiktionary (gloss pivot only) and NVdB.
- Hand-written files: only the corrections file.
- Output in `out/`, compressed with gzip -9. Nothing is published.
- From architecture section 10, everything goes in, except what is in v1.2 and v2 below.

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
| ARQ-73..78 | Platform channel: TTS, e-mail, share sheet, file picker; Export and Import. |
| ARQ-79 | `dict`, `stories` and `log` out of the system backup. |
| ARQ-84 | Only `history.day`, with the rollover at 4 a.m. (D30). |

`setting` gains the Saved sort order.

## v1.2

| Id | What goes in |
|---|---|
| OFF-05, OFF-20..24 | Content updates over the network and the new-stories notice. |
| ARQ-04..06 | Public `postilla-content`, Releases and manifest on our own domain. |
| ARQ-11 | zstd -19 instead of gzip -9. |
| ARQ-13 | One accepted major per package. |
| ARQ-14 | The lock points to the Releases. |
| ARQ-20..26 | Manifest, download, preparation and swap. |
| ARQ-94 | CI on GitHub Actions. |

In architecture section 10: the manifest and the `stories` `meta` with the added stories. `setting` gains the new-stories notice.

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
