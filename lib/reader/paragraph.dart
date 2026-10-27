// Um parágrafo do Leitor (ARQ-51): um RenderBox com um TextPainter. Faz o
// layout, guarda o retângulo de cada palavra, resolve toque e arrasto pelo
// retângulo mais próximo, pinta grifo, frase marcada e alças da expressão, e
// cria um nó de semântica por palavra (ACE-03).
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../db/db.dart' show Span;

/// O que o parágrafo pinta. Índices de palavra e de frase; -1 = nenhum.
class ParagraphMarks {
  const ParagraphMarks({
    this.selStart = -1,
    this.selEnd = -1,
    this.handles = false,
    this.pressedWord = -1,
    this.sentence = -1,
    this.pressedSentence = -1,
    this.focusWord = -1,
    this.gutter = false,
  });
  final int selStart, selEnd; // grifo (palavra ou expressão)
  final bool handles; // alças da expressão durante a pressão longa
  final int pressedWord;
  final int sentence; // frase ativa (tela dividida)
  final int pressedSentence;
  final int focusWord; // foco do teclado
  final bool gutter; // régua do parágrafo em foco (tela dividida)

  @override
  bool operator ==(Object other) =>
      other is ParagraphMarks &&
      other.selStart == selStart &&
      other.selEnd == selEnd &&
      other.handles == handles &&
      other.pressedWord == pressedWord &&
      other.sentence == sentence &&
      other.pressedSentence == pressedSentence &&
      other.focusWord == focusWord &&
      other.gutter == gutter;

  @override
  int get hashCode => Object.hash(selStart, selEnd, handles, pressedWord, sentence, pressedSentence, focusWord, gutter);
}

class ParagraphColors {
  const ParagraphColors({
    required this.ink,
    required this.sentenceInk,
    required this.selectedBg,
    required this.selectedLine,
    required this.hoverBg,
    required this.sentenceBg,
    required this.sentencePressBg,
    required this.gutter,
    required this.focus,
  });
  final Color ink, sentenceInk, selectedBg, selectedLine, hoverBg, sentenceBg, sentencePressBg, gutter, focus;

  @override
  bool operator ==(Object other) =>
      other is ParagraphColors && other.ink == ink && other.sentenceInk == sentenceInk && other.selectedBg == selectedBg && other.focus == focus;
  @override
  int get hashCode => Object.hash(ink, sentenceInk, selectedBg, focus);
}

class ParagraphText extends LeafRenderObjectWidget {
  const ParagraphText({
    super.key,
    required this.text,
    required this.style,
    required this.words,
    required this.sentences,
    required this.marks,
    required this.colors,
    required this.locale,
    this.onActivateWord,
  });
  final String text;
  final TextStyle style;
  final List<Span> words;
  final List<Span> sentences;
  final ParagraphMarks marks;
  final ParagraphColors colors;
  final Locale locale;
  final ValueChanged<int>? onActivateWord; // ação de toque do leitor de tela

  @override
  RenderParagraphBox createRenderObject(BuildContext context) => RenderParagraphBox(
        text: text,
        style: style,
        words: words,
        sentences: sentences,
        marks: marks,
        colors: colors,
        locale: locale,
        textScaler: MediaQuery.textScalerOf(context),
        onActivateWord: onActivateWord,
      );

  @override
  void updateRenderObject(BuildContext context, RenderParagraphBox renderObject) {
    renderObject
      ..setText(text, style, words, sentences, locale, MediaQuery.textScalerOf(context))
      ..marks = marks
      ..colors = colors
      ..onActivateWord = onActivateWord;
  }
}

class RenderParagraphBox extends RenderBox {
  RenderParagraphBox({
    required String text,
    required TextStyle style,
    required List<Span> words,
    required List<Span> sentences,
    required ParagraphMarks marks,
    required ParagraphColors colors,
    required Locale locale,
    required TextScaler textScaler,
    this.onActivateWord,
  })  : _text = text,
        _style = style,
        _words = words,
        _sentences = sentences,
        _marks = marks,
        _colors = colors,
        _locale = locale,
        _scaler = textScaler {
    _rebuildPainter();
  }

