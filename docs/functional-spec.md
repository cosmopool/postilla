# Postilla: functional spec

What the app does and how it behaves. This spec covers functionality only; look, tokens and components live in the design system ([design/](design/)). Each requirement has an id (`OFF-03`) so it can be cited in tasks and reviews.

Related documents:
- [dictionary.md](dictionary.md): entry fields and transformations.
- [dictionary-pipeline.md](dictionary-pipeline.md): how the dictionary is generated and published.
- [design/content.md](design/content.md): sample texts (catalog, story, entries).
- [propostas/revisao-treino.md](propostas/revisao-treino.md) and [propostas/revisao-treino-decisoes.md](propostas/revisao-treino-decisoes.md): full design of Review and Practice (pattern catalog, grading rules, load) and the decisions that closed it.

---

## 1. Offline-first

The app's first requirement. Every feature works without a connection, always, including on first launch. The network only serves to receive new versions of the content, and the app never depends on it.

### Principles

| Id | Requirement |
|---|---|
| OFF-01 | No screen, action or state depends on the network. The app has no "Sem conexão" state. |
| OFF-02 | All content (stories, translations, dictionary) is bundled with the app and stays on the device. |
| OFF-03 | All user data stays only on the device. There is no account, login or user server in v1. |
| OFF-04 | Writes are local and immediate: saving a word, moving forward in reading or changing a setting is written right away, with no queue and no "sincroniza depois". |
| OFF-05 | Lack of network never shows up as an error. An update that fails is retried later, silently. |

### Bundled content

| Id | Requirement |
|---|---|
| OFF-10 | The app package ships an initial version of the content, compressed (~15 MB, almost all of it the dictionary). |
| OFF-11 | On first launch, the app unpacks the content into local storage (~90 MB). This happens without network and shows a "Preparando o dicionário" state while it lasts. |
| OFF-12 | If there is not enough space to unpack, the app says how much space is needed and tries again when the user asks. |
| OFF-13 | Dictionary and stories have their own versions (SemVer, ARQ-12). Settings › About shows both and the date of the Wiktionary dump: "Dicionário 2.1.0 (Wikizionario de 01/10/2026) · Histórias 1.4.2". |

### Content updates

| Id | Requirement |
|---|---|
| OFF-20 | When the app opens with network, it checks the content manifest, at most once a day. |
| OFF-21 | If there is a new version, it is downloaded in the background, over any network (Wi‑Fi or cellular), and the app checks the sha256. |
| OFF-22 | The new version is applied atomically: either it goes in whole, or the app keeps the previous one. An interrupted or corrupted download is discarded. |
| OFF-23 | The swap never happens with a story or entry open. The new version takes effect from the next app launch. |
| OFF-24 | The update does not ask for confirmation. When the applied version brings new stories, the first time the Library opens it shows a one-time notice that goes away on its own ("3 histórias novas"). New stories have no badge or section of their own and enter the BIB-04 order. Without new stories, no notice appears. |

### User data

