# Postilla — componentes compartilhados (v0.4)

Spec for the book designers. Six books today: Identidade (`identity.html`), Biblioteca (with Ajustes › Imersão), Leitor, Leitor com tradução, Dicionário and Revisão (with the Treino). Ajustes gets its own book later.

**All shared CSS lives in `book.css`.** Every book links two files and nothing else is shared:

```html
<link rel="stylesheet" href="tokens.css">
<link rel="stylesheet" href="book.css">
```

Do not copy, fork or override `ui-*`, `phone*`, `book-*`, `wordmark*` or `is-*` classes, and never write a local rule whose selector mentions a `ui-*` or `book-*` class (not even as an ancestor): add a local class to the element instead. If you need a variant that does not exist, ask the brand lead so it lands in `book.css` for everyone. Book-specific rules go in your own `<style>` with your prefix: `lib-` (Biblioteca), `rd-` (Leitor), `tr-` (Leitor com tradução), `dic-` (Dicionário), `rev-` (Revisão), `set-` (Ajustes), `id-` (identity.html). No literal hex in a book: if a value is missing, it goes into `tokens.css`.

Reference implementation: `identity.html` uses every class below.

---

## 0. Rules that apply to every component

| Rule | Value |
|---|---|
| Fonts | Display = `--font-display` (Newsreader) only for screen titles ≥ 28px, story titles and dictionary headwords. Everything else = `--font-text` / `--font-ui` (Literata). IPA = `.ipa` (Noto Serif). No sans-serif anywhere. |
| Accent budget | The accent is **highlighter yellow**. Per screen: the grifo on the selected word (or expression) + at most **one** other yellow element. Primary buttons are **ink**. Progress lines are **ink** everywhere except the Reader (`.ui-progress--accent`). Where the one yellow goes is fixed per screen, see the table below. |
| Yellow is never text | On light, yellow fails as text and as a focus ring. For "accent as text/icon" use `--color-accent-text` (ink on light, yellow on dark). Focus uses `--color-focus` (ink on light). Never fill large areas (screens, headers, cards) with yellow. |
| Saved words | Neutral ink: dotted underline in `--color-word-saved` (= ink-faint), filled bookmark in `--color-word-saved-mark` (= ink-muted), list row bg `--color-word-saved-soft` (= surface-2). |
| Tap target | ≥ `--tap-min` (44px) in both axes. `.ui-btn--sm` and `.ui-chip` pad their hit area to 44px. **Conscious exception:** words in the reading column sit on 34px rows (`--type-reader` 20/34) and stay that way. Precedent: Kindle and Apple Books make words tappable at reading leading, and 20/44 is too loose to read. The word's width compensates (hit box = whole word on its line + half the gap to its neighbours, monosyllables get 44px minimum width), and the grifo confirms which word was hit before the dictionary pushes in. 34px clears WCAG 2.5.8 (24px). The largest Aa step (26/44) reaches 44px. |
| Corners | Controls are pills. Containers use `--radius-card`. Sheets use `--radius-sheet` on top corners. Never 0. |
| Lines | Hairlines 1px `--color-rule`. Control outlines 1.5px. Icons 24px, stroke 1.5. |
| Shadow | Only `--shadow-1` (sticky/floating bars) and `--shadow-2` (menus, dialogs). Cards have **no** shadow. |
| Focus | Built into `book.css` for every focusable element (`:focus-visible`). Never remove it. |
| Motion | `--dur-*` + `--ease-*`; reduced motion is handled by tokens. No bounces, confetti or streak flames. |
| Copy | PT-BR, sentence case, no exclamation marks, no emoji. Buttons are verbs ("Mostrar tradução"). |
| Toggles | One signal per state. A button whose **label changes** with its state ("Mostrar tradução" ↔ "Ocultar tradução", the narration disc "Ouvir narração" ↔ "Pausar narração") must **not** also carry `aria-pressed`: screen readers would announce "Ocultar tradução, pressed", which is double (and contradictory) signalling. The label is the state. Since v0.4 the translation button (`.ui-trbtn`) is **not outlined**: `languages` icon + label in ink, no fill, a ghost pill only on press, and a box as wide as the longer label so nothing moves when it swaps. With no translation (TRA-10) it keeps the label "Mostrar tradução", turns `--color-ink-faint` and uses `aria-disabled="true"` plus the hint "Esta história ainda não tem tradução em português". `aria-pressed` is only for toggles whose label never changes (chips, segmented, bookmark, Aa). |
| Gestures on words | **Tap** a word = dictionary entry, pushed as a full page (+ grifo). **Long-press** (500 ms) a word = select an **expression**: the grifo gets two handles and dragging extends it word by word within the paragraph (Leitor com tradução: within the sentence), e.g. «a un certo punto»; on release the expression opens in the dictionary as a full page. **Saving** a word or expression is done only with the bookmark in the dictionary entry; no gesture in the story saves. In the split reader, tapping outside a word (or anywhere in the Portuguese half) pairs the sentence. |

### Where the one yellow goes, per screen

