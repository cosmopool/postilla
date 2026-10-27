// Ajustes que valem para o app todo (ARQ-42): um struct imutável num
// ValueNotifier na raiz. Mudar um ajuste grava no `user` e troca o valor.
// Telas: Ajustes (raiz), Leitura, Imersão e Sobre.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../db/db.dart';
import '../strings.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class Settings {
  const Settings({
    this.textSize = 1,
    this.leading = 1,
    this.theme = ThemeMode.system,
    this.navIt = false,
    this.uiIt = false,
    this.dictIt = false,
    this.glossIt = false,
    this.split = 50,
    this.hints = const {},
  });

  final int textSize; // 0…4 (LEI-08)
  final int leading; // 0 compacta · 1 padrão · 2 ampla
  final ThemeMode theme;
  final bool navIt, uiIt, dictIt, glossIt; // Imersão (AJU-02)
  final int split; // 50 ou 65 (TRA-02)
  final Set<String> hints; // dicas de primeiro uso já vistas (LEI-11)

  Settings copyWith({
    int? textSize,
    int? leading,
    ThemeMode? theme,
    bool? navIt,
    bool? uiIt,
    bool? dictIt,
    bool? glossIt,
    int? split,
    Set<String>? hints,
  }) => Settings(
    textSize: textSize ?? this.textSize,
    leading: leading ?? this.leading,
    theme: theme ?? this.theme,
    navIt: navIt ?? this.navIt,
    uiIt: uiIt ?? this.uiIt,
    dictIt: dictIt ?? this.dictIt,
    glossIt: glossIt ?? this.glossIt,
    split: split ?? this.split,
    hints: hints ?? this.hints,
  );

  int get italianAreas => [navIt, uiIt, dictIt, glossIt].where((x) => x).length;

  static Settings fromStore(Map<String, Object?> m) {
    final r = (m['reading'] as Map?) ?? const {};
    final i = (m['immersion'] as Map?) ?? const {};
    return Settings(
      textSize: (r['size'] as int?) ?? 1,
      leading: (r['leading'] as int?) ?? 1,
      theme: ThemeMode.values[((m['theme'] as int?) ?? 0).clamp(0, 2)],
      navIt: (i['nav'] as bool?) ?? false,
      uiIt: (i['ui'] as bool?) ?? false,
      dictIt: (i['dict'] as bool?) ?? false,
      glossIt: (i['gloss'] as bool?) ?? false,
      split: (m['split'] as int?) == 65 ? 65 : 50,
      hints: {for (final h in (m['hints'] as List?) ?? const []) h as String},
    );
  }
}

/// Predefinições da Imersão (AJU-03): navegação, rótulos, dicionário, glosas.
enum Preset {
  beginner(false, false, false, false),
  intermediate(false, false, true, false),
  full(true, true, true, true);

  const Preset(this.nav, this.ui, this.dict, this.gloss);
  final bool nav, ui, dict, gloss;

  static Preset? of(Settings s) {
    for (final p in values) {
      if (p.nav == s.navIt && p.ui == s.uiIt && p.dict == s.dictIt && p.gloss == s.glossIt) return p;
    }
    return null;
  }
}

final settings = ValueNotifier<Settings>(const Settings());

/// Exposição dos ajustes na árvore (ARQ-42): quem chama `watchSettings`
/// reconstrói quando um ajuste (inclusive a Imersão) muda.
class SettingsScope extends InheritedNotifier<ValueNotifier<Settings>> {
  SettingsScope({super.key, required super.child}) : super(notifier: settings);
}

Settings watchSettings(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<SettingsScope>();
  return settings.value;
}

/// Troca os textos pela Imersão e só então notifica (ARQ-46).
void applySettings(Settings s) {
  nav = s.navIt ? NavItalian() : NavPortuguese();
  ui = s.uiIt ? UiItalian() : UiPortuguese();
  dict = s.dictIt ? DictItalian() : DictPortuguese();
  settings.value = s;
}

Future<void> loadSettings() async => applySettings(Settings.fromStore(await dbSettingsLoad()));