| Id | Requirement |
|---|---|
| OFF-30 | Data kept on the device: progress per story, completed stories, last opened story, entry history, saved words and expressions (with the entry's part of speech and the source sentence), reading settings, Immersion, translation ratio, first-use hints already seen, Review and Practice answers (REV-17, including the words I know), Settings › Review and the topics removed from Review. |
| OFF-31 | Each record has a stable id and creation and modification dates, to allow sync in a future version without a model migration. |
| OFF-32 | User data is never lost because of a content update: |
| | • a saved word keeps its own summary (lemma, part of speech, source story) and stays on the list even if the entry changes or leaves the dictionary. If the entry leaves, tapping the word opens search with the lemma and "Você quis dizer" (DIC-11); |
| | • progress points to story + paragraph. If the story text changes, progress moves to the nearest paragraph that still exists; |
| | • Review and Practice answers point to the lemma and to the pattern id, which never changes (ARQ-86). An entry or pattern that leaves the content takes its cards out of Review, and the answers stay (REV-18). |
| OFF-33 | Deleting the app deletes the data. The system backup (iCloud/Google) may restore it, but the app does not depend on it. |
| OFF-34 | There are four separate databases on the device: user data, stories, dictionary and app log (ARQ-70). Only the user database is exported and imported (AJU-05). Updating content never touches the user database. |

### Pronunciation

| Id | Requirement |
|---|---|
| OFF-40 | "Ouvir pronúncia" uses the system's Italian voice (TTS, `it-IT`), which works offline. |
| OFF-41 | If the device has no Italian voice, the button is disabled, with an explanation of how to install the voice in the system settings. |

### What this changes in the current design

The books were designed with an online dictionary. The corrections are in [12. What changes in the books](#12-what-changes-in-the-books).

---

## 2. Navigation

| Id | Requirement |
|---|---|
| NAV-01 | Four tabs: Library · Dictionary · Review · Settings. The Review tab's name follows Immersion › Navigation (IT: *Ripasso*). |
| NAV-02 | The Reader is not a tab. It is pushed from the Library, full screen and without a tab bar. |
| NAV-03 | An entry opened from the Reader is pushed as a full page, without a tab bar. An entry opened from the Dictionary tab is pushed inside the tab, with the bar visible. The dictionary never opens in a sheet or modal. |
| NAV-04 | Back carries the name of the previous screen ("Voltar à história", "Voltar a finestrino", "Voltar ao Dicionário"). The chevron, the edge gesture and the system back button all work. |
| NAV-05 | Going back from the Reader preserves the Library's scroll, search and filters. |
| NAV-06 | Tapping the active tab again: in the Library, scrolls to the top; in the Dictionary and Review, returns to the root. |
| NAV-07 | In the Review tab, Practice topic and rule pages are pushed inside the tab, with the bar visible. The session (Review or Practice) is pushed full screen, without a tab bar, like the Reader. The entry, the rule and the story excerpt opened from within the session are also pushed without a bar. Back follows NAV-04: "Voltar à Revisão", "Voltar a Plural", "Voltar ao cartão". |

## 3. Library

| Id | Requirement |
|---|---|
| BIB-01 | Story catalog with title and subtitle (always in Italian, never translated), level (A1–B2), genre, duration and state. |
| BIB-02 | Story states: new, in progress (with progress line and %) or completed ("Lida"). A story is completed when the end block (LEI-10) comes on screen. There is no "Marcar como lida" button. Reopening a completed story from the card keeps "Lida". Only "Recomeçar do início" (LEI-09) moves the story back to in progress, at 0%. |
| BIB-03 | "Continuar lendo" card with the last opened story that is still in progress. A completed story never takes the card. With no story in progress, the card goes away. It also goes away when there is a search or filter. |
| BIB-04 | Fixed order: Continue reading → all stories (by level from A1 to B2; within a level, from shortest to longest) → completed at the end. There is no manual sorting. |
| BIB-05 | Filters as chips, in two groups (Level and Genre): "or" within a group, "and" between groups. "Limpar filtros" in the list header. |
| BIB-06 | Search looks in title, subtitle and genre, ignoring accents and case, and the result updates with each letter. Search and filters combine. The genre is shown and searched in the language of Immersion › Navigation (AJU-02). |
| BIB-07 | With a search or filter, a single list appears, "Resultados", in the order in progress → new → completed. |
| BIB-08 | Empty states: a search with no result offers "Limpar busca"; filters with no result offer "Limpar filtros". The result count is announced. |
| BIB-09 | Tapping a card opens the Reader. A story in progress opens at the last paragraph read; new and completed ones open at the beginning. |
| BIB-10 | No long press on the card: no preview, no context menu, no swipe to delete. |

## 4. Reader

| Id | Requirement |
|---|---|
| LEI-01 | Text only in Italian, with a compact app bar (back, title, Aa, More options) and dock (progress line, "N% lido", "Mostrar tradução"). |
| LEI-02 | Tapping a word highlights the word and pushes the lemma's entry. Elisions (l'aria, c'è) are a single target. Punctuation does not respond. A word with no entry (proper noun, word outside the dictionary) is highlighted and shows a toast: "Sem verbete no dicionário". If the form leads to more than one lemma or part of speech ("porta": porta sostantivo or portare), it pushes a short choice page, with one row per lemma and part of speech. There is no lemma annotation in the content. |
| LEI-03 | A long press (500 ms) selects an expression. The user drags to extend the selection word by word, within the paragraph, and on release the expression opens in the dictionary. |
| LEI-04 | No gesture in the story saves. Saving happens only through the entry's bookmark. |
| LEI-05 | A tap outside the words, pinch and double tap have no effect of their own (the double tap counts as one tap). |
| LEI-06 | When returning from the entry, the scroll is the same and the word stays highlighted until the next tap or the first scroll. Saved words appear with a dotted underline. |
| LEI-07 | Progress is saved continuously (story + paragraph). When an entry opens, the app also records the offset within the paragraph: if the system kills the app, the story reopens exactly at that point. "N% lido" is the same on the dock and on the card: words in the paragraphs before the current one (the one at the top of the screen) ÷ total words, rounded down. It stays at 99% at most until the story is completed (BIB-02), when it becomes 100%. |
| LEI-08 | Aa: text size (5 steps), line spacing (3 options) and theme (Light · Dark · System, applies to the whole app). Changes take effect right away and for all stories. |
| LEI-09 | More options: Restart from the beginning · Report a text error. "Relatar erro" opens the system email app with recipient (postilla@kaiodelphino.com), subject and body filled in (story, paragraph, excerpt and content version). Without network, the email stays in the system outbox. |
| LEI-10 | End of story: count of words saved in it (the line goes away if it is zero), link to Saved, "Próxima história" card and "Voltar à biblioteca". No celebration. The next one is the first candidate in this order: 1) the continuation of the work, when the story is part of a split work; 2) the first not completed of the same level, in BIB-04 order; 3) the first not completed of the next level (never two above). Stories in progress also count. With no candidate, the card goes away. |
| LEI-11 | First-reading hint, shown once: "Toque numa palavra para abrir o dicionário." |
| LEI-12 | Keyboard: ← → move through words, Enter opens the entry, Esc goes back. |

## 5. Reader with translation

| Id | Requirement |
|---|---|
| TRA-01 | Horizontally split screen: Italian on top, Portuguese below. Ratios 50/50 (default), 65/35 and closed. Italian never gets less than 50%. |
| TRA-02 | The last open ratio is saved on the device. |
| TRA-03 | The divider snaps to the nearest ratio on release. Releasing with Italian above 82% closes the translation. |
| TRA-04 | A tap on the Italian word opens the dictionary. A tap outside the word marks the sentence and its Portuguese pair. A tap on the Portuguese marks the sentence and its Italian pair, and never opens the dictionary. |
| TRA-05 | One active sentence at a time. Tapping it again unmarks it. If the pair is out of view, the other half scrolls the minimum to show it. |
| TRA-06 | A long press selects an expression limited to the sentence. |
| TRA-07 | Scrolling of the two halves is synced by paragraph, led by the last half that received a tap. Sync is recalculated when moving the divider, changing the text size or rotating the device. |
| TRA-08 | Sentences and paragraphs are aligned 1:1 between Italian and Portuguese (a requirement for the content). |
| TRA-09 | The translation is always in Portuguese and always available, whatever the Immersion. The Glosses area (AJU-02) applies only to the entry's gloss. |

## 6. Dictionary

Fields, source and transformations: [dictionary.md](dictionary.md).

| Id | Requirement |
|---|---|
| DIC-01 | Monolingual entry in Italian, always by lemma: "si siede" opens sedersi. Plurals, conjugated forms and forms with a clitic lead to the lemma. |
| DIC-02 | Sections in a fixed order. A section with no data does not appear. Section labels (Significati ↔ Significados) follow Settings › Immersion › Dictionary (AJU-02). The entry content always stays in Italian. |
| DIC-03 | The PT gloss is hidden and a tap reveals or hides it. It is always closed when an entry opens. With Immersion › Glosses = Italian, the entry shows no gloss. |
| DIC-04 | "Nella storia" shows the story sentence with the word highlighted. Tapping it returns to the excerpt. For verbs, it shows the form used. |
| DIC-05 | Conjugation: one tense at a time (Presente, Passato prossimo, Imperfetto, Futuro, Imperativo), with the form used in the story highlighted. The Imperativo is the 5th tense, so the learner finds in the entry what they practice (D11e; see §11). |
| DIC-06 | The words in Sinonimi, Contrari, Parole derivate, Termini correlati, Alterati and Da non confondere con can be tapped and push another entry. All these sections are in v1. The stack holds up to 20 entries, and each one keeps its own scroll. |
| DIC-07 | An expression opens as an entry. If it has no entry of its own, it pushes the same choice page as LEI-02, with one row for each word of the selection that has an entry. |
| DIC-08 | Entry app bar: back, Hear pronunciation (OFF-40), bookmark and More options (copy, share, back to story, source). |
| DIC-09 | Attribution required on every entry, the same on all: "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA". |
| DIC-10 | Tab root: search and `Histórico \| Salvas` selector. More options: sort, clear history. The root has no Review card: it lives in the Review tab (REV-01). |
| DIC-11 | Search in Italian, with suggestions on each letter. Finds lemmas and inflected forms. Accepts wildcards (`?` for one letter, `*` for several). With no result, shows "Você quis dizer". |

