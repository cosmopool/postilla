# Postilla — componentes compartilhados (v0.3)

Spec for the 4 book designers (Biblioteca, Leitor, Dicionário, Ajustes/Imersão).

**All shared CSS lives in `book.css`.** Every book links two files and nothing else is shared:

```html
<link rel="stylesheet" href="tokens.css">
<link rel="stylesheet" href="book.css">
```

Do not copy, fork or override `ui-*`, `phone*`, `book-*`, `wordmark*` or `is-*` classes, and never write a local rule whose selector mentions a `ui-*` or `book-*` class (not even as an ancestor): add a local class to the element instead. If you need a variant that does not exist, ask the brand lead so it lands in `book.css` for everyone. Book-specific rules go in your own `<style>` with your prefix: `lib-` (Biblioteca), `rd-` (Leitor), `tr-` (Leitor com tradução), `dic-` (Dicionário), `set-` (Ajustes), `id-` (identity.html). No literal hex in a book: if a value is missing, it goes into `tokens.css`.

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
| Toggles | One signal per state. A button whose **label changes** with its state ("Mostrar tradução" ↔ "Ocultar tradução") must **not** also carry `aria-pressed`: screen readers would announce "Ocultar tradução, pressed", which is double (and contradictory) signalling. The label is the state; the button keeps its outline look in both states. `aria-pressed` is only for toggles whose label never changes (chips, segmented, bookmark, Aa). |
| Gestures on words | **Tap** a word = dictionary entry, pushed as a full page (+ grifo). **Long-press** (500 ms) a word = select an **expression**: the grifo gets two handles and dragging extends it word by word within the paragraph (Leitor com tradução: within the sentence), e.g. «a un certo punto»; on release the expression opens in the dictionary as a full page. **Saving** a word or expression is done only with the bookmark in the dictionary entry; no gesture in the story saves. In the split reader, tapping outside a word (or anywhere in the Portuguese half) pairs the sentence. |

### Where the one yellow goes, per screen

| Screen | The single yellow element | Plus |
|---|---|---|
| Biblioteca (tab root) | active-tab bar | — (no grifo; card progress is ink) |
| Leitor | reading progress line in the dock (`.ui-progress--accent`) | grifo on the selected word / expression |
| Leitor com tradução | the same reading progress line in the dock | grifo; the paired sentence is **neutral** (`--color-sentence-*`), divider and paragraph marker are neutral |
| Dicionário, pushed from the Reader (no tab bar) | grifo on the word inside the "Nella storia" snippet | nothing else; gloss, chips, labels are ink |
| Dicionário tab root (Histórico \| Salvas, search) and entries pushed inside the tab | active-tab bar | the "Nella storia" snippet drops its grifo (ink underline only) |
| Ajustes | active-tab bar | — |

## 1. Navigation (decided)

- **Bottom tab bar, 3 tabs:** `Biblioteca` · `Dicionário` · `Ajustes`. Active tab = ink label, weight 600, and a 2px yellow bar under the label.
- **Saved words live inside Dicionário**, as a `.ui-segmented` switch at the top of the tab root: `Histórico | Salvas`.
- The **Reader** is not a tab. It is pushed from Biblioteca and is full-screen with no tab bar. A dictionary entry opened from the Reader is a pushed full page ("Voltar à história") with no tab bar either.
- **Top app bar:** `large` on tab roots (display title under a 56px bar) and `compact` on pushed pages (back + centered title + **up to 3** trailing icon buttons, e.g. dictionary entry: `volume-2`, `bookmark`, `ellipsis`).