void setReading({int? size, int? leading}) {
  final s = settings.value.copyWith(textSize: size, leading: leading);
  applySettings(s);
  dbSettingSet('reading', {'size': s.textSize, 'leading': s.leading});
}

void setTheme(ThemeMode m) {
  applySettings(settings.value.copyWith(theme: m));
  dbSettingSet('theme', m.index);
}

void setImmersion({bool? navIt, bool? uiIt, bool? dictIt, bool? glossIt}) {
  final s = settings.value.copyWith(navIt: navIt, uiIt: uiIt, dictIt: dictIt, glossIt: glossIt);
  applySettings(s);
  dbSettingSet('immersion', {'nav': s.navIt, 'ui': s.uiIt, 'dict': s.dictIt, 'gloss': s.glossIt});
}

void setSplit(int ratio) {
  applySettings(settings.value.copyWith(split: ratio));
  dbSettingSet('split', ratio);
}

void markHintSeen(String hint) {
  if (settings.value.hints.contains(hint)) return;
  final s = settings.value.copyWith(hints: {...settings.value.hints, hint});
  applySettings(s);
  dbSettingSet('hints', s.hints.toList());
}

// ---------------------------------------------------------------- controles de leitura

/// Tamanho, entrelinha e tema: os mesmos na folha Aa do Leitor e em Ajustes › Leitura.
class ReadingControls extends StatelessWidget {
  const ReadingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final s = settings.value;
    Widget field(String label, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: T.small.copyWith(color: t.inkMuted)),
        const SizedBox(height: 8),
        control,
      ],
    );
    Widget a(double size) => Text(
      'A',
      style: T.smallMedium.copyWith(fontSize: size, height: 1, color: t.ink),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(
          ui.textSize,
          Row(
            children: [
              IconBtn(
                Glyphs.x,
                label: ui.decreaseText,
                filled: true,
                onTap: s.textSize > 0 ? () => _size(context, s.textSize - 1) : null,
                child: a(14),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i == s.textSize ? t.ink : t.ruleStrong),
                      ),
                  ],
                ),
              ),
              IconBtn(
                Glyphs.x,
                label: ui.increaseText,
                filled: true,
                onTap: s.textSize < 4 ? () => _size(context, s.textSize + 1) : null,
                child: a(22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        field(
          ui.lineSpacing,
          Segmented(
            label: ui.lineSpacing,
            options: [ui.compact, ui.standard, ui.loose],
            selected: s.leading,
            onSelect: (i) => setReading(leading: i),
          ),
        ),
        const SizedBox(height: 20),
        field(
          ui.theme,
          Segmented(
            label: ui.theme,
            options: [ui.light, ui.dark, ui.system],
            selected: switch (s.theme) {
              ThemeMode.light => 0,
              ThemeMode.dark => 1,
              ThemeMode.system => 2,
            },
            onSelect: (i) => setTheme([ThemeMode.light, ThemeMode.dark, ThemeMode.system][i]),
          ),
        ),
      ],
    );
  }

  void _size(BuildContext context, int size) {
    setReading(size: size);
    SemanticsService.sendAnnouncement(View.of(context), ui.sizeNofM(size + 1, 5), Directionality.of(context));
  }
}

// ---------------------------------------------------------------- telas

/// Raiz da aba Ajustes: Leitura · Imersão · Sobre.
class SettingsRoot extends StatelessWidget {
  const SettingsRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final preset = Preset.of(watchSettings(context));
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Semantics(
            header: true,
            child: Text(nav.settings, style: T.title.copyWith(color: t.ink)),
          ),
        ),
        ListRow(
          title: nav.reading,
          glyph: Glyphs.aLargeSmall,
          compact: true,
          onTap: () => Navigator.of(context).push(PushRoute(const _ReadingPage())),
        ),
        ListRow(
          title: nav.immersion,
          glyph: Glyphs.languages,
          compact: true,
          value: switch (preset) {
            Preset.beginner => ui.beginner,
            Preset.intermediate => ui.intermediate,
            Preset.full => ui.fullImmersion,
            null => ui.custom,
          },
          onTap: () => Navigator.of(context).push(PushRoute(const _ImmersionPage())),
        ),
        ListRow(
          title: nav.about,
          glyph: Glyphs.bookA,
          compact: true,
          onTap: () => Navigator.of(context).push(PushRoute(const _AboutPage())),
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.tk.bg,
    child: Column(
      children: [
        CompactBar(backLabel: ui.backToSettings, title: title),
        Expanded(
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), child: child),
        ),
      ],
    ),
  );
}

