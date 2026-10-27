// Ícones da v1: paths do Lucide 0.460.0 (licença ISC), desenhados com traço
// 1,5 numa grade 24×24, pontas e junções redondas, na cor do texto.
import 'dart:math';

import 'package:flutter/widgets.dart';

enum Glyphs {
  libraryBig([
    'M4 3h6a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z',
    'M7 3v18',
    'M20.4 18.9c.2.5-.1 1.1-.6 1.3l-1.9.7c-.5.2-1.1-.1-1.3-.6L11.1 5.1c-.2-.5.1-1.1.6-1.3l1.9-.7c.5-.2 1.1.1 1.3.6Z',
  ]),
  bookA([
    'M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H19a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6.5a1 1 0 0 1 0-5H20',
    'm8 13 4-7 4 7',
    'M9.1 11h5.7',
  ]),
  settings2(['M20 7h-9', 'M14 17H5'], [(17, 17, 3), (7, 7, 3)]),
  chevronLeft(['m15 18-6-6 6-6']),
  chevronRight(['m9 18 6-6-6-6']),
  search(['m21 21-4.3-4.3'], [(11, 11, 8)]),
  searchX(['m13.5 8.5-5 5', 'm8.5 8.5 5 5', 'm21 21-4.3-4.3'], [(11, 11, 8)]),
  x(['M18 6 6 18', 'm6 6 12 12']),
  aLargeSmall(['M21 14h-5', 'M16 16v-3.5a2.5 2.5 0 0 1 5 0V16', 'M4.5 13h6', 'm3 16 4.5-9 4.5 9']),
  ellipsis([], [(12, 12, 1), (19, 12, 1), (5, 12, 1)]),
  rows2(['M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z', 'M3 12h18']),
  languages(['m5 8 6 6', 'm4 14 6-6 2-3', 'M2 5h12', 'M7 2h1', 'm22 22-5-10-5 10', 'M14 18h6']);

  const Glyphs(this.paths, [this.circles = const []]);
  final List<String> paths;
  final List<(double, double, double)> circles;
}

class Glyph extends StatelessWidget {
  const Glyph(this.glyph, {super.key, this.size = 24, this.color});
  final Glyphs glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF181713);
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _GlyphPainter(glyph, c)),
    );
  }
}

final _cache = <Glyphs, Path>{};

Path _pathOf(Glyphs g) => _cache[g] ??= () {
      final p = Path();
      for (final d in g.paths) {
        p.addPath(parseSvgPath(d), Offset.zero);
      }
      for (final (cx, cy, r) in g.circles) {
        p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      }
      return p;
    }();

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);
  final Glyphs glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    canvas.drawPath(
      _pathOf(glyph),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}

/// Parser do subconjunto de path SVG que os ícones usam: M L H V C S A Z, absolutos e relativos.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MmLlHhVvCcSsAaZz]|-?(?:\d+\.?\d*|\.\d+)').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = 'M';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  var cx2 = 0.0, cy2 = 0.0; // último controle de curva, para o S
  double n() => double.parse(tokens[i++]);
  bool isNum() => i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!isNum()) cmd = tokens[i++];
    final rel = cmd.toLowerCase() == cmd;
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + n();
        y = oy + n();
        path.moveTo(x, y);
        sx = x;
        sy = y;
        cmd = rel ? 'l' : 'L'; // pares seguintes são linhas
      case 'L':
        x = ox + n();
        y = oy + n();
        path.lineTo(x, y);
      case 'H':
        x = ox + n();
        path.lineTo(x, y);
      case 'V':
        y = oy + n();
        path.lineTo(x, y);
      case 'C':
        final x1 = ox + n(), y1 = oy + n();
        cx2 = ox + n();
        cy2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, cx2, cy2, x, y);
      case 'S':
        final x1 = 2 * x - cx2, y1 = 2 * y - cy2;
        cx2 = ox + n();
        cy2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, cx2, cy2, x, y);
      case 'A':
        final rx = n(), ry = n(), rot = n();
        final large = n() != 0, sweep = n() != 0;
        x = ox + n();
        y = oy + n();
        path.arcToPoint(Offset(x, y), radius: Radius.elliptical(rx, ry), rotation: rot * pi / 180, largeArc: large, clockwise: sweep);
      case 'Z':
        path.close();
        x = sx;
        y = sy;
      default:
        i++;
    }
    if (cmd.toUpperCase() != 'C' && cmd.toUpperCase() != 'S') {
      cx2 = x;
      cy2 = y;
    }
  }
  return path;
}
