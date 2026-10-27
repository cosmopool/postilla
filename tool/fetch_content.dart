// Copia os pacotes fixados em content.lock de ../postilla-content/out para
// assets/content/ e confere o sha256 de cada um (ARQ-14). Roda antes de
// `flutter build` e de `flutter test`:
//
//   dart run tool/fetch_content.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

void main() {
  final lock = jsonDecode(File('content.lock').readAsStringSync()) as Map<String, dynamic>;
  final source = lock['source'] as String;
  final packages = lock['packages'] as Map<String, dynamic>;
  Directory('assets/content').createSync(recursive: true);

  final manifest = <String, dynamic>{};
  var failed = false;
  for (final MapEntry(key: name, value: p as Map<String, dynamic>) in packages.entries) {
    final from = File('$source/$name-${p['version']}.db.gz');
    final to = File('assets/content/$name.db.gz');
    if (!from.existsSync()) {
      stderr.writeln('$name: falta ${from.path} (rode `zig build run -- pack` no postilla-content)');
      failed = true;
      continue;
    }
    final sum = sha256.convert(from.readAsBytesSync()).toString();
    if (sum != p['gz_sha256']) {
      stderr.writeln('$name: sha256 $sum não bate com o content.lock (${p['gz_sha256']})');
      failed = true;
      continue;
    }
    from.copySync(to.path);
    manifest[name] = p;
    stdout.writeln('$name ${p['version']} → ${to.path}');
  }
  if (failed) exit(1);
  // O app lê versões e sha256 daqui (o content.lock não vai no pacote do app).
  File('assets/content/lock.json').writeAsStringSync(jsonEncode(manifest));
}