class _ReadingPage extends StatelessWidget {
  const _ReadingPage();
  @override
  Widget build(BuildContext context) {
    watchSettings(context);
    return _Page(title: nav.reading, child: const ReadingControls());
  }
}

class _ImmersionPage extends StatelessWidget {
  const _ImmersionPage();

  @override
  Widget build(BuildContext context) {
    final s = watchSettings(context);
    final t = context.tk;
    final preset = Preset.of(s);
    final summary = switch (preset) {
      Preset.beginner => ui.beginnerSummary,
      Preset.intermediate => ui.intermediateSummary,
      Preset.full => ui.fullImmersionSummary,
      null => ui.customSummary(s.italianAreas),
    };
    Widget area(String name, String hint, bool value, void Function(bool) set) => Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: T.button.copyWith(color: t.ink),
                ),
                TextSpan(
                  text: hint,
                  style: T.small.copyWith(color: t.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Segmented(label: name, options: [ui.portuguese, ui.italian], selected: value ? 1 : 0, onSelect: (i) => set(i == 1)),
        ],
      ),
    );
    return _Page(
      title: nav.immersion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MicroLabel(ui.presets),
          const SizedBox(height: 12),
          Semantics(
            label: ui.presets,
            container: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final (p, name) in [
                  (Preset.beginner, ui.beginner),
                  (Preset.intermediate, ui.intermediate),
                  (Preset.full, ui.fullImmersion),
                ])
                  FilterChipBtn(
                    name,
                    selected: preset == p,
                    onTap: () => setImmersion(navIt: p.nav, uiIt: p.ui, dictIt: p.dict, glossIt: p.gloss),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(summary, style: T.small.copyWith(color: t.inkMuted)),
            ),
          ),
          MicroLabel(ui.byArea),
          area(ui.areaNav, ui.areaNavHint, s.navIt, (v) => setImmersion(navIt: v)),
          area(ui.areaUi, '', s.uiIt, (v) => setImmersion(uiIt: v)),
          area(ui.areaDict, ui.areaDictHint, s.dictIt, (v) => setImmersion(dictIt: v)),
          area(ui.areaGloss, '', s.glossIt, (v) => setImmersion(glossIt: v)),
        ],
      ),
    );
  }
}

const appVersion = '0.1.0';

class _AboutPage extends StatefulWidget {
  const _AboutPage();
  @override
  State<_AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<_AboutPage> {
  ContentInfo _info = ContentInfo.nil;

  @override
  void initState() {
    super.initState();
    dbContentInfo().then((i) => mounted ? setState(() => _info = i) : null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final dump = _info.dumpDate.split('-').reversed.join('/');
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: T.body.copyWith(color: t.ink)),
          ),
          Text(v, style: T.small.copyWith(color: t.inkMuted)),
        ],
      ),
    );
    return _Page(
      title: nav.about,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(ui.version, appVersion),
          // OFF-13: "Dicionário 2.1.0 (Wikizionario de 01/10/2026) · Histórias 1.4.2".
          row(ui.dictionaryContent, '${_info.dictVersion} (Wikizionario de $dump)'),
          row(ui.storiesContent, _info.storiesVersion),
          const SizedBox(height: 24),
          MicroLabel(ui.credits, header: true),
          const SizedBox(height: 8),
          Text(
            'Wikizionario e Wiktionary em inglês (CC BY-SA 4.0), por meio do wiktextract e do kaikki.org. '
            'Glosas em português: WikDict e DBnary (CC BY-SA). '
            'Frequência: Nuovo vocabolario di base della lingua italiana, Tullio De Mauro (2016). '
            'Fontes Literata, Newsreader e Noto Serif (SIL Open Font License). Ícones Lucide (ISC).',
            style: T.small.copyWith(color: t.inkMuted),
          ),
        ],
      ),
    );
  }
}
