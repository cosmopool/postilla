// Dicionário: verbete (DIC-01..09), página de escolha de lema (LEI-02, DIC-07),
// raiz da aba com a busca (DIC-10, DIC-11) e o "Você quis dizer".
import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../main.dart' show AppTab, tabReselected;
import '../settings/settings.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// De onde o verbete foi aberto, quando foi de uma história ("Nella storia", DIC-04).
class StoryContext {
  const StoryContext({
    required this.title,
    required this.paragraph,
    required this.sentence,
    required this.hlStart,
    required this.hlEnd,
    required this.form,
  });
  final String title;
  final int paragraph; // a partir de 0
  final String sentence;
  final int hlStart, hlEnd; // trecho grifado, relativo à frase
  final String form; // a forma tocada ("si siede")
}

// ---------------------------------------------------------------- abrir

/// Pilha de verbetes por Navigator (DIC-06): até 20; o mais antigo sai.
final _stacks = Expando<List<Route<void>>>();
const maxEntries = 20;

/// Abre o resultado de uma consulta: sem lema, aviso; um lema, o verbete;
/// mais de um, a página de escolha.
Future<void> openLookup(
  BuildContext context, {
  required List<EntryRef> refs,
  required String backLabel,
  StoryContext? story,
  bool root = false,
}) async {
  final navigator = Navigator.of(context, rootNavigator: root);
  if (refs.isEmpty) {
    showToast(context, ui.noEntry);
    return;
  }
  if (refs.length == 1) {
    await pushEntry(navigator, refs.first, backLabel: backLabel, story: story);
    return;
  }
  await navigator.push(PushRoute(ChoicePage(refs: refs, backLabel: backLabel, story: story)));
}

Future<void> pushEntry(NavigatorState navigator, EntryRef ref, {required String backLabel, StoryContext? story}) async {
  final stack = _stacks[navigator] ??= [];
  if (stack.length >= maxEntries) {
    final oldest = stack.removeAt(0);
    if (oldest.isActive) navigator.removeRoute(oldest);
  }
  final route = PushRoute<void>(EntryPage(ref: ref, backLabel: backLabel, story: story));
  stack.add(route);
  await navigator.push(route);
  stack.remove(route);
}

// ---------------------------------------------------------------- escolha de lema

class ChoicePage extends StatelessWidget {
  const ChoicePage({super.key, required this.refs, required this.backLabel, this.story});
  final List<EntryRef> refs;
  final String backLabel;
  final StoryContext? story;

  @override
  Widget build(BuildContext context) {
    watchSettings(context);
    final t = context.tk;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CompactBar(backLabel: backLabel, title: ui.chooseEntry, scrolled: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final r in refs)
                    ListRow(
                      title: r.lemma,
                      meta: r.meta,
                      compact: true,
                      glyph: Glyphs.bookA,
                      titleWidget: Text(
                        r.lemma,
                        style: T.body.copyWith(color: t.ink),
                        locale: const Locale('it'),
                      ),
                      onTap: () => pushEntry(Navigator.of(context), r, backLabel: ui.backTo(ui.chooseEntry), story: story),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- verbete

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.ref, required this.backLabel, this.story});
  final EntryRef ref;
  final String backLabel;
  final StoryContext? story;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

const _tenseNames = {1: 'Presente', 2: 'Passato prossimo', 3: 'Imperfetto', 4: 'Futuro', 5: 'Imperativo'};
const _persons = ['io', 'tu', 'lui/lei', 'noi', 'voi', 'loro'];
const _clitics = {'mi', 'ti', 'si', 'ci', 'vi'};

class _EntryPageState extends State<EntryPage> {
  Entry _e = Entry.nil;
  bool _loaded = false;
  bool _gloss = false; // sempre fechada ao abrir (DIC-03)
  int _tense = 1;
  final _scroll = ScrollController();
  final _headKey = GlobalKey();
  bool _scrolled = false, _titleOn = false;

