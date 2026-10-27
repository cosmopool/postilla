// Postilla: abertura (conteúdo embutido, OFF-11), tema, Imersão e o shell com
// as três abas da v1 (Biblioteca · Dicionário · Ajustes). Navegação à mão
// (ARQ-44): um Navigator por aba num IndexedStack, e o raiz para o Leitor.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'db/content.dart';
import 'db/db.dart';
import 'dictionary/dictionary.dart';
import 'library/library.dart';
import 'settings/settings.dart';
import 'strings.dart';
import 'ui/icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PostillaApp());
}

class PostillaApp extends StatelessWidget {
  const PostillaApp({super.key, this.home});

  /// Para testes: pula a abertura quando os bancos já estão abertos.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Settings>(
      valueListenable: settings,
      builder: (context, s, _) => MaterialApp(
        title: 'Postilla',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Tokens.light),
        darkTheme: buildTheme(Tokens.darkTokens),
        themeMode: s.theme,
        builder: (context, child) => SettingsScope(child: child!),
        home: home ?? const _Boot(),
      ),
    );
  }
}

// ---------------------------------------------------------------- abertura

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  ContentState? _state; // null: preparando
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _state = null);
    final support = await getApplicationSupportDirectory();
    final lock = await loadLock(rootBundle);
    final state = await prepareContent(rootBundle, Directory('${support.path}/content'), lock);
    if (!state.ready) {
      setState(() => _state = state);
      return;
    }
    await dbOpen(userPath: '${support.path}/user.db', dictPath: state.dictPath, storiesPath: state.storiesPath);
    await loadSettings();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const Shell();
    final t = context.tk;
    final s = _state;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: s == null
              ? Semantics(
                  liveRegion: true,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: t.ink)),
                    const SizedBox(height: 16),
                    Text(ui.preparingDictionary, style: T.body.copyWith(color: t.ink)),
                  ]),
                )
              : EmptyState(
                  glyph: Glyphs.bookA,
                  title: s.missingBytes > 0 ? ui.noSpace((s.missingBytes / (1 << 20)).ceil()) : ui.contentFailed,
                  action: Btn(ui.tryAgain, kind: BtnKind.secondary, small: true, onTap: _start),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shell

enum AppTab { library, dictionary, settings }

/// Toque de novo na aba ativa: a aba escuta e rola ao topo ou volta à raiz (NAV-06).
final tabReselected = ValueNotifier<(AppTab, int)>((AppTab.library, 0));

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  AppTab _tab = AppTab.library;
  final _navs = {for (final t in AppTab.values) t: GlobalKey<NavigatorState>()};

  void _select(AppTab tab) {
    if (tab == _tab) {
      tabReselected.value = (tab, tabReselected.value.$2 + 1);
      if (tab != AppTab.library) _navs[tab]!.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    Widget tabNav(AppTab tab, Widget root) => Navigator(
          key: _navs[tab],
          onGenerateRoute: (_) => PageRouteBuilder(pageBuilder: (_, _, _) => root, transitionDuration: Duration.zero),
        );
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navs[_tab]!.currentState?.maybePop(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: t.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab.index,
              children: [
                tabNav(AppTab.library, const LibraryPage()),
                tabNav(AppTab.dictionary, const DictionaryRoot()),
                tabNav(AppTab.settings, const SettingsRoot()),
              ],
            ),
          ),
          bottomNavigationBar: _TabBar(selected: _tab, onSelect: _select),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect});
  final AppTab selected;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    watchSettings(context);
    final t = context.tk;
    final items = [
      (AppTab.library, Glyphs.libraryBig, nav.library),
      (AppTab.dictionary, Glyphs.bookA, nav.dictionary),
      (AppTab.settings, Glyphs.settings2, nav.settings),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Principal',
      child: Container(
        decoration: BoxDecoration(color: t.bg, border: Border(top: BorderSide(color: t.rule))),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        height: 64 + MediaQuery.paddingOf(context).bottom,
        child: Row(
          children: [
            for (final (tab, glyph, label) in items)
              Expanded(
                child: Semantics(
                  selected: tab == selected,
                  button: true,
                  label: label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(tab),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Glyph(glyph, color: tab == selected ? t.ink : t.inkMuted),
                            const SizedBox(height: 2),
                            Text(label,
                                style: T.meta.copyWith(
                                  color: tab == selected ? t.ink : t.inkMuted,
                                  fontWeight: tab == selected ? FontWeight.w600 : FontWeight.w400,
                                  fontVariations: [FontVariation.weight(tab == selected ? 600 : 400)],
                                )),
                          ],
                        ),
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(child: AnimatedContainer(
                            duration: Motion.of(context, Motion.fast),
                            width: 24,
                            height: 2,
                            decoration: BoxDecoration(
                              color: tab == selected ? t.accent : t.bg.withAlpha(0),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
