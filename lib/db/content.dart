// Conteúdo embutido (OFF-10, OFF-11): na primeira abertura, cada pacote
// `assets/content/<nome>.db.gz` é descompactado em `<suporte>/content/` e o
// sha256 do `.db` é conferido. O arquivo só ganha o nome final depois de
// conferido, então um `.db` presente está sempre inteiro.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'db.dart';

class ContentPackage {
  const ContentPackage(this.name, this.version, this.dbSha256, this.dbSize);
  final String name;
  final String version;
  final String dbSha256;
  final int dbSize;

  String fileName() => '$name-$version.db';
}

/// O que a abertura precisa saber: onde estão os bancos, ou por que não estão.
class ContentState {
  const ContentState({this.dictPath = '', this.storiesPath = '', this.missingBytes = 0, this.failed = false});
  final String dictPath;
  final String storiesPath;
  final int missingBytes; // > 0: faltou espaço (OFF-12)
  final bool failed;
  bool get ready => dictPath.isNotEmpty && storiesPath.isNotEmpty;
}

Future<List<ContentPackage>> loadLock(AssetBundle bundle) async {
  final m = jsonDecode(await bundle.loadString('assets/content/lock.json')) as Map<String, dynamic>;
  return [
    for (final MapEntry(key: name, value: p as Map<String, dynamic>) in m.entries)
      ContentPackage(name, p['version'] as String, p['db_sha256'] as String, p['db_size'] as int),
  ];
}

/// Pacotes que ainda não estão descompactados em `dir`.
List<ContentPackage> missingPackages(Directory dir, List<ContentPackage> lock) =>
    [for (final p in lock) if (!File('${dir.path}/${p.fileName()}').existsSync()) p];

/// Descompacta o que falta e apaga versões antigas. Roda fora do isolate da UI.
Future<ContentState> prepareContent(AssetBundle bundle, Directory dir, List<ContentPackage> lock) async {
  dir.createSync(recursive: true);
  for (final p in missingPackages(dir, lock)) {
    final gz = await bundle.load('assets/content/${p.name}.db.gz');
    final bytes = TransferableTypedData.fromList([gz.buffer.asUint8List(gz.offsetInBytes, gz.lengthInBytes)]);
    final target = '${dir.path}/${p.fileName()}';
    final result = await Isolate.run(() => _inflate(bytes, target, p.dbSha256));
    if (result == _Inflate.noSpace) return ContentState(missingBytes: p.dbSize);
    if (result == _Inflate.failed) return const ContentState(failed: true);
  }
  // Versões anteriores do mesmo pacote saem na hora (ARQ-24).
  final keep = {for (final p in lock) p.fileName()};
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!keep.contains(name)) {
      try {
        f.deleteSync();
      } catch (e) {
        appLog('content: não apagou $name: $e');
      }
    }
  }
  String path(String name) => '${dir.path}/${lock.firstWhere((p) => p.name == name).fileName()}';
  return ContentState(dictPath: path('dict'), storiesPath: path('stories'));
}

enum _Inflate { ok, noSpace, failed }

_Inflate _inflate(TransferableTypedData gz, String target, String sha) {
  final part = File('$target.part');
  try {
    final input = gz.materialize().asUint8List();
    final out = part.openSync(mode: FileMode.write);
    final digest = _DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    final sink = _FileSink(out, hash);
    final conv = gzip.decoder.startChunkedConversion(sink);
    const chunk = 1 << 16;
    for (var i = 0; i < input.length; i += chunk) {
      conv.add(input.sublist(i, i + chunk > input.length ? input.length : i + chunk));
    }
    conv.close();
    out.closeSync();
    if (digest.value.toString() != sha) {
      appLog('content: sha256 de $target não confere');
      part.deleteSync();
      return _Inflate.failed;
    }
    part.renameSync(target);
    return _Inflate.ok;
  } on FileSystemException catch (e) {
    appLog('content: $e');
    try {
      if (part.existsSync()) part.deleteSync();
    } catch (_) {}
    // ENOSPC: 28 no Linux/Android, 28 no Darwin.
    return e.osError?.errorCode == 28 ? _Inflate.noSpace : _Inflate.failed;
  } catch (e) {
    appLog('content: $e');
    return _Inflate.failed;
  }
}

class _FileSink implements Sink<List<int>> {
  _FileSink(this.file, this.hash);
  final RandomAccessFile file;
  final ByteConversionSink hash;
  @override
  void add(List<int> data) {
    file.writeFromSync(data);
    hash.add(data);
  }

  @override
  void close() => hash.close();
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