## 7. History and Saved

| Id | Requirement |
|---|---|
| SAL-01 | Every opened entry goes into History, grouped by day, with lemma, part of speech and origin. The origin is the story, or "Revisão" for an entry opened in a Review or Practice session (D29). The day turns at 4 a.m., the same day as Review (ARQ-84). Each day has one row per entry: reopening moves the row to the top of the day and updates the origin. History has no limit. "Limpar histórico" asks for confirmation in a dialog and does not affect Saved. |
| SAL-02 | Save and remove only through the bookmark (on the entry and on list rows). A toast confirms: "Salva em Dicionário › Salvas" or "Removida das Salvas". The word is saved by lemma (ARQ-35): saving "binario" noun also saves "binario" adjective, and removing from one removes from both. The part of speech of the entry where the word was saved only decides which cards it generates in Review (REV-03). |
| SAL-03 | An expression with its own entry is saved as a single item. |
| SAL-04 | Saved has two sort orders: Most recent (default) and A–Z. The choice is saved on the device. History has no sorting: it is always by day, from most recent to oldest, and only the Saved tab shows "Ordenar". Empty state: "Nenhuma palavra salva ainda". |
| SAL-05 | A saved word appears with a dotted underline in the Reader and in the related-word lists. In the Reader, every form of the lemma is dotted ("serrande" with "serranda" saved). A form of more than one lemma is dotted if any of them is saved (ARQ-54). |

## 7A. Review

Spaced review of the learner's words and of A1 grammar, in the Review tab (NAV-01). Full design, pattern catalog and grading rules: [propostas/revisao-treino.md](propostas/revisao-treino.md). Decisions (cited as **Dn**): [propostas/revisao-treino-decisoes.md](propostas/revisao-treino-decisoes.md). Screens: [book-revisao.html](design/book-revisao.html).

Terms used in this section and in 7B:
- **Card:** a memory scheduled by FSRS. The **word card** tests one word in one exercise (*binario* · Word; *uomo* · Plural). The **pattern card** tests a rule, and the word changes each time (Plural · -co, -go).
- **Pattern:** a regularity in the catalog, with id, level, rule in PT and IT, examples and members. A `regra` pattern is a pattern card. In a `lista` pattern, each member has its own word card.
- **Topic** and **rule:** for the learner, "Plural" is a topic and "-co, -go" is one of its rules.
- **Learner's words:** the Saved words and the NVdB words that Review has already introduced.

### Entry point and content

| Id | Requirement |
|---|---|
| REV-01 | Review starts from the "Revisão de hoje" card, at the top of the Review tab root, above the Practice list (TRE-01). Four states: |
| | • with cards: "Revisão de hoje · 20 cartões · 5 palavras novas". Tapping pushes the session (NAV-07); |
| | • interrupted: "Continuar revisão · 9 de 20 · +1". Tapping resumes; |
| | • nothing due, including after finishing: "Nada para revisar agora · Próxima revisão amanhã, 9 cartões." Not a link; |
| | • Source = Saved only and nothing saved: "Nada para revisar ainda · Salve palavras no Dicionário para elas entrarem aqui." Not a link. |
| REV-02 | New words come first from Saved, from oldest to newest, and then from NVdB, by frequency, band by band. Settings › Review › Source can limit this to "Só salvas" (AJU-07). A word with no PT gloss enters through the Word exercise with a blank (REV-15). An NVdB word with no gloss is left out, because in v1 it has no source sentence (D13, D18). |
| REV-03 | Saving makes the lemma a source of cards only in the part of speech of the entry where it was saved: saving "binario" noun does not generate cards for "binario" adjective. The save stays by lemma (SAL-02, D12). Removing from Saved takes the cards out of Review and keeps the answers; saving again resumes where it left off. A saved expression generates only the Word card. |
| REV-04 | Nine exercises: Word (see the gloss and write the word, PT→IT), Gender, Article, Conjugation, Plural, Preposition, Adjective (agreement), Possessive and Piacere. Conjugation tests three tenses: Presente, Passato prossimo and Imperativo (with the negative of *tu*). The v1 catalog has 30 A1 patterns in 9 topics (proposal, section 2.2). Catalog rules: |
| | • Gender is a 2-option choice by sound (*il · la*, *lo · la*; before a vowel, *un · un'*, because *l'* hides the gender), only for nouns whose ending does not tell the gender. The article form is a typed pattern card (D15); |
| | • all other form exercises are typed. Adjective, Possessive and Piacere use items written by hand in the catalog (*le chiavi ___ (nuovo)*), not generated sentences; |
| | • a regular verb never gets its own card: *parlare* appears only as a word of the pattern card for the -are Presente; |
| | • on a pattern card, the label states the rule (`PLURAL · -co, -go`). On a `lista` member, the label is only the topic (`PLURAL`), because "Irregulares" would already be a hint; |
| | • the word of the moment on a pattern card is the member the learner got wrong last time, if that was more than 1 day ago; otherwise, the one used longest ago. First the learner's words, then NVdB. Never the same one twice in a row. |
| | There is no setting per exercise or per tense: a topic leaves Review through the topic page (TRE-08). |
| REV-05 | A new word is introduced before it is first tested: lemma, article, gloss, definition and audio, with "Já sei" and "Aprender". The first question (Word) comes 3 cards later. "Já sei" (in the introduction or in More options) takes the word out of Review and puts it in Settings › Review › Words I know (AJU-07). A toast with an action confirms: "*chiave* não vai mais para a revisão. Desfazer", for 6 s; the timer pauses while the toast has focus. |

### Scheduling and session

