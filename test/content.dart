// Bancos reais para os testes (ARQ-93): os pacotes de assets/content/,
// descompactados uma vez por execução numa pasta temporária.
import 'dart:io';

import 'package:postilla/db/db.dart';

String _inflate(String name, Directory dir) {
  final target = '${dir.path}/$name.db';
  if (!File(target).existsSync()) {
    File(target).writeAsBytesSync(gzip.decode(File('assets/content/$name.db.gz').readAsBytesSync()));
  }
  return target;
}

/// Opens the database isolate with the production content, a fresh `user` and
/// a fresh story index filled from the debug fixture (assets/dev/).
Future<void> openTestDbs() async {
  final cache = Directory('${Directory.systemTemp.path}/postilla-test-content')..createSync(recursive: true);
  final run = Directory.systemTemp.createTempSync('postilla-run');
  await dbOpen(
    userPath: '${run.path}/user.db',
    dictPath: _inflate('dict', cache),
    storiesPath: _inflate('stories', cache),
    indexPath: '${run.path}/stories-index.db',
  );
  await dbLoadIndexFixture(File('assets/dev/index_fixture.json').readAsStringSync());
}