  String _text;
  TextStyle _style;
  List<Span> _words;
  List<Span> _sentences;
  ParagraphMarks _marks;
  ParagraphColors _colors;
  Locale _locale;
  TextScaler _scaler;
  ValueChanged<int>? onActivateWord;
  final TextPainter _tp = TextPainter(textDirection: TextDirection.ltr);

  /// Retângulos de cada palavra (uma palavra quebrada em duas linhas tem dois).
  List<List<Rect>> _wordRects = const [];

  void setText(String text, TextStyle style, List<Span> words, List<Span> sentences, Locale locale, TextScaler scaler) {
    if (text == _text && style == _style && identical(words, _words) && identical(sentences, _sentences) && locale == _locale && scaler == _scaler) {
      return;
    }
    _text = text;
    _style = style;
    _words = words;
    _sentences = sentences;
    _locale = locale;
    _scaler = scaler;
    _rebuildPainter();
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  set marks(ParagraphMarks m) {
    if (m == _marks) return;
    _marks = m;
    markNeedsPaint();
  }

  set colors(ParagraphColors c) {
    if (c == _colors) return;
    _colors = c;
    _rebuildPainter();
    markNeedsPaint();
  }

  void _rebuildPainter() {
    _tp.text = TextSpan(text: _text, style: _style.copyWith(color: _colors.ink, locale: _locale));
    _tp.textScaler = _scaler;
  }

  // ---------------------------------------------------------------- layout

  @override
  void performLayout() {
    _tp.layout(maxWidth: constraints.maxWidth);
    size = constraints.constrain(Size(constraints.maxWidth, _tp.height));
    _wordRects = [for (final w in _words) _boxes(w.start, w.end)];
  }

  /// Caixas da linha inteira (alvo de toque, rolagem).
  List<Rect> _boxes(int start, int end) => [
        for (final b in _tp.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end), boxHeightStyle: ui.BoxHeightStyle.max))
          b.toRect(),
      ];

  /// Caixas só do desenho das letras, para pintar grifo e frase.
  List<Rect> _inkBoxes(int start, int end) => [
        for (final b in _tp.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end)))
          b.toRect(),
      ];

  @override
  double computeMinIntrinsicHeight(double width) {
    _tp.layout(maxWidth: width);
    return _tp.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  bool hitTestSelf(Offset position) => true;

  // ---------------------------------------------------------------- consultas

  int get wordCount => _words.length;

  /// Palavra sob o ponto: a palavra inteira mais metade do vão até as vizinhas,
  /// e no mínimo 44 de largura (alvo das palavras curtas, ACE-06). -1 fora.
  int wordAt(Offset p, {bool exact = false}) {
    var best = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < _wordRects.length; i++) {
      for (final r in _wordRects[i]) {
        if (p.dy < r.top || p.dy > r.bottom) continue;
        if (exact) {
          if (r.contains(p)) return i;
          continue;
        }
        final grow = r.width < 44 ? (44 - r.width) / 2 : 0.0;
        final hit = Rect.fromLTRB(r.left - grow - 6, r.top, r.right + grow + 6, r.bottom);
        if (!hit.contains(p)) continue;
        final d = (p.dx - r.center.dx).abs();
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }
    }
    return best;
  }

  /// Palavra mais próxima na mesma linha (ou na linha mais próxima): para o arrasto.
  int nearestWord(Offset p) {
    var best = -1;
    var bestScore = double.infinity;
    for (var i = 0; i < _wordRects.length; i++) {
      for (final r in _wordRects[i]) {
        final dy = p.dy < r.top ? r.top - p.dy : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
        final dx = p.dx < r.left ? r.left - p.dx : (p.dx > r.right ? p.dx - r.right : 0.0);
        final score = dy * 1000 + dx;
        if (score < bestScore) {
          bestScore = score;
          best = i;
        }
      }
    }
    return best;
  }

  /// Frase sob o ponto (mais próxima no parágrafo). -1 se não há frases.
  int sentenceAt(Offset p) {
    if (_sentences.isEmpty) return -1;
    final pos = _tp.getPositionForOffset(p).offset;
    var best = 0;
    var bestDist = 1 << 30;
    for (var i = 0; i < _sentences.length; i++) {
      final s = _sentences[i];
      final d = pos < s.start ? s.start - pos : (pos > s.end ? pos - s.end : 0);
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  int sentenceOfWord(int w) {
    if (w < 0 || w >= _words.length) return -1;
    final at = _words[w].start;
    for (var i = 0; i < _sentences.length; i++) {
      if (at >= _sentences[i].start && at < _sentences[i].end) return i;
    }
    return -1;
  }

  /// Retângulo (no parágrafo) de uma frase ou de uma palavra, para rolar até ela.
  Rect sentenceRect(int i) => i < 0 || i >= _sentences.length ? Rect.zero : _union(_boxes(_sentences[i].start, _sentences[i].end));
  Rect wordRect(int i) => i < 0 || i >= _wordRects.length ? Rect.zero : _union(_wordRects[i]);

  Rect _union(List<Rect> rs) => rs.isEmpty ? Rect.zero : rs.reduce((a, b) => a.expandToInclude(b));

  // ---------------------------------------------------------------- pintura

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final m = _marks;
    final em = _style.fontSize ?? 20;
    final fill = Paint();

    // Régua do parágrafo em foco: 2 px, 12 px à esquerda do texto, recuada 4 px.
    if (m.gutter) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(offset.dx - 12, offset.dy + 4, 2, size.height - 8), const Radius.circular(1)),
        fill..color = _colors.gutter,
      );
    }

    void boxes(List<Rect> rs, Color c, double padX, double padY) {
      for (final r in rs) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.shift(offset).inflateXY(padX, padY), const Radius.circular(4)),
          Paint()..color = c,
        );
      }
    }

    final s = m.sentence >= 0 ? m.sentence : m.pressedSentence;
    if (s >= 0 && s < _sentences.length) {
      boxes(_inkBoxes(_sentences[s].start, _sentences[s].end), m.sentence >= 0 ? _colors.sentenceBg : _colors.sentencePressBg, em * 0.1, em * 0.06);
    }
    if (m.pressedWord >= 0 && m.pressedWord < _wordRects.length && m.pressedWord != m.selStart) {
      final w = _words[m.pressedWord];
      boxes(_inkBoxes(w.start, w.end), _colors.hoverBg, em * 0.08, em * 0.06);
    }

    if (m.selStart >= 0 && m.selEnd >= m.selStart && m.selEnd < _words.length) {
      final rs = _inkBoxes(_words[m.selStart].start, _words[m.selEnd].end);
      boxes(rs, _colors.selectedBg, em * 0.08, em * 0.06);
      final line = Paint()
        ..color = _colors.selectedLine
        ..strokeWidth = 2;
      final metrics = _tp.computeLineMetrics();
      for (final r in rs) {
        final base = _baselineAt(metrics, r) + em * 0.28;
        canvas.drawLine(Offset(offset.dx + r.left, offset.dy + base), Offset(offset.dx + r.right, offset.dy + base), line);
      }
      if (m.handles && rs.isNotEmpty) {
        final first = rs.first.shift(offset), last = rs.last.shift(offset);
        final h = em * 1.5;
        final k = Paint()..color = _colors.selectedLine;
        // Início: haste para cima com a bola em cima; fim: para baixo com a bola embaixo.
        canvas.drawRect(Rect.fromLTWH(first.left - 1, first.bottom - h, 2, h), k);
        canvas.drawCircle(Offset(first.left, first.bottom - h), 5, k);
        canvas.drawRect(Rect.fromLTWH(last.right - 1, last.top, 2, h), k);
        canvas.drawCircle(Offset(last.right, last.top + h), 5, k);
      }
    }

    if (m.focusWord >= 0 && m.focusWord < _wordRects.length) {
      final ring = Paint()
        ..color = _colors.focus
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final r in _wordRects[m.focusWord]) {
        canvas.drawRRect(RRect.fromRectAndRadius(r.shift(offset).inflate(3), const Radius.circular(6)), ring);
      }
    }

    // A frase ativa passa a tinta cheia (no português, que repousa em tinta suave).
    if (m.sentence >= 0 && m.sentence < _sentences.length && _colors.sentenceInk != _colors.ink) {
      final sp = _sentences[m.sentence];
      _tp.text = TextSpan(style: _style.copyWith(color: _colors.ink, locale: _locale), children: [
        TextSpan(text: _text.substring(0, sp.start)),
        TextSpan(text: _text.substring(sp.start, sp.end), style: TextStyle(color: _colors.sentenceInk)),
        TextSpan(text: _text.substring(sp.end)),
      ]);
      _tp.layout(maxWidth: size.width);
      _tp.paint(canvas, offset);
      _rebuildPainter();
      _tp.layout(maxWidth: size.width);
    } else {
      _tp.paint(canvas, offset);
    }
  }

  double _baselineAt(List<ui.LineMetrics> lines, Rect r) {
    for (final l in lines) {
      final top = l.baseline - l.ascent;
      if (r.center.dy >= top && r.center.dy <= l.baseline + l.descent) return l.baseline;
    }
    return r.bottom;
  }

  // ---------------------------------------------------------------- semântica

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (_words.isEmpty) {
      config.label = _text;
      config.textDirection = TextDirection.ltr;
      config.attributedLabel = AttributedString(_text, attributes: [LocaleStringAttribute(range: TextRange(start: 0, end: _text.length), locale: _locale)]);
    } else {
      config.explicitChildNodes = true;
    }
  }

  final List<SemanticsNode> _wordNodes = [];

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config, Iterable<SemanticsNode> children) {
    if (_words.isEmpty) {
      super.assembleSemanticsNode(node, config, children);
      return;
    }
    while (_wordNodes.length < _words.length) {
      _wordNodes.add(SemanticsNode());
    }
    final out = <SemanticsNode>[];
    for (var i = 0; i < _words.length; i++) {
      final w = _words[i];
      final label = _text.substring(w.start, w.end);
      final c = SemanticsConfiguration()
        ..isButton = true
        ..textDirection = TextDirection.ltr
        ..attributedLabel = AttributedString(label, attributes: [LocaleStringAttribute(range: TextRange(start: 0, end: label.length), locale: _locale)])
        ..onTap = () => onActivateWord?.call(i);
      final n = _wordNodes[i]
        ..rect = wordRect(i)
        ..updateWith(config: c);
      out.add(n);
    }
    node.updateWith(config: config, childrenInInversePaintOrder: out);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _wordNodes.clear();
  }
}