| Id | Requirement |
|---|---|
| REV-06 | Scheduling by FSRS-6, as in Anki (D2, ARQ-82): |
| | • every answer in the card's own format, from any door (Review, repeats, reinforcement, Practice), updates stability and difficulty. Same-day answers go through the short-term formula. A lapse counts only on the first error of the day on a card in review; |
| | • grades: Wrong and Don't know → Again. Almost, or right with a hint → Hard. Right → Good. There is no Easy button: the grade comes from the correction, without asking the learner to rate; |
| | • unlock: a word's form cards (Gender, `lista` member) only enter after its Word card is answered right on a day after the introduction. A `lista` member only enters after Review has introduced its pattern (REV-23); |
| | • batch order: due cards from lowest to highest retention; new ones interleaved, 1 in every 4; different exercises alternate when there is a choice. Two cards of the same word are never in the same batch, except the introduction and the first test; |
| | • tapping a word in review in the Reader only opens the entry and does not affect scheduling (D27). |
| REV-12 | Each answer is recorded right away (OFF-04). Closing the session (chevron, edge gesture or system back) does not ask for confirmation. What was left stays due, and the day's card shows "Continuar revisão" (REV-01). |
| REV-16 | No gamification (§10): no day streaks, points, goals or celebration. The end of Review shows only: "20 cartões revisados", "Certos 15 · Quase 2 · Errados 3", the day's new words ("5 palavras novas: chiave, giornale…"), the weakest pattern with the link to practice it (TRE-07), "Mais 34 vencidos." (only if some are left) and the "Continuar" and "Voltar à Revisão" buttons. |
| REV-20 | Limits (D7): batch of 20 cards, reinforcement included. Per day, up to 5 new words (0 · 3 · 5 · 10 in AJU-07), 2 new forms (Gender and `lista` members) and 1 new pattern. With more than 60 due at the start of the session, nothing new enters that day. Due cards have no limit. Quotas count only what Review created: Practice never spends quota. After 20, the end of the batch offers "Continuar" or stopping, and what is left stays due. The numbers depend on the new simulation (§11). |
| REV-21 | Counter "N de M · +K". M is the batch size and does not grow. N advances when a card appears for the first time (the introduction also advances it). K is the sum of pending repeats plus the new words waiting for their first test. The screen reader reads "Cartão 4 de 20, mais 1 para repetir". A wrong card comes back after at least 3 others, at most 2 times per session; after that, it is left for tomorrow (D21). Repeats count in FSRS (REV-06) and survive the app being closed. |
| REV-22 | Reinforcement (D8): one block per day with 3 items from the weakest pattern (TRE-07), in the first batch, after the 10th card, within the 20. With no weakest pattern, there is no block. The block starts with a transition line, with no new screen: "Reforço: plural em -co, -go · 3 cartões" and "Continuar". The short rule appears first only if the learner got any of the last 3 answers for that pattern wrong. They are 3 different words; in a `lista` pattern, only members the learner already has as cards. Reinforcement never creates a card, and the answers count in FSRS. |
| REV-23 | New pattern (D4): Review introduces up to 1 per day, the next in the catalog in *Dai! 1* order, with a level lower than or equal to the reading level and with at least one member among the learner's words. Reading level is the highest among stories in progress or read, A1 with none; in v1 the whole catalog is A1, and the filter cuts nothing (D32). `regra` pattern: the rule page (2 to 3 sentences and the examples table) with "Continuar"; the first question, typed, comes 3 cards later and creates the card. `lista` pattern: only the rule page; from then on, members that are learner's words can enter through the form quota. A topic removed from Review (TRE-08) introduces no patterns. |

### Question and correction

| Id | Requirement |
|---|---|
| REV-07 | Automatic correction (ARQ-85). The grade measures only the card's target: an error outside the target is shown, and the grade stands (D6). Rules (proposal, section 3.2): |
| | • an error outside the target is Right with a notice: *è arrivato* with subject *lei* → "Certo. Com *lei*: *è arrivata*."; |
| | • in Word, any form of the lemma counts: *serrande* → "Certo. A palavra no dicionário é *serranda*."; |
| | • the article is optional in every answer with a noun and, if present, is checked. A wrong article is Right with a notice ("O artigo é *i*: *binario* é masculino."). In Possessive, the article is the target; |
| | • accent: in Word, a missing accent is Right with a notice ("Falta o acento: *città*."); on a form card, it is Almost. The imperative apostrophe (*va'*) counts as an accent. An accent that changes the word (*e*/*è*, *da*/*dà*) is Wrong; |
| | • another lemma with the same gloss (*finestra*, when *finestrino* was asked) gets no grade: "Também é janela. Aqui, a palavra é outra." The card comes back at the end of the session with the first letter, and that answer is graded normally; |
| | • one letter off, with 6 letters or more, is Almost only in Word. On a form card, it is Wrong (*amichi*, *binarii*); |
| | • choice (Gender, Practice form choice): right is Good; wrong or Don't know, Again. There is no Almost; |
| | • Don't know is Again. Skipping records nothing. |
| | Per exercise: in Conjugation, the subject pronoun is optional and the pronominal verb's pronoun is required (*siede* for *si siede* is Wrong); alternative forms from the table count (*va'* and *vai*). In passato prossimo with *essere*, a swapped auxiliary is Wrong (*ho arrivato*) and any participle ending counts, with a notice if the subject calls for another (§11). In the negative imperative of *tu*, only *non* + infinitive. Adjective and Piacere accept only the blank or the whole sentence; Possessive accepts with or without the noun (*mia* or *mia madre*). The field turns off the keyboard's autocorrect, suggestions and auto-capitalization. |
| REV-08 | With the field active, an accent bar (à è é ì ò ù) sits above the keyboard. Each key has an accessible name ("e com acento grave"). |
| REV-09 | Hint ("Mostrar dica", no icon). In Word: the story sentence with a blank; with no sentence, or when the sentence is already the question, the first letter. On form cards: the rule in one line, without the answer ("-co, -go: ganha h."). In choices, there is no hint. Using the hint caps the grade at Almost (Hard, D20). |
| REV-15 | Immersion. For a word with no PT gloss, or with Immersion › Glosses = Italian, Word asks through the source sentence with a blank, with the aligned PT sentence as a clue; with no sentence, through the first definition in Significati with a blank (D13; see §11). The lemma and the words that start with the same 5 letters become blanks. Labels, buttons, instructions, verdicts, notices, topic and rule names and rule texts follow Immersion › Labels and buttons (D14). The names "Revisão" (*Ripasso*) and "Treino" (*Allenamento*) and the page titles follow Navigation. Tense names, person, part of speech, *Piacere* and the questions of the hand-written items always stay in Italian, as in the entry. |
| REV-25 | Single button: with the field empty, "Não sei"; with text, "Conferir"; on the answer, "Continuar", in the same place. Never two buttons side by side. In choices, the bar shows only "Não sei". The field has no placeholder and grows with the text. Keyboard: Enter checks; on the answer, Enter is ignored for 500 ms and then acts as Continue; Esc goes back; in choices, 1 and 2 pick the option. The keyboard goes down on checking and comes up on the next typed card. |

