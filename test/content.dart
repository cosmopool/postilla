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

/// Abre o isolate do banco com o conteúdo de produção e um `user` novo.
Future<void> openTestDbs() async {
  final cache = Directory('${Directory.systemTemp.path}/postilla-test-content')..createSync(recursive: true);
  final user = Directory.systemTemp.createTempSync('postilla-user');
  await dbOpen(
    userPath: '${user.path}/user.db',
    dictPath: _inflate('dict', cache),
    storiesPath: _inflate('stories', cache),
  );
}