Icons: [Lucide](https://lucide.dev) pinned `lucide@0.460.0`, stroke 1.5. Names: `library-big` (Biblioteca), `book-a` (Dicionário), `settings-2` (Ajustes), `chevron-left`, `search`, `bookmark` (saved = same glyph filled via `.ui-iconbtn--bookmark[aria-pressed="true"]`), `volume-2`, `a-large-small`, `rows-2` (tradução dividida), `languages`, `ellipsis`, `x`, `check`.

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
| `.ui-tabbar` / `.ui-tab` | `<nav class="ui-tabbar" aria-label="Principal"><a class="ui-tab" aria-current="page">…` | Exactly 3 tabs. The active one gets `aria-current="page"`. |
| `.ui-btn` | `--primary` (ink) · `--secondary` (ink outline) · `--ghost` · `--accent` (yellow fill, ink text; 1 per flow) · `--sm` · `--block` | A fixed-label toggle uses `aria-pressed`; `--secondary[aria-pressed="true"]` turns ink. The translation button is **not** such a toggle: it swaps its label and has no `aria-pressed`. Disabled via `disabled`. |
| `.ui-iconbtn` | `--filled` · `--bookmark` | 44px circle. `aria-pressed="true"` = ink disc, except `--bookmark`, which fills the glyph in `--color-word-saved-mark`. Always has `aria-label`. |
| `.ui-chip` | `<button class="ui-chip" aria-pressed="false">Mistério</button>` | Filter chip; pressed = ink fill. |
| `.ui-level` | `<span class="ui-level" data-level="a2">A2</span>` | Static CEFR tag, `a1`…`c2`, sage ramp. |
| `.ui-label` | `<p class="ui-label">Sinônimos</p>` | 11px caps micro-label. |
| `.ui-word` | `.is-hover` / `.is-active` · `.is-saved` · `.is-selected` (or `aria-current="true"`) | See states below. |
| `.ui-expression` | `<span class="ui-expression is-selected"><span class="ui-word">a</span> <span class="ui-word">un</span> …</span>` | Long-press selection across words: one grifo spanning the words and spaces + two handles. |
| `.ui-sentence` | `.is-active` (finger down) · `.is-selected` (paired) | Leitor com tradução. Neutral box: `--color-sentence-bg` / `--color-sentence-press-bg`, text `--color-sentence-ink`. Never yellow. Paragraph-in-focus gutter rule uses `--color-sentence-line`. |
| `.ui-search` | `<div class="ui-search"><i data-lucide="search"></i><input type="search"><button class="ui-iconbtn ui-search__clear" hidden>` · `--link` (field-shaped link) · `__value` + `__caret` (static typed text) | 44px surface pill; the focus ring moves to the whole pill. |
| `.ui-progress` | `<span class="ui-progress"><i style="--p:38%"></i></span>` · `--accent` | 2px line, `--color-rule` track, **ink** fill. `--accent` (yellow) only in the Reader. |
| `.ui-dock` / `__row` | dock = `.ui-progress--accent` on the top edge + one row (meta left, translation button right) | Reader and split reader. |
| `.ui-hero` | `__title` · `__sub` · `__meta` · `__pct` · `--compact` | "Continuar lendo", "Próxima história". As a link it darkens to surface-2 on hover/press. |
| `.ui-sechead` | `__title` (holds a `.ui-label`) · `__count` · `__action` (ghost sm button) | List group header. |
| `.ui-list` / `.ui-row` | `__main` (link) · `__text` · `__title` · `__meta` · `__value` · `--saved` · `--compact` + trailing `.ui-iconbtn--bookmark` | History, saved, suggestions, settings rows. |
| `.ui-empty` | `__icon` · `__title` · `__text` · `__action` · `--compact` | Empty / not found / offline. |
| `.ui-toast` | `<p class="ui-toast" role="status">` + `.is-shown` (2.6 s) · `--static` | Inside `.phone__screen`. |
| `.ui-overlay` / `.ui-scrim` / `.ui-sheet` | `__head` · `__title` + `.ui-grip` | Bottom sheet for quick settings (Aa). The dictionary never opens in a sheet. |
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

One convention for every book: add `.is-hover`, `.is-active` (pressed) or `.is-focus` to freeze a state in a mockup. Works on every `ui-*` control above; book-local components define their own `.lib-card.is-active` etc. with the same three classes. Never `data-force`. Selection is `.is-selected`; use `disabled` and `aria-pressed` as in production.

### Tokens added in v0.3 (`tokens.css`)

- `--color-sentence-bg` / `--color-sentence-press-bg` / `--color-sentence-ink` / `--color-sentence-line`: sentence pairing and the paragraph-in-focus rule. Neutral (rule, surface-2, ink, rule-strong), defined for both themes. Never yellow.
- `--text-reader-1-size` … `--text-reader-5-size` (18 · 20 · 22 · 24 · 26px; step 2 = `--text-reader-size`) and `--leading-reader-compact / -default / -loose` (1.5 · 1.7 · 2): the Aa sheet steps. Line height = size × leading.
- `--border-mark` (2px: grifo/saved underline, progress, active-tab bar, paragraph rule) and `--border-focus` (2px focus ring).

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

File names: `book-biblioteca.html`, `book-leitor.html`, `book-dicionario.html`, `book-ajustes.html`, all in `design/`. `<title>` = `Postilla · <Área>`.

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

  <footer class="book-footer"><div class="book-wrap">Postilla · sistema v0.3</div></footer>

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
