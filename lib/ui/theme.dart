// Tokens do design system (docs/design/tokens.css) em Dart. Uma cor por papel,
// em claro e escuro; tipos prontos por papel (`T.reader`, `T.def`…).
import 'package:flutter/material.dart';

class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.rule,
    required this.ruleStrong,
    required this.accent,
    required this.accentSoft,
    required this.focus,
    required this.onInk,
    required this.scrim,
    required this.wordSelectedBg,
    required this.wordSelectedLine,
    required this.wordHoverBg,
    required this.sentenceBg,
    required this.sentencePressBg,
    required this.sentenceLine,
    required this.levelBg,
    required this.levelInk,
    required this.dark,
  });

  final Color bg, surface, surface2, ink, inkMuted, inkFaint, rule, ruleStrong;
  final Color accent, accentSoft, focus, onInk, scrim;
  final Color wordSelectedBg, wordSelectedLine, wordHoverBg;
  final Color sentenceBg, sentencePressBg, sentenceLine;
  final List<Color> levelBg, levelInk; // A1…B2
  final bool dark;

  static const light = Tokens(
    bg: Color(0xFFFDFDFC),
    surface: Color(0xFFF6F6F3),
    surface2: Color(0xFFEDECE8),
    ink: Color(0xFF181713),
    inkMuted: Color(0xFF5C5B55),
    inkFaint: Color(0xFF878681),
    rule: Color(0xFFDDDCD8),
    ruleStrong: Color(0xFFC8C7C2),
    accent: Color(0xFFF2C200),
    accentSoft: Color(0xFFFFEB99),
    focus: Color(0xFF181713),
    onInk: Color(0xFFFDFDFC),
    scrim: Color(0x66181713),
    wordSelectedBg: Color(0xFFFFEB99),
    wordSelectedLine: Color(0xFFC99A00),
    wordHoverBg: Color(0xFFEDECE8),
    sentenceBg: Color(0xFFDDDCD8),
    sentencePressBg: Color(0xFFEDECE8),
    sentenceLine: Color(0xFFC8C7C2),
    levelBg: [Color(0xFFDEF7EC), Color(0xFFC6EBDC), Color(0xFFA5D8C3), Color(0xFF7DBBA3)],
    levelInk: [Color(0xFF0E3629), Color(0xFF0E3629), Color(0xFF0E3629), Color(0xFF0B2A20)],
    dark: false,
  );

  static const darkTokens = Tokens(
    bg: Color(0xFF100F0D),
    surface: Color(0xFF191816),
    surface2: Color(0xFF22221E),
    ink: Color(0xFFECEBE7),
    inkMuted: Color(0xFFACABA5),
    inkFaint: Color(0xFF7C7A75),
    rule: Color(0xFF31302C),
    ruleStrong: Color(0xFF44423E),
    accent: Color(0xFFF2C94C),
    accentSoft: Color(0xFF3D3210),
    focus: Color(0xFFF2C94C),
    onInk: Color(0xFF100F0D),
    scrim: Color(0x8C000000),
    wordSelectedBg: Color(0xFF3D3210),
    wordSelectedLine: Color(0xFFF2C94C),
    wordHoverBg: Color(0xFF22221E),
    sentenceBg: Color(0xFF31302C),
    sentencePressBg: Color(0xFF22221E),
    sentenceLine: Color(0xFF44423E),
    levelBg: [Color(0xFF172B24), Color(0xFF1C3D31), Color(0xFF285847), Color(0xFF548E78)],
    levelInk: [Color(0xFFD6EFE4), Color(0xFFD6EFE4), Color(0xFFD6EFE4), Color(0xFF071A13)],
    dark: true,
  );

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(Tokens? other, double t) => t < 0.5 || other == null ? this : other;
}

extension TokensOf on BuildContext {
  Tokens get tk => Theme.of(this).extension<Tokens>()!;
}

/// Durações e curvas (tokens de movimento). Com movimento reduzido, zero (ACE-01).
abstract final class Motion {
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);
  static const standard = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.3, 0, 0, 1);
  static const exit = Cubic(0.3, 0, 1, 1);

  static Duration of(BuildContext context, Duration d) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Tipos por papel. Cor fica a cargo de quem usa (`.copyWith(color: …)`).
abstract final class T {
  static const _text = 'Literata';
  static const _display = 'Newsreader';

  static TextStyle _s(String family, double size, double lh, FontWeight w, {double tracking = 0, FontStyle? style}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: lh / size,
        fontWeight: w,
        letterSpacing: tracking * size,
        fontStyle: style,
        fontVariations: [FontVariation.weight(w.value.toDouble()), FontVariation('opsz', size.clamp(7, 72))],
        leadingDistribution: TextLeadingDistribution.even,
      );

  static final headword = _s(_display, 44, 48, FontWeight.w500, tracking: -0.02);
  static final titleLg = _s(_display, 36, 40, FontWeight.w500, tracking: -0.02);
  static final title = _s(_display, 28, 32, FontWeight.w500, tracking: -0.02);
  static final cardTitle = _s(_display, 22, 28, FontWeight.w500, tracking: -0.01);
  static final number = _s(_display, 18, 26, FontWeight.w500);
  static final heading = _s(_text, 22, 28, FontWeight.w600, tracking: -0.01);
  static final lead = _s(_text, 18, 26, FontWeight.w400);
  static final rowTitle = _s(_text, 18, 26, FontWeight.w500);
  static final def = _s(_text, 17, 26, FontWeight.w400);
  static final body = _s(_text, 16, 24, FontWeight.w400);
  static final button = _s(_text, 16, 24, FontWeight.w500, tracking: 0.005);
  static final small = _s(_text, 14, 20, FontWeight.w400);
  static final smallMedium = _s(_text, 14, 20, FontWeight.w500);
  static final meta = _s(_text, 12, 16, FontWeight.w400);
  static final label = _s(_text, 11, 14, FontWeight.w600, tracking: 0.08);
  static final ipa = const TextStyle(fontFamily: 'NotoSerif', fontSize: 17, height: 26 / 17);

  /// Corpo de leitura: 5 tamanhos (LEI-08) e 3 entrelinhas.
  static const readerSizes = [18.0, 20.0, 22.0, 24.0, 26.0];
  static const readerLeadings = [1.5, 1.7, 2.0];
  static TextStyle reader(int size, int leading) {
    final s = readerSizes[size.clamp(0, 4)];
    return _s(_text, s, s * readerLeadings[leading.clamp(0, 2)], FontWeight.w400);
  }
}

ThemeData buildTheme(Tokens t) {
  final scheme = ColorScheme(
    brightness: t.dark ? Brightness.dark : Brightness.light,
    primary: t.ink,
    onPrimary: t.onInk,
    secondary: t.ink,
    onSecondary: t.onInk,
    error: t.dark ? const Color(0xFFF47C70) : const Color(0xFFBA2B28),
    onError: t.onInk,
    surface: t.bg,
    onSurface: t.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    fontFamily: 'Literata',
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(cursorColor: t.ink, selectionColor: t.accentSoft, selectionHandleColor: t.ink),
    extensions: [t],
  );
}
