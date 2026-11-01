import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/zip_host_os.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('zip_host_os_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  /// Zip a vault holding a Cyrillic directory, the way the mobile Obsidian
  /// export does.
  Future<String> buildZip() async {
    final vault = Directory(p.join(tmp.path, 'vault', 'Проект', 'Задача №1'));
    await vault.create(recursive: true);
    await File(p.join(vault.path, 'timeline.txt')).writeAsString('x');
    await File(p.join(vault.parent.path, 'Проект.md')).writeAsString('y');

    final zipPath = p.join(tmp.path, 'export.zip');
    await ZipFileEncoder()
        .zipDirectory(Directory(p.join(tmp.path, 'vault')), filename: zipPath);
    return zipPath;
  }

  /// Host system byte of every central directory header, in file order.
  List<int> hostSystems(String zipPath) {
    final bytes = File(zipPath).readAsBytesSync();
    final view = ByteData.sublistView(bytes);
    final hosts = <int>[];
    for (var i = 0; i + 46 <= bytes.length; i++) {
      if (view.getUint32(i, Endian.little) == 0x02014b50) {
        hosts.add(bytes[i + 5]);
      }
    }
    return hosts;
  }

  test('rewrites the host system of every entry to Unix', () async {
    final zipPath = await buildZip();
    expect(hostSystems(zipPath), everyElement(0), reason: 'archive writes DOS');

    await markZipEntriesAsUnixHost(zipPath);

    expect(hostSystems(zipPath), isNotEmpty);
    expect(hostSystems(zipPath), everyElement(3));
  });

  test('leaves names, contents and length intact', () async {
    final zipPath = await buildZip();
    final lengthBefore = File(zipPath).lengthSync();

    await markZipEntriesAsUnixHost(zipPath);

    expect(File(zipPath).lengthSync(), lengthBefore);
    final archive = ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    expect(
      archive.files.map((f) => f.name),
      containsAll(<String>[
        'Проект/Проект.md',
        'Проект/Задача №1/timeline.txt',
      ]),
    );
    final timeline = archive.files
        .firstWhere((f) => f.name.endsWith('timeline.txt'));
    expect(String.fromCharCodes(timeline.readBytes()!), 'x');
  });

  test('leaves a file that is not a zip alone', () async {
    final path = p.join(tmp.path, 'not-a-zip.bin');
    final bytes = Uint8List.fromList(List<int>.generate(512, (i) => i % 256));
    await File(path).writeAsBytes(bytes);

    await markZipEntriesAsUnixHost(path);

    expect(File(path).readAsBytesSync(), bytes);
  });
}