extension on Rect {
  /// Caixa com folga, como o `padding` + margem negativa do CSS (o texto não anda).
  Rect inflateXY(double padX, double padY) => Rect.fromLTRB(left - padX, top - padY, right + padX, bottom + padY);
}

/// Gestos do parágrafo: toque, pressão (para o fundo de "pressionado") e
/// pressão longa de 500 ms com arrasto (LEI-03). Coordenadas locais ao parágrafo.
class ParagraphGestures extends StatelessWidget {
  const ParagraphGestures({
    super.key,
    required this.child,
    this.onDown,
    this.onCancel,
    this.onTapUp,
    this.onLongStart,
    this.onLongMove,
    this.onLongEnd,
  });
  final Widget child;
  final void Function(Offset)? onDown;
  final VoidCallback? onCancel;
  final void Function(Offset)? onTapUp;
  final void Function(Offset)? onLongStart;
  final void Function(Offset)? onLongMove;
  final VoidCallback? onLongEnd;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(TapGestureRecognizer.new, (r) {
          r.onTapDown = (d) => onDown?.call(d.localPosition);
          r.onTapCancel = onCancel;
          r.onTapUp = (d) => onTapUp?.call(d.localPosition);
        }),
        if (onLongStart != null)
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 500)),
            (r) {
              r.onLongPressStart = (d) => onLongStart?.call(d.localPosition);
              r.onLongPressMoveUpdate = (d) => onLongMove?.call(d.localPosition);
              r.onLongPressEnd = (_) => onLongEnd?.call();
              r.onLongPressCancel = onCancel;
            },
          ),
      },
      child: child,
    );
  }
}