### Answer

| Id | Requirement |
|---|---|
| REV-10 | The answer shows, in this order: the verdict, with undo (REV-11); when the card comes back, the reason (REV-24); the word with article and the listen button; part of speech and IPA; the gloss (closed pill, which does not appear with Glosses = Italian); the form; the rule applied to the word ("*medico* é exceção: *medici*.") with "Ver a regra ›"; In the story (REV-26); "Continuar". The question shrinks to one line, and on a wrong answer the letter that differs is underlined. In a choice, the tapped option gets ✓ or ✕ and the right one is marked. On a pattern card, "Volta em 4 dias" becomes "A regra volta em 4 dias", because the word will be a different one. The grade is already recorded when the answer appears. Audio plays only from the button, never on its own (OFF-40, OFF-41, D33). |
| REV-11 | On Wrong and Almost, "Contar como certa" sits on the verdict line and changes the grade to Right, recalculating the interval. Once tapped, it becomes "Contada como certa." and "Desfazer". Don't know has no undo: the button only exists with the field empty. |
| REV-13 | More options changes between question and answer. On the question: Skip card (goes to the end of the batch, recording nothing) · I know this word (only in the Word exercise, only in Review) · Report a card error. On the answer: Open entry (pushes, SAL-01) · I know this word · Report a card error. There is no entry before answering. "Relatar erro no cartão" opens email like LEI-09. |
| REV-24 | Why this card (D17): one line on the answer, next to "Volta em…", and at the end of the session; never on the question, where it would be a hint. Texts: "Errou há pouco", "Palavra nova · das salvas", "Palavra nova · das mais comuns", "Regra nova". A normal due card has no line, and reinforcement is stated once, on the transition line (REV-22). |
| REV-26 | In the story (D22). When the word has a source sentence (the sentence recorded when saving in the Reader), the answer shows the sentence with the form highlighted and "Ver o trecho ›". The link pushes a page with only the sentence's paragraph, with the story's title and level and the saved form highlighted, without the Reader, without a bar and without a dock. Opening the page does not record progress, completion or last opened story. "Voltar ao cartão" returns to the answer, with focus on the link. In v1, NVdB words and words saved from search have no sentence (D18). |

### Data and accessibility

| Id | Requirement |
|---|---|
| REV-14 | Removed: images on the card were postponed until after v1 (D24, §10). The id is not reused. |
| REV-17 | Review and Practice answers live in an insert-only log in the user database (OFF-30, ARQ-80). No answer is changed or deleted: "Contar como certa", "Desfazer" and "Já sei" are new rows. Card state, weakness, quotas and repeats are computed from the log (ARQ-81), and none of it is stored. The log goes along in Export (AJU-05). |
| REV-18 | Question and answer come from the dictionary at card time, so a content update takes effect on the next card. If the entry or the pattern leaves the content, its cards leave Review, the answers stay and the word stays in Saved (OFF-32). A card is only active if the source exists, the lemma is not in "Já sei" and the topic is in Review (ARQ-83). |
| REV-19 | Session accessibility: |
| | • when a typed card opens, focus goes to the field, with an accessible name that joins instruction, question and clue ("Escreva o plural. il medico, sostantivo maschile, singolare."). In a choice, it goes to the options group, named after the question; |
| | • after checking, focus goes to the verdict (focusable, without `role="status"`), read as a single sentence ("Não é essa. A resposta é i medici."); |
| | • on the introduction, focus goes to the lemma; on the reinforcement transition, to the line; at the end, to the title. When coming back from a pushed page, to the link that opened it (ACE-02); |
| | • the field has `lang="it"`. The blank is read as "lacuna", the IPA is hidden from the screen reader and state always has icon and text (ACE-05). Large text: ACE-07. Reduced motion: ACE-01. |

## 7B. Practice

Practice is Review with the learner choosing the subject: the same cards, the same correction and the same answer log. It sits at the root of the Review tab, below the day's card.