| Screen | The single yellow element | Plus |
|---|---|---|
| Biblioteca (tab root) | active-tab bar | — (no grifo; card progress, status line, "Chegou agora" dot and active facets are ink) |
| Biblioteca, facet sheet open (Nível / Gênero / Tema) | none in the sheet | checked boxes, the "Ver N histórias" button and the search match are ink; the tab bar's yellow bar stays under the scrim |
| Leitor | reading progress line in the dock (`.ui-progress--accent`) | grifo on the selected word / expression; the narration disc is ink, the sentence being read is neutral (TRA-05 look), the translation button and title page are ink |
| Leitor com tradução | the same reading progress line in the dock | grifo; the paired sentence is **neutral** (`--color-sentence-*`), divider and paragraph marker are neutral |
| Dicionário, pushed from the Reader (no tab bar) | grifo on the word inside the "Nella storia" snippet | nothing else; gloss, chips, labels are ink |
| Dicionário tab root (Histórico \| Salvas, search) and entries pushed inside the tab | active-tab bar | the "Nella storia" snippet drops its grifo (ink underline only) |
| Ajustes | active-tab bar | — |
| Revisão tab root, theme and rule pages (Treino) | active-tab bar | — (the "Revisão de hoje" card is surface; weak-pattern lines are plain text) |
| Revisão / Treino session: question (every format), presentation, reinforcement line, end | none | progress line and buttons are ink |
| Revisão / Treino session: answer | grifo on the word inside the "Na história" card | none when the word has no source sentence |
| Story excerpt pushed from an answer (D22) | grifo on the saved form | — |

## 1. Navigation (decided)

- **Bottom tab bar, 4 tabs:** `Biblioteca` · `Dicionário` · `Revisão` · `Ajustes` (IT: *Biblioteca · Dizionario · Ripasso · Impostazioni*). Active tab = ink label, weight 600, and a 2px yellow bar under the label. The columns are equal but give way to the longest label, so *Impostazioni* in semibold never overflows on a 323px screen.
- **Revisão is the 4th tab** (decision D5 of `propostas/revisao-treino-decisoes.md`): its root holds the "Revisão de hoje" card and the Treino list; theme and rule pages are pushed inside the tab. A review or training session is pushed full screen with no tab bar, like the Reader. The Dicionário root no longer has a review card.
- **Saved words live inside Dicionário**, as a `.ui-segmented` switch at the top of the tab root: `Histórico | Salvas`.
- The **Reader** is not a tab. It is pushed from Biblioteca and is full-screen with no tab bar. A dictionary entry opened from the Reader is a pushed full page ("Voltar à história") with no tab bar either.
- **Top app bar:** `large` on tab roots (display title under a 56px bar) and `compact` on pushed pages (back + centered title + **up to 3** trailing icon buttons, e.g. dictionary entry: `volume-2`, `bookmark`, `ellipsis`).

