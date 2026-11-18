import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postilla/db/db.dart';
import 'package:postilla/main.dart';
import 'package:postilla/settings/about.dart';
import 'package:postilla/settings/languages.dart';
import 'package:postilla/settings/settings.dart';
import 'package:postilla/ui/icons.dart';

import 'content.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
  }
  await t.pumpAndSettle();
}

const _langs = [
  Language(LangId('en'), 'English'),
  Language(LangId('it'), 'Italiano', target: true),
  Language(LangId('pt-BR'), 'Português', translate: true),
  Language(LangId('pt-PT'), 'Português europeu', translate: true), // no UI strings
  Language(LangId('es'), 'Español', target: true, translate: true),
];

void main() {
  group('language choices (AJU-08)', () {
    test('target lists learnable languages and keeps the stored one', () {
      expect(targetChoices(_langs, const LangId('it')).map((l) => l.id.v), ['it', 'es']);
      expect(targetChoices(_langs, const LangId('en')).map((l) => l.id.v), ['en', 'it', 'es']);
    });

    test('native lists translated languages with UI strings, minus the target', () {
      expect(nativeChoices(_langs, const LangId('it')).map((l) => l.id.v), ['pt-BR']);
      expect(nativeChoices(_langs, const LangId('pt-BR')), isEmpty);
    });

    test('picking a target keeps the native while it is still a choice', () {
      expect(pairAfterTarget(_langs, const LangId('es'), const LangId('pt-BR')), (const LangId('es'), const LangId('pt-BR')));
      expect(pairAfterTarget(_langs, const LangId('it'), const LangId('es')), (const LangId('it'), const LangId('pt-BR')));
    });

    test('a language shows by its own name, or its id when unknown', () {
      expect(languageName(_langs, const LangId('it')), 'Italiano');
      expect(languageName(_langs, const LangId('scn')), 'scn');
    });
  });

  test('dump date reads day first', () {
    expect(dumpDateLabel('2026-10-01'), '01/10/2026');
    expect(dumpDateLabel(''), '');
  });

  group('Settings screen', () {
    setUpAll(() async {
      await openTestDbs();
      await loadSettings();
    });

    testWidgets('opens with Idiomas and ends with the app colophon', (t) async {
      t.view.physicalSize = const Size(402 * 3, 1400 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(const PostillaApp(home: Shell()));
      await settle(t);
      await t.tap(find.text('Ajustes').last);
      await settle(t);

      final idiomas = t.getTopLeft(find.text('IDIOMAS')).dy;
      expect(idiomas, lessThan(t.getTopLeft(find.text('Leitura')).dy));
      expect(find.text('Aprendo'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Traduções em'), findsOneWidget);
      expect(find.textContaining('Ao trocar, as histórias no novo idioma'), findsOneWidget);

      expect(t.getTopLeft(find.text('SOBRE')).dy, greaterThan(t.getTopLeft(find.text('Imersão')).dy));
      expect(find.text('APP'), findsOneWidget);
      expect(find.text('Versão 0.1.0'), findsOneWidget);
      expect(find.text('8 no aparelho'), findsOneWidget);
      expect(find.text('Sincronização 0'), findsOneWidget);
      expect(find.textContaining('Wikizionario de '), findsOneWidget);
      expect(find.textContaining('Wikizionario, en.wiktionary e WikDict'), findsOneWidget);
    });

    testWidgets('Aprendo opens the picker with the current language checked', (t) async {
      await t.pumpWidget(const PostillaApp(home: Shell()));
      await settle(t);
      await t.tap(find.text('Ajustes').last);
      await settle(t);
      await t.tap(find.text('Aprendo'));
      await settle(t);
      expect(find.byWidgetPredicate((w) => w is Glyph && w.glyph == Glyphs.check), findsOneWidget);
      await t.tap(find.text('Italiano'));
      await settle(t);
      expect(find.text('IDIOMAS'), findsOneWidget);
    });
  });
}