| Id | Requirement |
|---|---|
| TRE-01 | The "Treino" section lists 9 topics in a single list, without groups, in the order in which *Dai! 1* introduces them (D35): Article · Presente · Plural · Prepositions · Adjectives · Possessives · Piacere · Passato prossimo · Imperativo. Each row shows examples ("il, lo, la, l'") or the topic's state (TRE-07). The order never changes. Tapping pushes the topic page (NAV-07). Tense names and *Piacere* always stay in Italian. |
| TRE-02 | Topic page: a short text, the list of the topic's rules (with an example or state on each row) and "Treinar \<tema\>", which mixes the rules. Rule page: the text (2 to 3 sentences), the examples table and "Treinar só esta regra". A pattern with few members (*uomo → uomini*) gets no page and appears only as a row of the topic (§11). Paths: topic › Practice (2 taps); topic › rule › Practice only this rule (3 taps); end of Review › "Treinar -co, -go" (1 tap). "Ver a regra", opened from within a session, shows the same page without the "Treinar" button. |
| TRE-03 | Round of 10 items, in a fixed sequence (D16): |
| | • the first time on a pattern (no answers): the rule page, which does not count as an item, and 2 form-choice items (*il parco* → *parchi* · *parci*); |
| | • the rest, up to 10, is typed form. In "só esta regra", 1 item in every 3 is from the neighboring pattern (*parchi* × *treni*). In the whole topic, patterns are drawn with weight equal to the weakness, with at most one never-seen pattern per round. In a `lista` pattern, the items are the members, with the due ones first; |
| | • error: the answer shows the rule applied to the word ("*medico* é exceção: o plural é *medici*"), and the item comes back 2 items later, at most 2 times, outside the 10. The counter shows "4 de 10 · +1"; |
| | • no phases, no thresholds and no "firme por hoje" criterion. |
| TRE-04 | Round words: first the learner's words that are members of the pattern; then NVdB, by frequency. When the word is not the learner's and Glosses = Portuguese, the gloss appears in the question (*il parco* · parque). In the hand-written items (Adjectives, Possessives, Piacere), first the ones that use a learner's lemma. Each word appears once per round. |
| TRE-05 | Practice answers count in FSRS like Review answers (REV-06, D2). Form choice does not count: it only feeds the weakness, at half weight (D2b). Practice only creates pattern cards (the first typed answer for a never-seen pattern creates the card) and cards for `lista` members that are learner's words, which enter Review when unlocked (D9). A practiced NVdB word never becomes a Word card. Practice does not spend the REV-20 quotas. Correction, hint, single button, undo, More options and focus are those of Review (REV-07..11, REV-13, REV-19, REV-25), without "Já sei esta palavra". |
| TRE-06 | End of round: topic and rule ("PLURAL · -co, -go"), "10 cartões · Certos 7 · Quase 1 · Errados 2", one row per error ("amico: você escreveu amichi · amici") and, only in "só esta regra", "A regra volta na Revisão em 3 dias." Buttons: "Voltar a \<tema\>" and "Treinar de novo". On each item's answer there is no "Volta em…": the link to Review is only the end line. |
| TRE-07 | Weakness: computed per pattern, from answers from any door (ARQ-89). For the learner, it appears only as text and only as an exception (D10): "Você tem errado -co, -go" on the topic or rule row; "Ainda não treinado" or "Ainda não treinada" with no answers; the reinforcement transition (REV-22); the end of Review ("Você tem errado plural em -co, -go." and "Treinar -co, -go ›"). No number, bar, percentage, color, level icon, "Firme" or "dominado". The list does not change order with performance. Vocabulary has no weakness in v1: FSRS already brings the missed word back (D25). |
| TRE-08 | Topic page › More options: "Tirar da Revisão" (or "Pôr na Revisão", if removed) · Report error. Removing makes the topic's cards disappear from Review (the answers stay) and prevents its new patterns from being introduced. The topic's Practice stays available. It is the only way to take grammar out of Review (AJU-07). |
| TRE-09 | No gamification (REV-16, §10). |

## 8. Settings

The Settings book does not exist yet (`book-ajustes.html` is planned). For now, this is what is defined:

| Id | Requirement |
|---|---|
| AJU-01 | **Reading:** text size, line spacing and theme (the same as the Reader's Aa sheet). |
| AJU-02 | **Immersion:** four areas, each in Portuguese or Italian: Navigation, Labels and buttons, Dictionary, Glosses. Each area applies to the whole app, with no exception: the app bar, buttons and notices of the Dictionary follow "Labels and buttons". |
| AJU-03 | Immersion presets: Beginner (everything in Portuguese, default), Intermediate (dictionary in Italian), Full immersion (everything in Italian). Any other combination is Custom. Immediate effect. There is no onboarding: the app starts in Beginner without asking, and the user changes it in Settings › Immersion. |
| AJU-04 | **About:** app version, content version (OFF-13) and credits (Wikizionario, en.wiktionary and WikDict, CC BY-SA; NVdB, De Mauro 2016; wiktextract and kaikki). Morph-it! enters the credits if it enters the pipeline (§11). |
| AJU-05 | **Data:** Export and Import the user database as a file, through the share sheet and the system file picker. The file does not include stories or dictionary. Import replaces the current data: the app asks for confirmation and first keeps an automatic copy of the current data, so it can be undone. |
| AJU-06 | **About › Send diagnostics:** opens the system email app with recipient (postilla@kaiodelphino.com), subject, filled-in body (app and content versions) and the log of the last 30 days attached (ARQ-70..72). Nothing leaves the device unless the user sends the email. |
| AJU-07 | **Review:** three items (D34). New words per day: 0 · 3 · 5 · 10, default 5 (REV-20). Source: Saved only · Saved and most common, default Saved and most common (REV-02). Words I know: the words removed with "Já sei" (REV-05), and each one can go back to Review. There is no setting per exercise, per tense, for production or for audio. A topic leaves Review only through the topic page (TRE-08). |

## 9. Accessibility

| Id | Requirement |
|---|---|
| ACE-01 | With reduced motion, transitions become instant and state changes remain. |
| ACE-02 | Focus: on push, it goes to the new page's back, except in the Review and Practice session (REV-19). On pop, it returns to the source element. |
| ACE-03 | In the Reader, the screen reader reads by paragraph. Each word is a button, navigable with the words rotor. |
| ACE-04 | Each half of the split screen declares its language (`it` / `pt-BR`), so the screen reader voice switches language. |
| ACE-05 | Counts, states and changes are announced. No state depends on color alone. |
| ACE-06 | Touch targets of 44pt, with the documented exception of the words in the reading column (34pt lines). |
| ACE-07 | Large text: in Review and Practice, the answer field has a minimum height of 44pt and grows with the text. Verdicts and results wrap, without ellipses, and words are not broken. |

## 10. Out of scope

- Account, login, sync between devices and any user server (v1).
- Gamification: day streaks, XP, trophies, goals and celebrations.
- Story audio (narration).
- Dictionary search in Portuguese (reverse search PT → IT).
- Pinch zoom, manual Library sorting, preview or context menu on cards.
- Chapters and pages. Each story is one continuous text. A long work becomes several stories in the catalog ("Pinocchio, capitolo primo", "capitolo secondo"…).
- Review and Practice, postponed until after v1:
  - images on the card, from the gallery or the camera (the old REV-14, D24);
  - occurrence index: context sentences beyond the sentence recorded when saving, including from unread stories of the same level (v1.1, D18, D31). Conjugation and preposition in a sentence depend on it;
  - pre-teaching the words of the next story (v1.1, D26);
  - link from the entry (Flessione, Coniugazione) to Practice (v1.1);
  - content above A1 (D11, D11c, D11e): imperfetto and futuro in Practice, passato remoto and "recognize the form" (*disse* → *dire*, D28), condizionale, congiuntivo, plurals in -ma and -cia/-gia, -ci/-gi plural by stress, irregular plurals beyond *uomo*, participle agreement with *essere*, clitic pronouns, imperative with pronoun, *c'è/ci sono*, *questo/quello*, *non… mai*; they come back with A2 and B1 content. Practicing above the reading level becomes a decision again at that point (D32);
  - special handling for the word that falls into Again repeatedly: in v1, only FSRS (D25).
- In Review and Practice, also out: recognition exercise (IT→PT, meaning choice) and the "Production" setting (D3, D34); automatic audio and a setting for it (D33); mastery state ("Firme", levels, bars) and a list reordered by errors (D10); opening the story in the Reader from a card, or a "lookup Reader" (D22: the session shows only the excerpt, REV-26).

## 11. Open

Conflicts between the design books and missing definitions. When the spec already follows a recommendation, the requirement says "see §11", and the final decision may change it.

| # | Topic | Conflict or gap |
|---|---|---|
| 11 | PT gloss | Decided: the pipeline downloads an Italian → Portuguese dictionary and fills the gloss from it. Source: WikDict it-pt + pivot through en.wiktionary (2026-10-26, see [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto)). |
| 12 | Review load (REV-20, D7) | The numbers (5 words, 2 forms, 1 pattern, brake at 60, batch of 20) came from a simulation in FSRS-4.5 with a different design. It still has to be redone in FSRS-6 with every answer counting (D2), writing only (D3), pattern cards, reinforcement and Practice (proposal, section 9.3). **Recommendation:** the spec keeps these numbers until the simulation, and they are only settled after it. |
| 13 | Pattern catalog (REV-04, D11b) | The 30-pattern catalog (order, members) goes back for approval. Within it: a) "frequent" in `gen.lista` and `gen.sufixo` has no source; b) `prep.art` combinations: the 9 from the research (*al, alla, allo, del, della, nel, nella, sul, dal*) or the 5 prepositions with *il, la, l', i, le*. **Recommendation:** approve as is, with a) NVdB *fondamentale* and b) the 5 prepositions with *il, la, l', i, le*, leaving *lo* and *gli* for A2. |
| 14 | *amico* and *medico* (REV-04) | A named exception inside the `pl.co_go` pattern card, or a word card of its own (literal reading of D1, "word card only for exceptions")? **Recommendation:** inside the pattern: *amici* × *amichi* is the decision the rule trains. |
| 15 | Gender in FSRS (REV-06) | D2 speaks of a "typed" answer, but Gender is a choice and that is the card's own format. Options: it counts, by the "in the card's format" rule; or it does not count, and Gender has no scheduling. **Recommendation:** it counts. The spec is already like that. |
| 16 | Order of new patterns (REV-23, D4) | Does "catalog order" interleave topics by *Dai! 1* unit (the proposal's Ordem column) or introduce one topic at a time? **Recommendation:** interleaved. The spec is already like that. |
| 17 | `lista` members (REV-06) | Can a member (*fatto*) enter through the form quota before Review introduces its pattern? **Recommendation:** no, only after. The spec is already like that. |
| 18 | Pattern pace (REV-23) | With 1 pattern per day and the level filter without effect (D32), passato prossimo and imperativo arrive around the 25th day of Review, whatever the reading. Options: accept; 1 pattern every 2 days; tie it to the number of stories read. **Recommendation:** accept in v1 and look at it with usage data. |
| 19 | Level filter (REV-23) | No effect in v1, because the whole catalog is A1 (D32). Options: implement it now or only when A2 content arrives. **Recommendation:** only with A2 (one codepath less). The requirement stays written. |
| 20 | Participle with *essere* (REV-07) | A participle ending that does not agree with the subject (*è arrivato* with *lei*): Right with a notice or Right without a notice? **Recommendation:** with a notice (shows it without penalizing). The spec is already like that. |
| 21 | Excerpt page (REV-26, D22) | Does it show the paragraph's translation? Does tapping a word open the entry? Is there an "Abrir a história"? **Recommendation:** none of that in v1: the page only recalls the context. |
| 22 | Glosses = Italian in Word (REV-15) | The proposal uses the source sentence with a blank and the aligned PT sentence as a clue also with Glosses = Italian, but the PT sentence gives away the meaning this Immersion hides. Options: a) keep the PT clue (the translation is always PT, TRA-09); b) with Glosses = Italian, the first IT definition with a blank (as in the current book), and the IT sentence with a blank as a hint; c) only the IT sentence with a blank. **Recommendation:** b. The PT sentence stays only for the word with no gloss with Glosses = Portuguese. For now, the spec follows the proposal (a). |
| 23 | Imperativo in the entry (DIC-05) | D11e makes the imperative the 5th tense of Conjugation, but the proposal (12.2, item 13) still asks whether the entry shows it. The spec follows D11e. **Recommendation:** keep it. |
| 24 | Credits and attribution (AJU-04, DIC-09) | Decided (2026-10-26 and 2026-10-27): AJU-04 credits Wikizionario, en.wiktionary, WikDict and NVdB, and DIC-09 is a fixed line, "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA". What remains is Morph-it!, which depends on confirming the license (CC BY-SA 2.0 or LGPL) and on measuring how much it adds after en.wiktionary (D19). **Recommendation:** measure before putting Morph-it! in the pipeline and leave it out if it does not add A1 to B1 words. If it goes in, it goes into AJU-04 and into the DIC-09 line. |
| 25 | Pattern without its own page (TRE-02) | The proposal says a pattern with fewer than 10 members gets no page. That catches `imper.lista` (9 members), besides `pl.lista` (1). Options: lower threshold (fewer than 3 members); only `pl.lista`; keep 10. **Recommendation:** fewer than 3 members. |
| 26 | Origin of an entry opened in Practice (SAL-01) | D29 gives the origin "Revisão" to an entry opened in the session. For an entry opened in Practice, is the origin "Revisão" or "Treino"? **Recommendation:** "Revisão", the tab's name: a single origin. The spec is already like that. |
| 27 | Topic out of Review (TRE-08) | How does the Practice list show that a topic was removed from Review? Options: the text "Fora da Revisão" on the topic row, in place of the examples; nothing, only the More options item. **Recommendation:** the text on the row. It is an exception, like those in D10. |
| 28 | More options at the Review tab root | The proposal's design puts "⋯" at the tab root, without saying what is in it. Options: a shortcut to Settings › Review; no More options. **Recommendation:** no More options at the root. |
| 29 | Toast with Undo in Saved (SAL-02) | The toast with an action from "Já sei" (REV-05) would also serve for "Removida das Salvas. Desfazer" (request 2 from the proposal to the design system). **Recommendation:** yes, with the same component and the same 6 s timer. |