  @override
  void initState() {
    super.initState();
    dbEntry(widget.ref).then((e) {
      if (!mounted) return;
      setState(() {
        _e = e;
        _loaded = true;
        _tense = _tenseOfForm(e, widget.story?.form ?? '') ?? (e.conj.isEmpty ? 1 : e.conj.first.tense);
      });
    });
    _scroll.addListener(() {
      final head = _headKey.currentContext?.findRenderObject() as RenderBox?;
      final titleOn = head != null && _scroll.offset > head.size.height + 8;
      final scrolled = _scroll.offset > 0;
      if (titleOn != _titleOn || scrolled != _scrolled) {
        setState(() {
          _titleOn = titleOn;
          _scrolled = scrolled;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Tempo em que a forma da história aparece, para abrir a Conjugação nele (DIC-05).
  static int? _tenseOfForm(Entry e, String form) {
    if (form.isEmpty) return null;
    for (final c in e.conj) {
      if (c.forms.contains(form)) return c.tense;
    }
    return null;
  }

  void _more() {
    final t = context.tk;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: t.bg,
      barrierColor: t.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: t.inkFaint, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 8),
              ListRow(
                title: ui.copy,
                compact: true,
                onTap: () {
                  Navigator.pop(ctx);
                  copyText(context, _e.word);
                },
              ),
              if (widget.story != null)
                ListRow(
                  title: ui.backToStory,
                  compact: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _toStory();
                  },
                ),
              ListRow(
                title: ui.source,
                meta:
                    'Wikizionario, Wiktionary, WikDict · CC BY-SA',
                compact: true,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Volta direto à história: tira todos os verbetes e escolhas da pilha.
  void _toStory() => Navigator.of(context).popUntil((r) => r is! PushRoute || r.settings.name == 'reader');

  void _open(String word) async {
    final refs = await dbLemmas(word);
    if (!mounted) return;
    openLookup(context, refs: refs, backLabel: ui.backTo(_e.word), story: widget.story);
  }

  @override
  Widget build(BuildContext context) {
    final s = watchSettings(context);
    final t = context.tk;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CompactBar(
              backLabel: widget.backLabel,
              title: _e.word,
              titleVisible: _titleOn,
              scrolled: _scrolled,
              actions: [IconBtn(Glyphs.ellipsis, label: ui.moreOptions, onTap: _loaded && !_e.isNil ? _more : null)],
            ),
            Expanded(
              child: !_loaded
                  ? const SizedBox()
                  : _e.isNil
                  ? EmptyState(glyph: Glyphs.searchX, title: ui.noEntry)
                  : Semantics(
                      label: 'Conteúdo do verbete',
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                        children: _sections(t, s),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(Tokens t, Settings s) {
    final e = _e;
    const it = Locale('it');
    final out = <Widget>[];
    void section(String heading, List<Widget> body, {bool first = false}) {
      out.add(
        Container(
          margin: EdgeInsets.only(top: first ? 24 : 24),
          padding: EdgeInsets.only(top: first ? 0 : 20),
          decoration: first
              ? null
              : BoxDecoration(
                  border: Border(top: BorderSide(color: t.rule)),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [MicroLabel(heading, header: true), const SizedBox(height: 12), ...body],
          ),
        ),
      );
    }

    // 1. Lema e classe
    final plural = e.flex.where((f) => f.tags == 'plurale').map((f) => f.form).toList();
    out.add(
      KeyedSubtree(
        key: _headKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                e.word,
                style: T.headword.copyWith(color: t.ink),
                locale: it,
              ),
            ),
            if (e.ipa.isNotEmpty || e.syll.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (e.ipa.isNotEmpty)
                    ExcludeSemantics(
                      child: Text(e.ipa, style: T.ipa.copyWith(color: t.ink)),
                    ),
                  if (e.syll.isNotEmpty)
                    Semantics(
                      label: 'sillabazione: ${e.syll.join(' ')}',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            for (var i = 0; i < e.syll.length; i++) ...[
                              if (i > 0)
                                TextSpan(
                                  text: '  |  ',
                                  style: TextStyle(color: t.ruleStrong),
                                ),
                              TextSpan(text: e.syll[i]),
                            ],
                          ],
                        ),
                        style: T.small.copyWith(color: t.inkMuted),
                        locale: it,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: e.classLine,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  if (plural.isNotEmpty) ...[
                    const TextSpan(text: ' · plurale '),
                    TextSpan(
                      text: plural.join(', '),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                  ],
                  if (e.aux.isNotEmpty) ...[
                    const TextSpan(text: ' · ausiliare '),
                    TextSpan(
                      text: e.aux,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                  ],
                ],
              ),
              style: T.small.copyWith(color: t.inkMuted),
              locale: it,
            ),
          ],
        ),
      ),
    );

    // 2. Glosa PT (oculta; nenhuma com Glosas = Italiano, DIC-03)
    if (e.gloss.isNotEmpty && !s.glossIt) {
      out.add(const SizedBox(height: 24));
      out.add(
        Align(
          alignment: Alignment.centerLeft,
          child: _GlossPill(gloss: e.gloss.join(', '), open: _gloss, onTap: () => setState(() => _gloss = !_gloss)),
        ),
      );
    }

    // 3. Significati
    if (e.senses.isNotEmpty) {
      section(dict.meanings, [
        for (var i = 0; i < e.senses.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: T.number.copyWith(color: t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _sense(t, e.senses[i])),
              ],
            ),
          ),
      ], first: true);
    }

    // 4. Nella storia
    final st = widget.story;
    if (st != null) {
      section(dict.inTheStory, [_inStory(t, st)]);
    }

    // 5. Flessione / Coniugazione
    if (e.conj.isNotEmpty) {
      section(dict.conjugation, [_conjugation(t, e)]);
    } else if (e.flex.isNotEmpty) {
      section(dict.inflection, [_flexTable(t, e)]);
    }

    // 6. Etimologia
    if (e.etym.isNotEmpty) {
      section(dict.etymology, [Text(e.etym, style: T.def.copyWith(color: t.ink), locale: it)]);
    }

    // 7. Palavras que levam a outro verbete (DIC-06)
    void words(String heading, List<Link> list) {
      if (list.isEmpty) return;
      section(heading, [
        Wrap(
          spacing: 20,
          children: [for (final l in list) _WordLink(link: l, onTap: () => _open(l.word))],
        ),
      ]);
    }

    words(dict.synonyms, e.syn);
    words(dict.antonyms, e.ant);
    words(dict.derived, e.derived);
    words(dict.related, [for (final w in e.related) Link(w)]);
    words(dict.altered, e.altered);
    words(dict.confusables, [for (final w in e.confusables) Link(w)]);

    // 8. Atribuição (DIC-09): linha fixa.
    out.add(Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Text('Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA', style: T.meta.copyWith(color: t.inkMuted)),
    ));
    return out;
  }

  Widget _sense(Tokens t, Sense s) {
    const it = Locale('it');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              for (final l in s.labels)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: t.ruleStrong),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l,
                      style: T.meta.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              TextSpan(text: s.gloss),
            ],
          ),
          style: T.def.copyWith(color: t.ink),
          locale: it,
        ),
        if (s.examples.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: t.rule, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final x in s.examples.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      x,
                      style: T.def.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic),
                      locale: it,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _inStory(Tokens t, StoryContext st) {
    const it = Locale('it');
    final hl = st.hlStart >= 0 && st.hlEnd <= st.sentence.length && st.hlStart < st.hlEnd;
    return Pressable(
      onTap: _toStory,
      radius: 20,
      color: t.surface,
      hoverColor: Color.lerp(t.surface, t.surface2, 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '«'),
                  if (hl) ...[
                    TextSpan(text: st.sentence.substring(0, st.hlStart)),
                    TextSpan(
                      text: st.sentence.substring(st.hlStart, st.hlEnd),
                      style: TextStyle(
                        backgroundColor: t.wordSelectedBg,
                        decoration: TextDecoration.underline,
                        decorationColor: t.wordSelectedLine,
                        decorationThickness: 2,
                      ),
                    ),
                    TextSpan(text: st.sentence.substring(st.hlEnd)),
                  ] else
                    TextSpan(text: st.sentence),
                  const TextSpan(text: '»'),
                ],
              ),
              style: T.def.copyWith(color: t.ink),
              locale: it,
            ),
            if (st.form.isNotEmpty && st.form != _e.word) ...[
              const SizedBox(height: 8),
              Text(
                st.form,
                style: T.meta.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic),
                locale: it,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${st.title} · ¶${st.paragraph + 1}',
                    style: T.meta.copyWith(color: t.inkMuted),
                    locale: it,
                  ),
                ),
                Glyph(Glyphs.chevronRight, size: 20, color: t.inkMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(Tokens t, List<String> heads, List<List<Widget>> rows, {Set<int> highlight = const {}, bool rowHeaders = false}) {
    Widget cell(Widget c, {bool head = false, bool rowHead = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: DefaultTextStyle.merge(
        style: head
            ? T.label.copyWith(color: t.inkMuted)
            : (rowHead ? T.small.copyWith(color: t.inkMuted) : T.body.copyWith(color: t.ink)),
        child: c,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.rule),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: rowHeaders ? const {0: FractionColumnWidth(0.3)} : null,
        children: [
          TableRow(
            decoration: BoxDecoration(color: t.surface2),
            children: [for (final h in heads) cell(Text(h.toUpperCase()), head: true)],
          ),
          for (var i = 0; i < rows.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: highlight.contains(i) ? t.surface : null,
                border: i == rows.length - 1 ? null : Border(top: BorderSide(color: t.rule)),
              ),
              children: [for (var j = 0; j < rows[i].length; j++) cell(rows[i][j], rowHead: rowHeaders && j == 0)],
            ),
        ],
      ),
    );
  }

  Widget _flexTable(Tokens t, Entry e) {
    const it = Locale('it');
    final sing = [e.word, ...e.flex.where((f) => f.tags.contains('singolare')).map((f) => f.form)];
    final plur = e.flex.where((f) => f.tags.contains('plurale')).map((f) => f.form).toList();
    final other = e.flex.where((f) => !f.tags.contains('plurale') && !f.tags.contains('singolare')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _table(
          t,
          [dict.singular, dict.plural],
          [
            [Text(sing.join(', '), locale: it), Text(plur.join(', '), locale: it)],
          ],
        ),
        for (final f in other)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${f.tags} ${f.form}',
              style: T.small.copyWith(color: t.inkMuted),
              locale: it,
            ),
          ),
      ],
    );
  }

  Widget _conjugation(Tokens t, Entry e) {
    const it = Locale('it');
    final tenses = [
      for (final k in _tenseNames.keys)
        if (e.conj.any((c) => c.tense == k)) k,
    ];
    final storyForm = widget.story?.form ?? '';
    final rows = <List<Widget>>[];
    final highlight = <int>{};
    for (var p = 1; p <= 6; p++) {
      final c = e.conj.where((c) => c.tense == _tense && c.person == p).firstOrNull;
      if (c == null) continue;
      if (c.forms.contains(storyForm)) highlight.add(rows.length);
      rows.add([
        Text(_persons[p - 1], locale: it),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _form(t, c.forms.first),
            for (final alt in c.forms.skip(1))
              Text(
                'anche $alt',
                style: T.meta.copyWith(color: t.inkMuted),
                locale: it,
              ),
            if (c.forms.contains(storyForm))
              Text(
                ui.inTheStory,
                style: T.meta.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic),
                locale: it,
              ),
          ],
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _tense == 5 ? dict.imperative : dict.indicative,
          style: T.meta.copyWith(color: t.inkMuted),
          locale: it,
        ),
        Semantics(
          label: dict.tense,
          container: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final k in tenses) ...[
                  FilterChipBtn(_tenseNames[k]!, selected: _tense == k, onTap: () => setState(() => _tense = k)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          label: '${_tenseNames[_tense]} di ${e.word}',
          child: _table(t, [dict.person, dict.form], rows, highlight: highlight, rowHeaders: true),
        ),
        if (e.participle.isNotEmpty || e.gerund.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                if (e.participle.isNotEmpty) ...[
                  const TextSpan(text: 'participio passato '),
                  TextSpan(
                    text: e.participle,
                    style: TextStyle(
                      color: t.ink,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                  ),
                ],
                if (e.participle.isNotEmpty && e.gerund.isNotEmpty) const TextSpan(text: ' · '),
                if (e.gerund.isNotEmpty) ...[
                  const TextSpan(text: 'gerundio '),
                  TextSpan(
                    text: e.gerund,
                    style: TextStyle(
                      color: t.ink,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                  ),
                ],
              ],
            ),
            style: T.small.copyWith(color: t.inkMuted),
            locale: it,
          ),
        ],
      ],
    );
  }

  /// O pronome reflexivo (mi, ti, si…) em tinta suave; o resto em tinta.
  Widget _form(Tokens t, String form) {
    final sp = form.indexOf(' ');
    if (sp > 0 && _clitics.contains(form.substring(0, sp))) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: form.substring(0, sp + 1),
              style: TextStyle(color: t.inkMuted),
            ),
            TextSpan(text: form.substring(sp + 1)),
          ],
        ),
        locale: const Locale('it'),
      );
    }
    return Text(form, locale: const Locale('it'));
  }
}

