// Leitor (LEI-01..12) e Leitor com tradução (TRA-01..09). Todos os parágrafos
// fazem layout ao abrir (ARQ-52); as formas da história são resolvidas em lote
// para lemas (ARQ-53). A tela dividida sincroniza a rolagem por parágrafo,
// liderada pela última metade tocada (TRA-07, ARQ-56).
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../dictionary/dictionary.dart';
import '../library/library.dart' show genreName;
import '../settings/settings.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'paragraph.dart';

/// Abre o Leitor em tela cheia, sem barra de abas (NAV-02), sempre no início.
void openReader(BuildContext context, Story story, List<Story> catalog, Map<GenreId, Genre> genres) {
  Navigator.of(context, rootNavigator: true).push(
    PushRoute(
      ReaderPage(story: story, catalog: catalog, genres: genres),
      settings: const RouteSettings(name: 'reader'),
    ),
  );
}

/// Próxima história (LEI-10): continuação da obra; senão a seguinte do mesmo
/// nível na ordem do catálogo; senão a primeira do nível seguinte (nunca dois acima).
Story nextStory(Story s, List<Story> catalog) {
  if (s.work.isNotEmpty) {
    for (final c in catalog) {
      if (c.work == s.work && c.part == s.part + 1) return c;
    }
  }
  final i = catalog.indexWhere((c) => c.id == s.id);
  for (var j = i + 1; j < catalog.length; j++) {
    if (catalog[j].level == s.level) return catalog[j];
  }
  for (final c in catalog) {
    if (c.level.v == s.level.v + 1) return c;
  }
  return Story.nil;
}

/// Palavra do Leitor: parágrafo e índice da palavra nele.
typedef WordPos = ({int p, int w});