## 12. What changes in the books

Differences between the design books and this spec. The spec wins. The books will be fixed in the next design round.

### All books

- **Offline (OFF-01, OFF-41):** the "Sem conexão", "sincroniza depois" and "desativado offline" states and the messages that mention a connection are removed.
- **New states:** "Preparando o dicionário" (OFF-11), not enough space (OFF-12), missing Italian voice (OFF-41), new-stories notice (OFF-24).
- **Tab bar (NAV-01):** four tabs, Library · Dictionary · Review · Settings, with a new icon for Review (not in the current list in `components-shared.md`). This applies to every book that draws the bar: book-biblioteca, book-dicionario, book-revisao and identity.

### book-leitor.html

- **Dock (LEI-01, LEI-07):** "N min restantes", "Menos de 1 min" and "Concluída" become progress line + "N% lido". The scroll-based calculation (`p >= 0.99`) becomes the word-based calculation.
- **Highlight (LEI-06):** the 1.5 s duration is removed. The highlight stays until the next tap or the first scroll.
- **More options (LEI-09):** "Guardar para depois" is removed. "Relatar erro" opens email.
- **Completion (BIB-02):** the story is completed when the end block comes on screen.
- **Next story (LEI-10):** the rule becomes continuation → same level → next level, and the card goes away when there is no candidate.
- **Word with no entry and ambiguous lemma (LEI-02):** the "Sem verbete no dicionário" toast and the choice page are missing.
- **Reading error:** "Verifique a conexão…" becomes a local error. The translation's "Carregando" is removed.

### book-leitor-traducao.html

- **Translation (TRA-09):** always in Portuguese, whatever the Immersion.
- The "sincroniza" is removed.

### book-dicionario.html

- **Labels (DIC-02, AJU-02):** "padrão: italiano" and "Botões, avisos e o app bar ficam sempre em português" are removed. Everything follows Immersion.
- **Sections (DIC-06):** "Parole correlate" becomes "Termini correlati". Parole derivate, Alterati and Da non confondere con are added.
- **Gloss (DIC-03):** with Glosses = Italian, the pill does not appear.
- **Expression (DIC-07):** with no entry of its own, it opens the choice page, not the keyword's entry.
- **Tab root (SAL-01, SAL-04):** "Ordenar" (Most recent · A–Z) only in Saved. "Limpar histórico" with a confirmation dialog. History with one row per entry per day.
- The "Sem conexão" states of the entry and of the root are removed.
- **Conjugation (DIC-05):** the Imperativo is added as the 5th tense.
- **History (SAL-01):** an entry opened in a Review or Practice session has origin "Revisão". The day turns at 4 a.m.

### book-biblioteca.html

- **Immersion (AJU-02):** the "Glosses and translation" area becomes "Glosses". The "Open" note about the split translation is removed.
- **Continue reading (BIB-03):** shows the last story in progress, never a completed one.

### book-revisao.html

- **Placement (NAV-01, REV-01, DIC-10):** the "Revisão de hoje" card leaves the Dictionary root and goes to the Review tab root, above the Practice list, with four states (with cards, interrupted, nothing due, nothing saved).
- **Exercises (REV-04):** nine exercises. Added: Gender (2 options by sound), Article as a typed pattern card, Preposition, Adjective, Possessive, Piacere and Imperativo (with the negative); the 4-option Article is removed. Pattern card with the rule label. A regular verb has no card of its own. Conjugation only with Presente, Passato prossimo and Imperativo.
- **Settings › Review (AJU-07):** the Exercises and Conjugation tenses chips and the "Imagens" row are removed. The "Por dia" of 0 · 5 · 10 · 15 · 20 (default 10) becomes 0 · 3 · 5 · 10 (default 5). Three items remain. The screen's bar gets the 4th tab.
- **Images (REV-14):** the gallery or camera photo, the question variant with an image and the count in Settings are removed.
- **Scheduling (REV-06, REV-20):** FSRS-6 with every answer counting. Limits become 5 words + 2 forms + 1 pattern per day, a brake at 60 due and batches of 20. The quota stops counting "new cards of any type".
- **Correction (REV-07):** a missing accent in Word becomes Right with a notice; "Também é janela" gets no grade; article optional and checked; an error outside the target is Right with a notice.
- **Hint (REV-09):** it also exists on form cards, with the rule in one line.
- **Answer (REV-10, REV-11, REV-24):** new order; "Contar como certa" on the verdict line, also on Almost, with "Desfazer"; reason line; "A regra volta em…" on the pattern card.
- **Single button (REV-25):** Don't know · Check · Continue in the same place.
- **Counter and repeats (REV-21):** "N de M · +K", up to 2 repeats per card.
- **Reinforcement and new pattern (REV-22, REV-23):** the reinforcement transition line; the new-rule page and the `lista` pattern page.
- **In the story (REV-26):** "Ver o trecho ›" pushes the page with only the paragraph, instead of opening the story.
- **More options (REV-13):** changes between question and answer; "Abrir verbete" only on the answer.
- **"Já sei" (REV-05):** toast with Undo.
- **End (REV-16):** counts, new words, weakest pattern with "Treinar…", due cards left over.
- **Accessibility (REV-19, ACE-07):** the verdict's `role="status"` is removed. After checking, focus goes to the verdict, not to Continue. Field with an accessible name and a height that grows.
- **Practice (TRE-01..09):** new screens: topic list at the root, topic page, rule page (with and without "Treinar"), form choice, round with "N de 10 · +K" and end of round.
- **Data (REV-17):** the card and image tables are removed; answers become an insert-only log.
- **Requests to the design system (proposal, 7.4):** bar with 4 tabs and icon; toast with an action; field border with 3:1 contrast; "Mostrar dica" without an icon; "Na história" and the excerpt page reuse the entry's "Nella storia" component.

### identity.html

- **Chapters:** "Capítulo 2 de 6", "Página 1 de 6" and "Fim do capítulo 1. Continuar no capítulo 2?" are removed (out of scope).

### Settings book (to be created)

- Include Data: Export and Import (AJU-05). Immersion without onboarding (AJU-03).
- Include Review, with the three AJU-07 items, and the en.wiktionary credits in About (AJU-04).