Icons: [Lucide](https://lucide.dev) pinned `lucide@0.460.0`, stroke 1.5. Names: `library-big` (Biblioteca), `book-a` (Dicionário), `settings-2` (Ajustes), `chevron-left`, `search`, `bookmark` (saved = same glyph filled via `.ui-iconbtn--bookmark[aria-pressed="true"]`), `volume-2`, `a-large-small`, `rows-2` (was the translation button's icon up to v0.3), `languages` (translation button), `ellipsis`, `x`, `check`.

Added in v0.4 (used by the chosen mocks): `play` and `pause` (narration disc, glyph filled via `.ui-transport__play`), `skip-back` ("Frase anterior"), `rotate-ccw` ("Ouvir de novo"), `headphones` (narration length on the card), `download` (Reader wait, `.ui-wait__icon`), `chevron-down` (facet, collapsed zero values), `chevron-up` (zero values expanded), `chevron-right` (trailing affordance on rows and cards, e.g. Ajustes › Idiomas), `circle-arrow-up` (status-line notice), `external-link` ("Atualizar na loja" leaves the app). `sliders` is **not** on the list: the "Filtros" button it belonged to was dropped for the three facets.

**Revisão tab icon: pending.** Until the brand lead picks one, every mock uses `check` from the list above as a placeholder. Requested (book-revisao › Em aberto A1): `layers` (a stack of cards), with `repeat-2` and `notebook-pen` as alternatives.

**Icons requested by the Revisão book** (in use there, not yet on the list; Em aberto A2): `chevron-right` (link affordance on cards and rows, already used by the Dicionário book), `circle-dot` (verdict "Quase"), `circle-dashed` (verdict "Também é", no grade), `eye-off` (verdict "Não sei"). "Mostrar dica" has no icon (`lightbulb` stays off the list).

```html
<script src="https://unpkg.com/lucide@0.460.0/dist/umd/lucide.min.js"></script>
<script>lucide.createIcons({ attrs: { 'stroke-width': 1.5, width: 24, height: 24 } });</script>
<!-- usage: <i data-lucide="book-a" aria-hidden="true"></i> -->
```

---

## 2. Class reference (`book.css`)

### App components

| Class | Markup / modifiers | Notes |
|---|---|---|
| `.ui-appbar` | `<div class="ui-appbar">` → leading `.ui-iconbtn`, `<p class="ui-appbar__title">`, `<div class="ui-appbar__actions">` | Compact bar. Add `.is-scrolled` for the bottom hairline. |
| `.ui-appbar--large` + `.ui-largetitle` | `<div class="ui-appbar ui-appbar--large">…</div><h1 class="ui-largetitle">Biblioteca</h1>` | Tab roots. |
| `.ui-tabbar` / `.ui-tab` | `<nav class="ui-tabbar" aria-label="Principal"><a class="ui-tab" aria-current="page">…` | Exactly 4 tabs: Biblioteca · Dicionário · Revisão · Ajustes. The active one gets `aria-current="page"`. No badge or count on any tab (spec §10). |
| `.ui-btn` | `--primary` (ink) · `--secondary` (ink outline) · `--ghost` · `--accent` (yellow fill, ink text; 1 per flow) · `--sm` · `--block` | A fixed-label toggle uses `aria-pressed`; `--secondary[aria-pressed="true"]` turns ink. Disabled via `disabled`. The translation button is **no longer** a `.ui-btn` (it was `--secondary --sm` up to v0.3): use `.ui-trbtn`. |
| `.ui-iconbtn` | `--filled` · `--bookmark` | 44px circle. `aria-pressed="true"` = ink disc, except `--bookmark`, which fills the glyph in `--color-word-saved-mark`. Always has `aria-label`. |
| `.ui-chip` | `<button class="ui-chip" aria-pressed="false">Imperfetto</button>` | Toggle chip with a fixed label; pressed = ink fill. Used by the Dicionário (tense switch). Chips **no longer filter the Library**: the Library filters with `.ui-facets` and their sheets. |
| `.ui-level` | `<span class="ui-level" data-level="a2">A2</span>` | Static CEFR tag, `a1`…`c2`, sage ramp. |
| `.ui-label` | `<p class="ui-label">Sinônimos</p>` | 11px caps micro-label. |
| `.ui-word` | `.is-hover` / `.is-active` · `.is-saved` · `.is-selected` (or `aria-current="true"`) | See states below. |
| `.ui-expression` | `<span class="ui-expression is-selected"><span class="ui-word">a</span> <span class="ui-word">un</span> …</span>` | Long-press selection across words: one grifo spanning the words and spaces + two handles. |
| `.ui-sentence` | `.is-active` (finger down) · `.is-selected` (paired) | Leitor com tradução. Neutral box: `--color-sentence-bg` / `--color-sentence-press-bg`, text `--color-sentence-ink`. Never yellow. Paragraph-in-focus gutter rule uses `--color-sentence-line`. |
| `.ui-search` | `<div class="ui-search"><i data-lucide="search"></i><input type="search"><button class="ui-iconbtn ui-search__clear" hidden>` · `--link` (field-shaped link) · `__value` + `__caret` (static typed text) | 44px surface pill; the focus ring moves to the whole pill. |
| `.ui-progress` | `<span class="ui-progress"><i style="--p:38%"></i></span>` · `--accent` | 2px line, `--color-rule` track, **ink** fill. `--accent` (yellow) only in the Reader. |
| `.ui-dock` / `__row` | dock = `.ui-progress--accent` on the top edge + one row: [`.ui-transport`] · `.ui-dock__pct` · `.ui-trbtn` | Reader and split reader (LEI-01). The transport exists only on a narrated story whose audio is ready (LEI-14). See "Reader dock" below. |
| `.ui-hero` | `__title` · `__sub` · `__meta` · `__pct` · `--compact` | "Continuar lendo", "Próxima história". As a link it darkens to surface-2 on hover/press. |
| `.ui-sechead` | `__title` (holds a `.ui-label`) · `__count` · `__action` (ghost sm button) | List group header. |
| `.ui-list` / `.ui-row` | `__main` (link) · `__text` · `__title` · `__meta` · `__value` · `--saved` · `--compact` + trailing `.ui-iconbtn--bookmark` | History, saved, suggestions, settings rows. |
| `.ui-empty` | `__icon` · `__title` · `__text` · `__action` · `--compact` | Empty / not found / offline. |
| `.ui-toast` | `<p class="ui-toast" role="status">` + `.is-shown` (2.6 s) · `--static` · `--action` + `__action` | Inside `.phone__screen`. With one action ("Desfazer"): `<div class="ui-toast ui-toast--action" role="status"><span>…</span><button class="ui-toast__action">Desfazer</button></div>`, shown for 6 s; the timer pauses while the toast has focus, and the focus is never moved to it. The action is underlined text in `--color-on-ink`, with an inset `--color-on-ink` focus ring. Used by "Já sei esta palavra", "Tirar da Revisão" and, when adopted, SAL-02 ("Removida das Salvas. Desfazer"). |
| `.ui-overlay` / `.ui-scrim` / `.ui-sheet` | `__head` · `__title` + `.ui-grip` · `--tall` (with `__count`, `__note`, `__body`, `__group`, `__more`, `__foot`) | Bottom sheet for quick settings (Aa) and, as `--tall`, the Library facet sheets (BIB-05). The dictionary never opens in a sheet. |
| `.ui-trbtn` / `__label` | `<button class="ui-trbtn" type="button"><i data-lucide="languages" aria-hidden="true"></i><span class="ui-trbtn__label" data-alt="Ocultar tradução">Mostrar tradução</span></button>` | Translation button (dock). See "Reader dock". |
| `.ui-transport` / `__play` | `<div class="ui-transport" role="group" aria-label="Narração">` + `.ui-iconbtn` (`skip-back`) + `.ui-transport__play` (`play`/`pause`) + `.ui-iconbtn` (`rotate-ccw`) | Narration transport (LEI-15). See "Reader dock". |
| `.ui-dock__pct` | `<span class="ui-dock__pct">36%<span> lido</span></span>` · "Lida" when completed (no inner span) | "N% lido" (LEI-07); shrinks on narrow screens. |
| `.ui-titlepage` | `__meta` (`.ui-level` + genre · tags) · `__title` · `__sub` · then `.ui-colophon` (or `.ui-wait`) | Story title page (LEI-13), first thing in the reading column, scrolls away with the text. Single and split view. |
| `.ui-colophon` | `<dl class="ui-colophon"><div><dt>Leitura</dt><dd>4 min · narração de 4:12<small>second line</small></dd></div>…</dl>` | Labelled rows, each only when it applies. Labels follow Immersion › Labels and buttons; the label column takes the widest label. Same component closes Ajustes › Sobre (AJU-04). |
| `.ui-wait` | `__icon` (`download`) · `__title` · `__text` · `.ui-progress` · `__actions` | Reader waiting for the files of a new language (BIB-12). `role="status"`. |
| `.ui-statusline` | `--notice` + `__link` | Library status line (BIB-13). See "Library" below. |
| `.ui-dot` | `<span class="ui-dot" aria-hidden="true"></span>` | 6px ink "new" marker: before "N histórias novas" and the card's "Chegou agora" (OFF-24). |
| `.ui-facets` / `.ui-facet` | `.is-selected` · `__v` | Library facet row and facet button (BIB-05). See "Library" below. |
| `.ui-check` | `__box` · `__name` (`<b>` = search match) · `__n` + a visually hidden `<input type="checkbox">` | Checklist row of the facet sheets (BIB-14). |
| `.ui-grip` | | 40×4 pill in `--color-ink-faint`; sheet handle and divider grip. |
| `.ui-divider` | `__handle` (`role="separator"`) · `__ratio` · `.is-hover` · `.is-active` (dragging) · `__handle.is-focus` (inset ring) | Split-reader divider. |
| `.ui-field` | `<div class="ui-field"><p class="ui-label">Entrelinha</p>control</div>` | Label stacked over a control. |
| `.ui-stack` / `__layer` / `__layer--top` | `data-state="pushed"` on the stack | Push navigation: the top layer slides in, the one below recedes 30%. |
| `.ui-scroll` | | Scrollable pane, hidden scrollbar, inset focus ring. |
| Entry pieces | `.ui-headword` · `.ui-pron` · `.ui-pos` (`<em>` class, `<b>` plural/auxiliary) · `.ui-block` (`--first`) · `.ui-senses` > `.ui-sense` > `.ui-sense__def` + `.ui-examples` > `.ui-example` · `.ui-reg` (`<abbr>` register/field label) · `.ui-wordlink` (`.is-saved`, `--inline`) · `.ui-table-wrap` > `.ui-table` | Dictionary entry, wherever it appears (dictionary, reader stubs, identity). |
| `.ui-segmented` | `<div class="ui-segmented" role="group" aria-label="…"><button aria-pressed="true">Italiano</button>…` | Immersion settings (Português \| Italiano), Histórico \| Salvas. |
| `.ipa` | `<span class="ipa">/fiˈnɛstra/</span>` | Only for IPA. |
| `.wordmark` | `<span class="wordmark">Post<span class="wordmark__i">ı</span>lla</span>` (ı = U+0131) | Set `font-size` only. The dot uses `--color-accent-mark`. |
| `.visually-hidden` | | Screen-reader-only text. |

### Reader dock (v0.4)

```html
<div class="ui-dock">
  <div class="ui-progress ui-progress--accent" aria-hidden="true"><i style="--p:36%"></i></div>
  <div class="ui-dock__row">
    <div class="ui-transport" role="group" aria-label="Narração">
      <button class="ui-iconbtn" type="button" aria-label="Frase anterior"><i data-lucide="skip-back" aria-hidden="true"></i></button>
      <button class="ui-transport__play" type="button" aria-label="Pausar narração"><i data-lucide="pause" aria-hidden="true"></i></button>
      <button class="ui-iconbtn" type="button" aria-label="Ouvir de novo"><i data-lucide="rotate-ccw" aria-hidden="true"></i></button>
    </div>
    <span class="ui-dock__pct">36%<span> lido</span></span>
    <button class="ui-trbtn" type="button"><i data-lucide="languages" aria-hidden="true"></i><span class="ui-trbtn__label" data-alt="Ocultar tradução">Mostrar tradução</span></button>
  </div>
</div>
```

- **Order is fixed:** transport · "N% lido" · translation button. Glyphs and text (not the 44px hit boxes) align to the 20px gutter on both ends, like the app bar; hit boxes reach 12px into the gutter.
- **Transport** (`.ui-transport`): three 44px targets, no gap. It appears whole and at once when the audio is ready (LEI-14) and never moves, so a second tap on the disc always pauses. Before the first Play both ends are `disabled`; on the story's first sentence "Frase anterior" is `disabled`. The disc (`.ui-transport__play`) is an ink circle with the glyph filled in `--color-on-ink`; it swaps glyph and label: "Ouvir narração a partir daqui" (`play`) → "Pausar narração" (`pause`) → "Continuar narração" (`play`). Never `aria-pressed`, never yellow. Without narration the group is absent and nothing else moves.
- **"N% lido"** (`.ui-dock__pct`): 16px after the last transport glyph. On narrow screens, with the transport present, "lido" leaves the screen below 386px and the number too below 360px (only the progress line remains); both stay in the accessible text. The rule queries the nearest inline-size container: `.phone__screen` in a phone. A dock shown outside a phone needs a book-local wrapper with `container-type: inline-size` at the screen width (identity uses `.id-strip`). Without the transport nothing shrinks.
- **Translation button** (`.ui-trbtn`): `--type-small`, `--color-ink`, no outline, no fill; hover = `--color-surface` pill, pressed = `--color-surface-2` pill, focus ring on the pill. `data-alt` on `__label` holds the other label so the box is as wide as the longer one ("Mostrar tradução" / "Ocultar tradução"; IT "Mostra traduzione" / "Nascondi traduzione"). The label is the state: never `aria-pressed`. No translation (TRA-10): `aria-disabled="true"` + `aria-describedby` pointing to a `.visually-hidden` hint, colour `--color-ink-faint`, no pill. It stays focusable so the hint is reachable.
- Forced states: `.ui-trbtn` and `.ui-transport__play` take `.is-hover` / `.is-active` / `.is-focus`.

### Title page, colophon and wait (v0.4)

```html
<header class="ui-titlepage" lang="it">
  <p class="ui-titlepage__meta"><span class="ui-level" data-level="a2">A2</span><span lang="pt-BR">Viagem · Emília-Romanha</span></p>
  <h1 class="ui-titlepage__title">Il treno per Bologna</h1>
  <p class="ui-titlepage__sub">Marta va a trovare la nonna dopo due anni.</p>
  <dl class="ui-colophon" lang="pt-BR">
    <div><dt>Texto</dt><dd>Carlo Collodi · adaptado<small>Licença CC BY-SA 4.0</small></dd></div>
    <div><dt>Leitura</dt><dd>4 min · narração de 4:12</dd></div>
    <div><dt>Vocabulário</dt><dd>92% das palavras são do vocabulário básico<small>Nuovo vocabolario di base, De Mauro (NVdB)</small></dd></div>
    <div><dt>Tradução</dt><dd>Ainda não existe em português<small>one line of why</small></dd></div>
  </dl>
</header>
```

- The title page is the top of the reading column (single and split view) and scrolls away with the text. Meta line = level + genre · tags (in the Navigation language); title in `--type-title-lg`, subtitle in italic `--type-lead`, both always Italian.
- Colophon rows appear only when they apply (LEI-13): "Texto" only for a license other than `LicenseRef-Postilla`, "narração de m:ss" only once the audio is on the device, "Vocabulário" only with band data, "Tradução" only without a translation. `<small>` is the muted second line. The license name is plain text, never a link.
- Ajustes › Sobre reuses `.ui-colophon` as is ("App", "Dicionário" + dump date, "Histórias" + "Sincronização 42"), inside a book-local surface card with the wordmark and the credits.
- Wait (BIB-12) replaces the colophon and the text, inside the title page:

```html
<div class="ui-wait" lang="pt-BR" role="status">
  <span class="ui-wait__icon"><i data-lucide="download" aria-hidden="true"></i></span>
  <p class="ui-wait__title">O português ainda está chegando</p>   <!-- target file missing too: "Esta história ainda está chegando" -->
  <p class="ui-wait__text">… quando a tradução terminar de baixar, a história abre sozinha.</p>
  <span class="ui-progress" aria-hidden="true"><i style="--p:60%"></i></span>
  <div class="ui-wait__actions">
    <button class="ui-btn ui-btn--primary ui-btn--block" type="button">Ler sem tradução</button>   <!-- only when the target file is on the device -->
    <button class="ui-btn ui-btn--ghost ui-btn--block" type="button">Voltar à biblioteca</button>
  </div>
</div>
```

### Library (v0.4)

Status line (BIB-13), one line under the large title, `role="status"`, no close button. In priority order:

```html
<div class="ui-statusline ui-statusline--notice" role="status"><i data-lucide="circle-arrow-up" aria-hidden="true"></i>
  <span>Há histórias novas que esta versão do app não abre.</span>
  <a class="ui-statusline__link" href="…">Atualizar na loja<i data-lucide="external-link" aria-hidden="true"></i></a></div>   <!-- OFF-26 -->
<p class="ui-statusline" role="status"><span class="ui-dot" aria-hidden="true"></span><span><b>3 histórias novas</b> chegaram</span></p>   <!-- OFF-24 -->
<p class="ui-statusline" role="status">152 histórias no aparelho</p>
```

Put it right after `.ui-largetitle` (the title then drops its bottom padding). Ink and muted ink only: the notice is not an error (no error colour, nothing blocked). The link is underlined text with a 44px target.

Facets (BIB-05), a fixed row under the search field, always Nível · Gênero · Tema:

```html
<div class="ui-facets" role="group" aria-label="Filtros">
  <button class="ui-facet" type="button" aria-haspopup="dialog" aria-expanded="false">Nível<i data-lucide="chevron-down" aria-hidden="true"></i></button>
  <button class="ui-facet is-selected" type="button" aria-haspopup="dialog" aria-expanded="false"><span class="visually-hidden">Gênero: </span><span class="ui-facet__v">Conto</span><i data-lucide="chevron-down" aria-hidden="true"></i></button>
  <button class="ui-facet is-selected" type="button" aria-haspopup="dialog" aria-expanded="false">Tema · 3<span class="visually-hidden"> selecionados</span><i data-lucide="chevron-down" aria-hidden="true"></i></button>
</div>
```

- Closed summary: nothing checked = the facet name; one value = the value (`__v`, cut with an ellipsis); several = "name · N". `.is-selected` (at least one value checked) = ink fill. The text changes with the state, so the state is never colour alone. The accessible name always carries the facet ("Nível: A2", "Tema · 3 selecionados").
- 36px pill with a 44px hit area, like `.ui-btn--sm`. Below a 350px screen the row tightens and selected facets drop the chevron, so three facets still fit one line.
- Not `aria-pressed`: a facet opens a dialog (`aria-haspopup="dialog"`, `aria-expanded`).

Facet sheet = `.ui-sheet.ui-sheet--tall` in a `.ui-overlay` (child of `.phone__screen`):

```html
<div class="ui-sheet ui-sheet--tall" role="dialog" aria-modal="true" aria-labelledby="s-tema">
  <span class="ui-grip" aria-hidden="true"></span>
  <div class="ui-sheet__head"><h3 class="ui-sheet__title" id="s-tema">Tema<span class="ui-sheet__count">92 temas</span></h3>
    <button class="ui-btn ui-btn--ghost ui-btn--sm" type="button" aria-label="Limpar tema">Limpar</button></div>
  <p class="ui-sheet__note">Números contam o filtro de <b>Nível</b>.</p>
  <div class="ui-search">…</div>                                   <!-- only for a facet with more than 12 values -->
  <div class="ui-sheet__body">
    <p class="ui-label ui-sheet__group"><span>Marcados</span><span>3</span></p>
    <div role="group" aria-label="Temas marcados">
      <label class="ui-check"><input class="visually-hidden" type="checkbox" checked><span class="ui-check__box" aria-hidden="true"><i data-lucide="check"></i></span>
        <span class="ui-check__name">Comida</span><span class="ui-check__n">7<span class="visually-hidden"> histórias</span></span></label>
    </div>
    <button class="ui-sheet__more" type="button" aria-expanded="false"><span>71 temas sem histórias com esses filtros</span><i data-lucide="chevron-down" aria-hidden="true"></i></button>
  </div>
  <div class="ui-sheet__foot"><p class="visually-hidden" role="status">9 histórias</p><button class="ui-btn ui-btn--primary ui-btn--block" type="button">Ver 9 histórias</button></div>
</div>
```

- Height = the screen minus the status bar and 20px; the head, note and search stay, `__body` scrolls, `__foot` stays at the bottom with a hairline above.
- "Limpar" clears this facet only and is `disabled` while nothing is checked.
- `__note` is the muted meta line: the context above the search, naming the other active facets and the search, never their values ("Números contam os filtros de Nível e Gênero e a busca."); a tip under the results; or, alone, a sheet search that finds nothing ("Nenhum tema com “fantasma”."). With nothing checked the list has no `__group` label.
- `__group`: a `.ui-label` with its count on the right ("Marcados 3", "Outros temas 18", "2 de 92 temas").
- `__more`: the last line collapsing the zero values ("10 gêneros sem histórias com esses filtros"); `aria-expanded` and `chevron-down` ↔ `chevron-up`. Opened, the zero values follow as disabled `.ui-check` rows.
- **No yellow** anywhere in the sheet.

Checklist row (`.ui-check`): a 20px box (`--radius-mark`, 1.5px `--color-ink-muted` outline; checked = ink fill with an on-ink `check`), the name in `--type-body`, the count in `--type-meta`. The state lives on the real `<input type="checkbox">` (`checked`, `disabled`); the row shows its focus ring inside. Disabled (zero with the other filters, BIB-14) = `--color-ink-faint` name and count, "0 de 6". A search match is `<b>` inside `__name`: semibold and underlined, never colour. Forced states: `.is-hover`, `.is-active`, `.is-focus`.

### Added in v0.4

- `.ui-trbtn` (+ `__label`): the translation button, unoutlined, three states in one box (replaces `.ui-btn--secondary.ui-btn--sm` in the dock).
- `.ui-transport` (+ `__play`): narration transport in the dock.
- `.ui-dock__pct`: "N% lido" with the narrow-screen rule.
- `.ui-titlepage` (+ `.ui-titlepage__meta`, `.ui-titlepage__title`, `.ui-titlepage__sub`) and `.ui-colophon`: story title page; the colophon also in Ajustes › Sobre.
- `.ui-wait` (+ `.ui-wait__icon`, `.ui-wait__title`, `.ui-wait__text`, `.ui-wait__actions`): Reader wait after a language switch.
- `.ui-statusline` (+ `--notice`, `__link`) and `.ui-dot`: Library status line and the "new" marker.
- `.ui-facets` / `.ui-facet` (+ `.is-selected`, `__v`): Library facets.
- `.ui-sheet--tall` (+ `__count`, `__note`, `__body`, `__group`, `__more`, `__foot`): Library facet sheet.
- `.ui-check` (+ `__box`, `__name`, `__n`): checklist row.
- No new tokens. Literal sizes kept from the mocks (no token fits): the 6px `.ui-dot`, the 14px `check` glyph with a 2.25px stroke inside the 20px box, the facet's 36px height (same as `.ui-btn--sm`), and the 10px / 6px facet padding and gap below a 350px screen.

### Word highlight states

| State | Class | Look | Meaning |
|---|---|---|---|
| default | `.ui-word` | no decoration | any Italian word; tappable |
| hover / pressed | `:hover`, `.is-hover` or `.is-active` | `--color-word-hover-bg` box | pointer hover; on touch, while the finger is down |
| saved | `.is-saved` | dotted 2px underline in `--color-word-saved` (ink-faint) | user saved this word |
| selected | `.is-selected` | **grifo**: `--color-accent-soft` box + 2px `--color-word-selected-line` underline | word whose entry is open / just tapped |
| saved + selected | `.is-saved.is-selected` | selected wins | — |
| expression selected | `.ui-expression.is-selected` around several `.ui-word` | the same grifo spanning the words **and** the spaces, plus two selection handles (2px stem + knob in `--color-word-selected-line`) | long-press + drag; opens the expression's entry |

Never color the word text itself. Never use bold for state.

### Forced states (for side-by-side state grids)

One convention for every book: add `.is-hover`, `.is-active` (pressed) or `.is-focus` to freeze a state in a mockup. Works on every `ui-*` control above (v0.4: `.ui-trbtn`, `.ui-transport__play`, `.ui-facet`, `.ui-check` take all three; `.ui-sheet__more` and `.ui-statusline__link` take `.is-hover`); book-local components define their own `.lib-card.is-active` etc. with the same three classes. Never `data-force`. Selection is `.is-selected`; use `disabled` and `aria-pressed` as in production.

### Tokens added in v0.3 (`tokens.css`)

- `--color-sentence-bg` / `--color-sentence-press-bg` / `--color-sentence-ink` / `--color-sentence-line`: sentence pairing and the paragraph-in-focus rule. Neutral (rule, surface-2, ink, rule-strong), defined for both themes. Never yellow.
- `--text-reader-1-size` … `--text-reader-5-size` (18 · 20 · 22 · 24 · 26px; step 2 = `--text-reader-size`) and `--leading-reader-compact / -default / -loose` (1.5 · 1.7 · 2): the Aa sheet steps. Line height = size × leading.
- `--border-mark` (2px: grifo/saved underline, progress, active-tab bar, paragraph rule) and `--border-focus` (2px focus ring).

### Pending requests to the brand lead (from `book-revisao.html` › Em aberto)

- Revisão tab icon (A1) and the four verdict/link icons (A2), above.
- `.ui-tabbar` with 4 tabs and `.ui-toast--action` are already in `book.css` with existing tokens only (A3): confirm or adjust.
- A field-outline token with 3:1 contrast at rest (A4). `--color-rule-strong`, today's input outline, gives 1.66:1 on light and 1.91:1 on dark.
- Promote the "Nella storia" card (`.dic-ctx`, copied as `.rev-ctx`) and the gloss pill (`.dic-gloss`, copied as `.rev-gloss`) to `book.css` (A5).
- A `.ui-menu` for "Mais opções" (A6): every book mocks those actions in a toast today.

---

## 3. Phone frame

```html
<figure class="phone" aria-label="Leitor — tradução oculta">
  <div class="phone__device">
    <div class="phone__screen">            <!-- add data-theme="dark" here to force dark -->
      <div class="phone__status" aria-hidden="true">
        <span>9:41</span><span class="phone__status-icons"><i></i><i></i><b></b></span>
      </div>
      <div class="phone__body">
        <!-- .ui-appbar, then .phone__scroll (content), then optional .ui-tabbar -->
      </div>
      <div class="phone__home" aria-hidden="true"></div>
    </div>
  </div>
  <figcaption class="phone__caption"><strong>Leitor</strong> · tradução oculta</figcaption>
</figure>
```

The frame is fluid from about 330px to 410px wide (390pt screen + bezel) with a fixed 390:844 ratio. Lay screens out with flex/grid and `--gutter` (20px), never absolute pixel positions. Content that overflows `.phone__scroll` clips. Caption format: `<strong>Tela</strong> · estado`.

---

## 4. Book page skeleton

File names: `book-biblioteca.html`, `book-leitor.html`, `book-leitor-traducao.html`, `book-dicionario.html`, `book-revisao.html`, `book-ajustes.html` (future), all in `design/`. `<title>` = `Postilla · <Área>`.

```html
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" href="data:,">
  <title>Postilla · Leitor</title>
  <link rel="stylesheet" href="tokens.css">
  <link rel="stylesheet" href="book.css">
  <style>/* book-specific rules only, prefixed rd- / tr- / lib- / dic- / set-; never targeting ui-* / book-* */</style>
</head>
<body class="book">
  <a class="book-skip" href="#conteudo">Pular para o conteúdo</a>
  <header class="book-header">
    <div class="book-wrap">
      <div class="book-topline">
        <a class="book-brand" href="identity.html">Postilla<span class="book-brand__dot" aria-hidden="true">.</span></a>
        <button class="ui-btn ui-btn--ghost ui-btn--sm" type="button" data-theme-toggle>Tema: automático</button>
      </div>
      <p class="book-series">Livro 2 de 5 · Leitor</p>
      <h1 class="book-title">Leitor</h1>
      <p class="book-lede">Uma frase que diz o que este livro resolve.</p>
      <nav class="book-toc" aria-label="Seções"><a href="#estrutura">Estrutura</a><a href="#estados">Estados</a></nav>
    </div>
  </header>

  <main id="conteudo">
    <section class="book-section" id="estados" aria-labelledby="estados-h">
      <div class="book-wrap">
        <header class="book-section__head">
          <p class="book-kicker">02</p>
          <h2 class="book-h2" id="estados-h">Estados da palavra</h2>
          <p class="book-note">Por que existe, quando usar.</p>
        </header>

        <div class="book-states">                       <!-- states side by side -->
          <figure class="book-state">
            <div class="book-state__stage on-bg"><!-- component --></div>
            <figcaption class="book-state__label"><strong>Padrão</strong> · sem marca</figcaption>
          </figure>
        </div>

        <h3 class="book-h3">Telas</h3>
        <div class="book-screens"><!-- .phone figures --></div>

        <dl class="book-spec"><dt>Fonte</dt><dd><code>--type-reader</code></dd></dl>
      </div>
    </section>
  </main>

  <footer class="book-footer"><div class="book-wrap">Postilla · sistema v0.4</div></footer>

  <script>
  /* theme toggle: auto → light → dark */
  (() => {
    const btn = document.querySelector('[data-theme-toggle]'); if (!btn) return;
    const order = ['auto', 'light', 'dark'], label = { auto: 'automático', light: 'claro', dark: 'escuro' };
    let i = 0;
    btn.addEventListener('click', () => {
      i = (i + 1) % 3; const t = order[i];
      if (t === 'auto') document.documentElement.removeAttribute('data-theme');
      else document.documentElement.setAttribute('data-theme', t);
      btn.textContent = 'Tema: ' + label[t];
    });
  })();
  </script>
</body>
</html>
```

Book layout classes: `.book` (on body), `.book-wrap` (16px gutter on phones, 32px from 768px), `.book-skip`, `.book-header`, `.book-topline`, `.book-brand` / `.book-brand__dot`, `.book-series`, `.book-title`, `.book-lede`, `.book-toc`, `.book-section`, `.book-section__head`, `.book-kicker`, `.book-h2`, `.book-h3`, `.book-note`, `.book-states` (`--wide` for 320px cells) / `.book-state` (`--span` = full row) / `.book-state__stage` (`.on-bg` = page background with hairline) / `.book-state__fill` / `.book-state__label`, `.book-screens`, `.book-spec`, `.book-footer`.

Book furniture (shared, never re-create locally):

| Class | Use |
|---|---|
| `.book-prose`, `.book-muted`, `.book-cols`, `.book-card`, `.book-callout` | running text, muted text, auto-fit columns, surface card, surface note |
| `.book-feature` | phone (or specimen) + legend/aside side by side |
| `.book-pin` · `.book-legend` · `.book-pinned [data-pin]` | numbered anatomy pins (20px ink disc) and their legend; position pins with a local class (`rd-at--tl`) |
| `.book-board` > `figure` + `.book-frame` | storyboard of a transition, 3:2 frames |
| `.book-table` (`--keyed`, `--stack`) · `.book-table-wrap` | documentation tables; `--stack` turns rows into cards ≤ 600px (`data-l` labels) |
| `.book-dd` > `figure` + `.book-dd__stage` + `.book-dd__tag--do / --dont` | do / don't pairs |
| `.book-code` + `.book-code__c` | pseudo-code block and comments |

Rules for books:
- Section order: 01 Estrutura (anatomy) → 02 Estados → 03 Telas (phones) → 04 Especificação → 05 Conteúdo/cópia.
- State figures always in this order: **padrão, hover, pressionado, foco, selecionado, desativado** (omit the ones that do not apply; never reorder).
- Every page head carries `<link rel="icon" href="data:,">` (no favicon request, no console 404).
- Show at least one phone with `data-theme="dark"` on `.phone__screen` next to its light twin.
- Italian content inside mockups gets `lang="it"`; Portuguese chrome inherits `lang="pt-BR"`.
- No lorem ipsum. Italian content is real, graded A1–B2.