class _GlossPill extends StatelessWidget {
  const _GlossPill({required this.gloss, required this.open, required this.onTap});
  final String gloss;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Pressable(
      onTap: onTap,
      selected: open,
      semanticLabel: open ? '${ui.glossPrefix}$gloss' : ui.showGloss,
      color: open ? t.surface : null,
      child: CustomPaint(
        painter: open ? null : _DashedPill(t.ruleStrong),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
          decoration: open
              ? BoxDecoration(
                  border: Border.all(color: t.rule, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                )
              : null,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: open ? t.bg : t.surface2, borderRadius: BorderRadius.circular(999)),
                  child: Text('PT', style: T.label.copyWith(color: t.ink)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(open ? gloss : ui.showGloss, style: T.body.copyWith(color: open ? t.ink : t.inkMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPill extends CustomPainter {
  _DashedPill(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), Radius.circular(size.height / 2));
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) => old.color != color;
}

class _WordLink extends StatelessWidget {
  const _WordLink({required this.link, required this.onTap});
  final Link link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pressable(
          onTap: onTap,
          radius: 4,
          hoverColor: t.wordHoverBg,
          pressedColor: t.wordHoverBg,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.centerLeft,
            child: Text(
              link.word,
              style: T.def.copyWith(color: t.ink, decoration: TextDecoration.underline, decorationColor: t.ruleStrong),
              locale: const Locale('it'),
            ),
          ),
        ),
        if (link.note.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '(${link.note})',
              style: T.small.copyWith(color: t.inkMuted),
              locale: const Locale('it'),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- raiz da aba e busca

class DictionaryRoot extends StatefulWidget {
  const DictionaryRoot({super.key});
  @override
  State<DictionaryRoot> createState() => _DictionaryRootState();
}

class _DictionaryRootState extends State<DictionaryRoot> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  List<SearchHit> _hits = const [];
  List<EntryRef> _guess = const [];
  String _searched = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query.addListener(_changed);
    _focus.addListener(() => setState(() {}));
    tabReselected.addListener(_reselected);
  }

  void _reselected() {
    if (tabReselected.value.$1 == AppTab.dictionary) {
      _query.clear();
      _focus.unfocus();
    }
  }

  @override
  void dispose() {
    tabReselected.removeListener(_reselected);
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    final q = _query.text;
    // Resultado a cada letra (DIC-11), sem martelar o banco no meio da digitação.
    _debounce = Timer(const Duration(milliseconds: 60), () async {
      if (q.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _hits = const [];
            _guess = const [];
            _searched = '';
          });
        }
        return;
      }
      final hits = await dbSearch(q);
      final guess = hits.isEmpty ? await dbDidYouMean(q) : const <EntryRef>[];
      if (!mounted || q != _query.text) return;
      setState(() {
        _hits = hits;
        _guess = guess;
        _searched = q.trim();
      });
    });
  }