/// Linha de leitura da tela dividida: 24 px do topo de cada metade.
const _readingLine = 24.0;

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.story, required this.catalog, required this.genres});
  final Story story;
  final List<Story> catalog;
  final Map<GenreId, Genre> genres;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with TickerProviderStateMixin {
  List<Paragraph> _paras = const [];
  Map<String, List<EntryRef>> _lemmas = const {};
  bool _loaded = false;

  // Grifo: parágrafo, palavra inicial e final (-1 = nenhum).
  int _selP = -1, _selS = -1, _selE = -1, _anchor = -1;
  bool _handles = false;
  WordPos? _pressed;
  WordPos? _focusWord; // teclado (LEI-12)

  // Tela dividida
  late final AnimationController _open = AnimationController(vsync: this, duration: Motion.slow, reverseDuration: Motion.base);
  late final AnimationController _snap = AnimationController(vsync: this, duration: Motion.base);
  double _ratio = 0.5; // parte do italiano
  bool _dragging = false;
  int _actP = -1, _actS = -1; // frase ativa
  ({int p, int s, bool pt})? _pressedSentence;
  int _leader = 0; // 0 italiano · 1 português
  bool _syncing = false;
  int _focusPara = 0;

  final _itScroll = ScrollController();
  final _ptScroll = ScrollController();
  final _itCol = GlobalKey();
  final _ptCol = GlobalKey();
  final _titleKey = GlobalKey();
  List<GlobalKey> _itKeys = const [];
  List<GlobalKey> _ptKeys = const [];
  bool _titleOff = false;
  bool _sheetOpen = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ratio = settings.value.split / 100;
    _load();
    _itScroll.addListener(_onItScroll);
    _open.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final paras = await dbParagraphs(widget.story.id);
    final forms = <String>{};
    for (final p in paras) {
      for (final w in p.words) {
        forms.add(p.it.substring(w.start, w.end));
      }
    }
    final lemmas = await dbLemmasOf(forms.toList());
    if (!mounted) return;
    setState(() {
      _paras = paras;
      _lemmas = lemmas;
      _itKeys = [for (final _ in paras) GlobalKey()];
      _ptKeys = [for (final _ in paras) GlobalKey()];
      _loaded = true;
    });
    // A dica de primeira leitura aparece uma vez (LEI-11).
    WidgetsBinding.instance.addPostFrameCallback((_) => markHintSeen('reader'));
  }

  @override
  void dispose() {
    _open.dispose();
    _snap.dispose();
    _itScroll.dispose();
    _ptScroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _split => _open.value > 0 || _open.isAnimating;

  // ---------------------------------------------------------------- rolagem e sincronia

  void _onItScroll() {
    final title = _titleKey.currentContext?.findRenderObject() as RenderBox?;
    final off = title != null && _itScroll.offset > title.size.height + 40;
    final focus = _paraAtLine(_itCol, _itKeys, _itScroll);
    if (off != _titleOff || focus != _focusPara) {
      setState(() {
        _titleOff = off;
        _focusPara = focus;
      });
    }
  }

  /// Topo e altura de cada parágrafo no conteúdo rolável de uma metade.
  List<(double, double)> _tops(GlobalKey col, List<GlobalKey> keys) {
    final colBox = col.currentContext?.findRenderObject() as RenderBox?;
    if (colBox == null) return const [];
    return [
      for (final k in keys)
        if (k.currentContext?.findRenderObject() case final RenderBox b when b.attached)
          (b.localToGlobal(Offset.zero, ancestor: colBox).dy, b.size.height)
        else
          (0, 0),
    ];
  }

  int _paraAtLine(GlobalKey col, List<GlobalKey> keys, ScrollController sc) {
    if (!sc.hasClients) return 0;
    final line = sc.offset + _readingLine;
    final tops = _tops(col, keys);
    var i = 0;
    for (var j = 0; j < tops.length; j++) {
      if (tops[j].$1 <= line) i = j;
    }
    return i;
  }

  /// A metade que lidera informa o parágrafo na linha de leitura e a fração já
  /// rolada; a outra vai para o mesmo parágrafo e a mesma fração (ARQ-56).
  void _sync(int from) {
    if (!_split || _syncing) return;
    final (srcSc, srcCol, srcKeys) = from == 0 ? (_itScroll, _itCol, _itKeys) : (_ptScroll, _ptCol, _ptKeys);
    final (dstSc, dstCol, dstKeys) = from == 0 ? (_ptScroll, _ptCol, _ptKeys) : (_itScroll, _itCol, _itKeys);
    if (!srcSc.hasClients || !dstSc.hasClients) return;
    final src = _tops(srcCol, srcKeys), dst = _tops(dstCol, dstKeys);
    if (src.isEmpty || dst.length != src.length) return;
    final line = srcSc.offset + _readingLine;
    var i = 0;
    for (var j = 0; j < src.length; j++) {
      if (src[j].$1 <= line) i = j;
    }
    final frac = src[i].$2 <= 0 ? 0.0 : ((line - src[i].$1) / src[i].$2).clamp(0.0, 1.0);
    final target = (dst[i].$1 + frac * dst[i].$2 - _readingLine).clamp(0.0, dstSc.position.maxScrollExtent);
    _syncing = true;
    dstSc.jumpTo(target);
    _syncing = false;
  }

  bool _onScroll(int pane, ScrollNotification n) {
    // A primeira rolagem do usuário apaga o grifo (LEI-06).
    if (n is ScrollStartNotification && n.dragDetails != null && _selP >= 0 && !_handles) {
      setState(() => _selP = _selS = _selE = -1);
    }
    if (n is ScrollUpdateNotification && pane == _leader && !_syncing) _sync(pane);
    return false;
  }

  // ---------------------------------------------------------------- toque e expressão

  RenderParagraphBox? _box(List<GlobalKey> keys, int p) =>
      keys.length > p ? keys[p].currentContext?.findRenderObject() as RenderParagraphBox? : null;

  void _down(int p, Offset pos) {
    final box = _box(_itKeys, p);
    if (box == null) return;
    final w = box.wordAt(pos, exact: _split);
    setState(() {
      _pressed = w >= 0 ? (p: p, w: w) : null;
      _pressedSentence = w < 0 && _split ? (p: p, s: box.sentenceAt(pos), pt: false) : null;
      _focusWord = null;
    });
  }

  void _cancel() => setState(() {
    _pressed = null;
    _pressedSentence = null;
  });

  void _tapIt(int p, Offset pos) {
    final box = _box(_itKeys, p);
    _cancel();
    if (box == null) return;
    final w = box.wordAt(pos, exact: _split);
    if (w >= 0) {
      _openWord(p, w, w);
    } else if (_split) {
      _toggleSentence(p, box.sentenceAt(pos), fromPt: false);
    }
  }

  void _tapPt(int p, Offset pos) {
    final box = _box(_ptKeys, p);
    _cancel();
    if (box == null) return;
    _toggleSentence(p, box.sentenceAt(pos), fromPt: true);
  }

  /// Uma frase ativa por vez; tocar de novo desmarca (TRA-05). O par fora da
  /// vista faz a outra metade rolar o mínimo.
  void _toggleSentence(int p, int s, {required bool fromPt}) {
    if (s < 0) return;
    if (p == _actP && s == _actS) {
      setState(() {
        _actP = _actS = -1;
        _selP = _selS = _selE = -1;
      });
      return;
    }
    setState(() {
      _actP = p;
      _actS = s;
    });
    _announceSentence(p, s, fromPt);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(fromPt ? 0 : 1, p, s));
  }

  void _announceSentence(int p, int s, bool fromPt) {
    final para = _paras[p];
    final sents = fromPt ? para.itSents : para.ptSents;
    if (s >= sents.length) return;
    final text = (fromPt ? para.it : para.pt).substring(sents[s].start, sents[s].end);
    SemanticsService.sendAnnouncement(View.of(context), '${ui.paragraphN(p + 1)}, ${s + 1}. $text', TextDirection.ltr);
  }

  void _reveal(int pane, int p, int s) {
    final (sc, col, keys) = pane == 0 ? (_itScroll, _itCol, _itKeys) : (_ptScroll, _ptCol, _ptKeys);
    final box = _box(keys, p);
    final colBox = col.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || colBox == null || !sc.hasClients) return;
    final r = box.sentenceRect(s).shift(box.localToGlobal(Offset.zero, ancestor: colBox));
    final view = sc.position.viewportDimension;
    double? to;
    if (r.top < sc.offset) to = r.top - 8;
    if (r.bottom > sc.offset + view) to = r.bottom - view + 8;
    if (to == null) return;
    _syncing = true;
    sc.jumpTo(to.clamp(0.0, sc.position.maxScrollExtent));
    _syncing = false;
  }

  void _longStart(int p, Offset pos) {
    final box = _box(_itKeys, p);
    if (box == null) return;
    final w = box.nearestWord(pos);
    if (w < 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressed = null;
      _pressedSentence = null;
      _selP = p;
      _selS = _selE = _anchor = w;
      _handles = true;
    });
  }

  void _longMove(int p, Offset pos) {
    final box = _box(_itKeys, p);
    if (box == null || _selP != p) return;
    var w = box.nearestWord(pos);
    if (w < 0) return;
    // Na tela dividida, a expressão fica dentro da frase (TRA-06).
    if (_split) {
      final s = box.sentenceOfWord(_anchor);
      while (w > _anchor && box.sentenceOfWord(w) != s) {
        w--;
      }
      while (w < _anchor && box.sentenceOfWord(w) != s) {
        w++;
      }
    }
    setState(() {
      _selS = min(_anchor, w);
      _selE = max(_anchor, w);
    });
  }

  void _longEnd() {
    if (_selP < 0) return;
    setState(() => _handles = false);
    _openWord(_selP, _selS, _selE);
  }

  /// Grifa e, depois de 150 ms, empilha o verbete, a página de escolha ou o aviso.
  Future<void> _openWord(int p, int s, int e) async {
    final para = _paras[p];
    setState(() {
      _selP = p;
      _selS = s;
      _selE = e;
      _focusWord = null;
    });
    final text = para.it.substring(para.words[s].start, para.words[e].end);
    final grifo = Motion.of(context, Motion.fast);
    var refs = s == e ? (_lemmas[text] ?? const <EntryRef>[]) : await dbLemmas(text);
    if (refs.isEmpty && s != e) {
      // Expressão sem verbete próprio: uma linha por palavra que tem verbete (DIC-07).
      final all = <EntryRef>[];
      for (var i = s; i <= e; i++) {
        for (final r in _lemmas[para.it.substring(para.words[i].start, para.words[i].end)] ?? const <EntryRef>[]) {
          if (!all.contains(r)) all.add(r);
        }
      }
      refs = all;
    }
    await Future.delayed(grifo);
    if (!mounted) return;
    final box = _box(_itKeys, p);
    final sIdx = box?.sentenceOfWord(s) ?? -1;
    final sent = sIdx >= 0 ? para.itSents[sIdx] : Span(0, para.it.length);
    final story = StoryContext(
      title: widget.story.title,
      paragraph: p,
      sentence: para.it.substring(sent.start, sent.end),
      hlStart: para.words[s].start - sent.start,
      hlEnd: para.words[e].end - sent.start,
      form: text,
    );
    await openLookup(context, refs: refs, backLabel: ui.backToStory, story: story, root: true);
    if (!mounted) return;
    // De volta: na tela dividida, a frase da palavra fica ativa nas duas metades.
    if (_split && sIdx >= 0 && refs.isNotEmpty) {
      setState(() {
        _actP = p;
        _actS = sIdx;
      });
    }
  }

  // ---------------------------------------------------------------- tradução

  void _toggleTranslation() {
    final opening = !_split || _open.status == AnimationStatus.reverse;
    setState(() {
      _actP = _actS = -1;
      _leader = 0;
    });
    if (opening) {
      _ratio = settings.value.split / 100;
      _open.duration = Motion.of(context, Motion.slow);
      _open.forward().whenComplete(() => _sync(0));
      if (!settings.value.hints.contains('split')) WidgetsBinding.instance.addPostFrameCallback((_) => markHintSeen('split'));
      // A metade de baixo chega já alinhada ao parágrafo em foco.
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync(0));
    } else {
      _open.reverseDuration = Motion.of(context, Motion.base);
      _open.reverse();
    }
    SemanticsService.sendAnnouncement(View.of(context), opening ? ui.translationOpened : ui.translationClosed, TextDirection.ltr);
  }

  void _dragDivider(DragUpdateDetails d, double height) {
    setState(() {
      _dragging = true;
      var r = _ratio + d.delta.dy / height;
      // Abaixo de 50% o divisor resiste (30% do movimento).
      if (r < 0.5) r = _ratio + d.delta.dy / height * 0.3;
      _ratio = r.clamp(0.42, 1.0);
    });
    _sync(0);
  }

  void _dropDivider() {
    _dragging = false;
    if (_ratio > 0.82) {
      // Soltar com o italiano acima de 82% fecha a tradução (TRA-03).
      _ratio = settings.value.split / 100;
      _toggleTranslation();
      return;
    }
    final target = _ratio < 0.575 ? 0.5 : 0.65;
    final from = _ratio;
    _snap
      ..duration = Motion.of(context, Motion.base)
      ..reset();
    final anim = CurvedAnimation(parent: _snap, curve: Motion.standard);
    void tick() => setState(() => _ratio = from + (target - from) * anim.value);
    _snap.addListener(tick);
    _snap.forward().whenComplete(() {
      _snap.removeListener(tick);
      setSplit((target * 100).round());
      _sync(0);
    });
  }

  void _stepDivider(int dir) {
    final target = dir > 0 ? 0.65 : 0.5;
    setState(() => _ratio = target);
    setSplit((target * 100).round());
  }

  // ---------------------------------------------------------------- teclado (LEI-12)

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (_paras.isEmpty) return KeyEventResult.ignored;
    final f = _focusWord ?? (p: 0, w: -1);
    WordPos? next;
    if (e.logicalKey == LogicalKeyboardKey.arrowRight || e.logicalKey == LogicalKeyboardKey.arrowDown) {
      next = f.w + 1 < _paras[f.p].words.length ? (p: f.p, w: f.w + 1) : (f.p + 1 < _paras.length ? (p: f.p + 1, w: 0) : f);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft || e.logicalKey == LogicalKeyboardKey.arrowUp) {
      next = f.w > 0 ? (p: f.p, w: f.w - 1) : (f.p > 0 ? (p: f.p - 1, w: _paras[f.p - 1].words.length - 1) : (p: 0, w: 0));
    } else if (e.logicalKey == LogicalKeyboardKey.home) {
      next = (p: 0, w: 0);
    } else if (e.logicalKey == LogicalKeyboardKey.end) {
      next = (p: _paras.length - 1, w: _paras.last.words.length - 1);
    } else if ((e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.space) && f.w >= 0) {
      _openWord(f.p, f.w, f.w);
      return KeyEventResult.handled;
    }
    if (next == null) return KeyEventResult.ignored;
    setState(() => _focusWord = next);
    final box = _box(_itKeys, next.p);
    if (box != null) {
      final r = box.wordRect(next.w);
      Scrollable.ensureVisible(_itKeys[next.p].currentContext!, alignment: 0.3, duration: Motion.of(context, Motion.fast));
      box.showOnScreen(rect: r);
    }
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------- folha Aa

  Future<void> _readingSheet() async {
    final t = context.tk;
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.bg,
      barrierColor: t.scrim,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SettingsScope(
        child: Builder(
          builder: (ctx) {
            watchSettings(ctx);
            final t = ctx.tk;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: t.inkFaint, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(nav.reading, style: T.heading.copyWith(color: t.ink)),
                          ),
                        ),
                        IconBtn(Glyphs.x, label: ui.closeReading, onTap: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ReadingControls(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final s = watchSettings(context);
    final t = context.tk;
    final split = _split;
    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _key,
          child: Column(
            children: [
              CompactBar(
                backLabel: ui.backToLibrary,
                title: widget.story.title,
                titleVisible: split || _titleOff,
                scrolled: split || _titleOff,
                actions: [IconBtn(Glyphs.aLargeSmall, label: ui.readingSettings, selected: _sheetOpen, onTap: _readingSheet)],
              ),
              Expanded(
                child: !_loaded
                    ? const SizedBox()
                    : LayoutBuilder(
                        builder: (context, c) {
                          final h = c.maxHeight;
                          final itShare = 1 - _open.value * (1 - _ratio);
                          final itH = (h * itShare).clamp(0.0, h);
                          return Column(
                            children: [
                              SizedBox(height: itH, child: _itPane(t, s, split)),
                              if (split)
                                SizedBox(
                                  height: h - itH,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      alignment: Alignment.topCenter,
                                      maxHeight: max(h - itH, 44),
                                      child: Column(
                                        children: [
                                          _divider(t, h),
                                          Expanded(child: _ptPane(t, s)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              _dock(t, split),
            ],
          ),
        ),
      ),
    );
  }

  ParagraphColors _colors(Tokens t, {bool pt = false}) => ParagraphColors(
    ink: pt ? t.inkMuted : t.ink,
    sentenceInk: t.ink,
    selectedBg: t.wordSelectedBg,
    selectedLine: t.wordSelectedLine,
    hoverBg: t.wordHoverBg,
    sentenceBg: t.sentenceBg,
    sentencePressBg: t.sentencePressBg,
    gutter: t.sentenceLine,
    focus: t.focus,
  );

  Widget _itPane(Tokens t, Settings s, bool split) {
    final story = widget.story;
    final genre = genreName(widget.genres[story.genre], s.navIt);
    final style = T.reader(s.textSize, s.leading);
    final colors = _colors(t);
    return Column(
      children: [
        // Cabeçalho da metade: só com a tradução aberta.
        if (split)
          SizeTransition(
            sizeFactor: _open,
            child: SizedBox(
              height: 32,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    MicroLabel(ui.italian),
                    const Spacer(),
                    Semantics(
                      label: ui.paragraphN(_focusPara + 1),
                      excludeSemantics: true,
                      child: Text(
                        '¶ ${_focusPara + 1} de ${_paras.length}',
                        style: T.meta.copyWith(color: t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Listener(
            onPointerDown: (_) => _leader = 0,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => _onScroll(0, n),
              child: SingleChildScrollView(
                controller: _itScroll,
                padding: EdgeInsets.fromLTRB(20, 8, 20, split ? 0 : 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 34 * style.fontSize!),
                    child: Column(
                      key: _itCol,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KeyedSubtree(
                          key: _titleKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LevelBadge(story.level.v, name: story.level.name),
                                  const SizedBox(width: 8),
                                  Text('$genre · ${ui.minutes(story.minutes)}', style: T.meta.copyWith(color: t.inkMuted)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                header: true,
                                child: Text(
                                  story.title,
                                  style: (split ? T.title : T.titleLg).copyWith(color: t.ink),
                                  locale: const Locale('it'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                story.subtitle,
                                style: T.lead.copyWith(color: t.inkMuted, fontStyle: FontStyle.italic),
                                locale: const Locale('it'),
                              ),
                            ],
                          ),
                        ),
                        if (!_hintSeenAtOpen)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(ui.firstReadHint, style: T.meta.copyWith(color: t.inkMuted)),
                          ),
                        const SizedBox(height: 32),
                        for (var i = 0; i < _paras.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ParagraphGestures(
                              onDown: (pos) => _down(i, pos),
                              onCancel: _cancel,
                              onTapUp: (pos) => _tapIt(i, pos),
                              onLongStart: (pos) => _longStart(i, pos),
                              onLongMove: (pos) => _longMove(i, pos),
                              onLongEnd: _longEnd,
                              child: ParagraphText(
                                key: _itKeys[i],
                                text: _paras[i].it,
                                style: style,
                                words: _paras[i].words,
                                sentences: _paras[i].itSents,
                                locale: const Locale('it'),
                                colors: colors,
                                marks: ParagraphMarks(
                                  selStart: _selP == i ? _selS : -1,
                                  selEnd: _selP == i ? _selE : -1,
                                  handles: _handles && _selP == i,
                                  pressedWord: _pressed?.p == i ? _pressed!.w : -1,
                                  sentence: split && _actP == i ? _actS : -1,
                                  pressedSentence: _pressedSentence != null && !_pressedSentence!.pt && _pressedSentence!.p == i
                                      ? _pressedSentence!.s
                                      : -1,
                                  focusWord: _focusWord?.p == i ? _focusWord!.w : -1,
                                  gutter: split && _focusPara == i,
                                ),
                                onActivateWord: (w) => _openWord(i, w, w),
                              ),
                            ),
                          ),
                        _end(t, s),
                        // Espaço para o último parágrafo chegar à linha de leitura.
                        if (split) const SizedBox(height: 240),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Se a dica já tinha sido vista antes de abrir esta história.
  late final bool _hintSeenAtOpen = settings.value.hints.contains('reader');

  Widget _divider(Tokens t, double height) {
    final pct = (_ratio * 100).round();
    return Semantics(
      label: ui.splitHandle,
      value: ui.splitValue(pct),
      increasedValue: ui.splitValue(65),
      decreasedValue: ui.splitValue(50),
      slider: true,
      onIncrease: () => _stepDivider(1),
      onDecrease: () => _stepDivider(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => _dragDivider(d, height),
        onVerticalDragEnd: (_) => _dropDivider(),
        onVerticalDragCancel: _dropDivider,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _dragging ? t.surface2 : t.surface,
            border: Border(top: BorderSide(color: t.rule)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: MicroLabel(ui.portuguese)),
              ),
              SizedBox(
                width: 64,
                child: Center(
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    width: _dragging ? 48 : 40,
                    height: 4,
                    decoration: BoxDecoration(color: _dragging ? t.ink : t.inkFaint, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _dragging ? 1 : 0,
                    duration: Motion.of(context, Motion.fast),
                    child: Text('$pct / ${100 - pct}', style: T.meta.copyWith(color: t.inkMuted)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ptPane(Tokens t, Settings s) {
    final colors = _colors(t, pt: true);
    final style = T.lead;
    return ColoredBox(
      color: t.surface,
      child: Column(
        children: [
          if (!_splitHintSeenAtOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(ui.firstSplitHint, style: T.meta.copyWith(color: t.inkMuted)),
            ),
          Expanded(
            child: Listener(
              onPointerDown: (_) => _leader = 1,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) => _onScroll(1, n),
                child: SingleChildScrollView(
                  controller: _ptScroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    key: _ptCol,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _paras.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ParagraphGestures(
                            onDown: (pos) {
                              final box = _box(_ptKeys, i);
                              if (box != null) setState(() => _pressedSentence = (p: i, s: box.sentenceAt(pos), pt: true));
                            },
                            onCancel: _cancel,
                            onTapUp: (pos) => _tapPt(i, pos),
                            child: ParagraphText(
                              key: _ptKeys[i],
                              text: _paras[i].pt,
                              style: style,
                              words: const [],
                              sentences: _paras[i].ptSents,
                              locale: const Locale('pt', 'BR'),
                              colors: colors,
                              marks: ParagraphMarks(
                                sentence: _actP == i ? _actS : -1,
                                pressedSentence: _pressedSentence != null && _pressedSentence!.pt && _pressedSentence!.p == i
                                    ? _pressedSentence!.s
                                    : -1,
                                gutter: _focusPara == i,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 240),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  late final bool _splitHintSeenAtOpen = settings.value.hints.contains('split');

  Widget _end(Tokens t, Settings s) {
    final next = nextStory(widget.story, widget.catalog);
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MicroLabel(ui.endOfStory, header: true),
          if (next.id.v.isNotEmpty) ...[
            const SizedBox(height: 16),
            Pressable(
              onTap: () => _goTo(next),
              radius: 20,
              color: t.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MicroLabel(ui.nextStory),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        LevelBadge(next.level.v, name: next.level.name),
                        const SizedBox(width: 8),
                        Text(
                          '${genreName(widget.genres[next.genre], s.navIt)} · ${ui.minutes(next.minutes)}',
                          style: T.meta.copyWith(color: t.inkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next.title,
                      style: T.heading.copyWith(color: t.ink),
                      locale: const Locale('it'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next.subtitle,
                      style: T.small.copyWith(color: t.inkMuted),
                      locale: const Locale('it'),
                    ),
                    const SizedBox(height: 12),
                    Btn(ui.startReading, block: true, onTap: () => _goTo(next)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Btn(ui.backToLibrary, kind: BtnKind.ghost, block: true, onTap: () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }

  void _goTo(Story next) {
    Navigator.of(context).pushReplacement(
      PushRoute(
        ReaderPage(story: next, catalog: widget.catalog, genres: widget.genres),
        settings: const RouteSettings(name: 'reader'),
      ),
    );
  }

  Widget _dock(Tokens t, bool split) {
    final hiding = split && _open.status != AnimationStatus.reverse;
    return Container(
      color: t.bg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      height: 60,
      alignment: Alignment.centerRight,
      child: Btn(
        hiding ? ui.hideTranslation : ui.showTranslation,
        kind: BtnKind.secondary,
        small: true,
        glyph: Glyphs.rows2,
        onTap: _loaded ? _toggleTranslation : null,
      ),
    );
  }
}