  void _openHit(EntryRef r) => pushEntry(Navigator.of(context), r, backLabel: ui.backToDictionary);

  @override
  Widget build(BuildContext context) {
    watchSettings(context);
    final t = context.tk;
    final searching = _focus.hasFocus || _query.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!searching) ...[
          const SizedBox(height: 56),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Semantics(
              header: true,
              child: Text(nav.dictionary, style: T.title.copyWith(color: t.ink)),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(20, searching ? 8 : 0, searching ? 12 : 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SearchField(controller: _query, focusNode: _focus, hint: ui.searchItalian),
              ),
              if (searching) ...[
                const SizedBox(width: 4),
                Btn(
                  ui.cancel,
                  kind: BtnKind.ghost,
                  small: true,
                  onTap: () {
                    _query.clear();
                    _focus.unfocus();
                  },
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _body(t)),
      ],
    );
  }

  Widget _body(Tokens t) {
    final q = normalize(_query.text.trim());
    if (q.isEmpty || _searched.isEmpty && _hits.isEmpty) return _hints(t);
    if (_hits.isEmpty) {
      return ListView(
        children: [
          EmptyState(glyph: Glyphs.searchX, title: ui.noEntryFor(_searched), text: ui.checkSpelling),
          if (_guess.isNotEmpty) ...[
            SectionHeader(ui.didYouMean),
            for (final r in _guess)
              ListRow(
                title: r.lemma,
                meta: r.meta,
                compact: true,
                glyph: Glyphs.search,
                titleWidget: Text(
                  r.lemma,
                  style: T.body.copyWith(color: t.ink),
                  locale: const Locale('it'),
                ),
                onTap: () => _openHit(r),
              ),
          ],
        ],
      );
    }
    return Semantics(
      label: ui.suggestions,
      container: true,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          for (final h in _hits)
            ListRow(
              title: h.ref.lemma,
              meta: h.ref.meta,
              compact: true,
              glyph: Glyphs.search,
              titleWidget: _prefixTitle(t, h.ref.lemma, q),
              onTap: () => _openHit(h.ref),
            ),
          _hints(t, shrink: true),
        ],
      ),
    );
  }

  /// O prefixo digitado em tinta suave, o resto em tinta ("fines|tra").
  Widget _prefixTitle(Tokens t, String lemma, String q) {
    final n = normalize(lemma);
    final style = T.body.copyWith(color: t.ink);
    if (!q.contains('*') && !q.contains('?') && n.startsWith(q) && lemma.length == n.length) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: lemma.substring(0, q.length),
              style: TextStyle(color: t.inkMuted),
            ),
            TextSpan(text: lemma.substring(q.length)),
          ],
        ),
        style: style,
        locale: const Locale('it'),
      );
    }
    return Text(lemma, style: style, locale: const Locale('it'));
  }

  Widget _hints(Tokens t, {bool shrink = false}) {
    final style = T.small.copyWith(color: t.inkMuted);
    Widget key(String k) => Container(
          constraints: const BoxConstraints(minWidth: 24),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(4)),
          child: Text(k, textAlign: TextAlign.center, style: T.smallMedium.copyWith(color: t.ink, fontWeight: FontWeight.w600)),
        );
    // `?` e `*` soltos na frase viram teclas.
    final words = ui.hintWildcards.split(' ');
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ui.hintForms, style: style),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < words.length; i++) ...[
                  if (i > 0) const TextSpan(text: ' '),
                  if (words[i] == '?' || words[i] == '*')
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: key(words[i]))
                  else
                    TextSpan(text: words[i]),
                ],
              ],
            ),
            style: style,
          ),
        ],
      ),
    );
    return shrink ? body : ListView(children: [body]);
  }
}
