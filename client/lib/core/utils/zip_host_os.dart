import 'dart:io';
import 'dart:typed_data';

/// Central directory file header signature (`PK\x01\x02`).
const _centralHeaderSignature = 0x02014b50;

/// End of central directory record signature (`PK\x05\x06`).
const _eocdSignature = 0x06054b50;

/// Zip64 end of central directory locator signature (`PK\x06\x07`).
const _zip64LocatorSignature = 0x07064b50;

/// Zip64 end of central directory record signature (`PK\x06\x06`).
const _zip64EocdSignature = 0x06064b50;

/// "Version made by" host system codes.
const _hostMsDos = 0;
const _hostUnix = 3;

/// The EOCD record is 22 bytes plus a comment of at most 64 KB.
const _maxEocdSearch = 22 + 0xFFFF;

/// Rewrite every central directory entry of [zipPath] to declare Unix as the
/// host system of the "version made by" field.
///
/// package:archive hardcodes MS-DOS there, even though it already writes Unix
/// permission bits into the external attributes. DOS-heritage extractors —
/// Info-ZIP `unzip` among them, which is what most Linux file managers shell
/// out to — take that byte as licence to treat the entry name as OEM text and
/// transcode it to the local charset. Our names are UTF-8 (the language
/// encoding flag says so), so a Cyrillic directory arrives as the box-drawing
/// soup that CP866 makes of UTF-8 bytes. Saying "Unix" stops the transcoding.
///
/// Patches the central directory in place; the entry data is untouched, so the
/// file's offsets stay valid. A structure we cannot parse is left alone rather
/// than guessed at — a mis-decoded name beats a corrupt archive.
Future<void> markZipEntriesAsUnixHost(String zipPath) async {
  final raf = await File(zipPath).open(mode: FileMode.append);
  try {
    final length = await raf.length();
    final centralDirOffset = await _centralDirectoryOffset(raf, length);
    if (centralDirOffset == null || centralDirOffset >= length) return;

    await raf.setPosition(centralDirOffset);
    final central = await raf.read(length - centralDirOffset);
    if (!_patchCentralDirectory(central)) return;

    await raf.setPosition(centralDirOffset);
    await raf.writeFrom(central);
  } finally {
    await raf.close();
  }
}

/// Flip the host system byte of every central directory header in [central],
/// which starts at the first header. Returns false if the walk hits anything
/// unexpected — the caller then leaves the file as it found it.
bool _patchCentralDirectory(Uint8List central) {
  final view = ByteData.sublistView(central);
  var pos = 0;
  var patched = false;
  while (pos + 46 <= central.length &&
      view.getUint32(pos, Endian.little) == _centralHeaderSignature) {
    // "Version made by" is a little-endian uint16 of (host system << 8 | spec
    // version), so the host system lives in the high byte.
    if (central[pos + 5] == _hostMsDos) {
      central[pos + 5] = _hostUnix;
      patched = true;
    }
    final nameLength = view.getUint16(pos + 28, Endian.little);
    final extraLength = view.getUint16(pos + 30, Endian.little);
    final commentLength = view.getUint16(pos + 32, Endian.little);
    pos += 46 + nameLength + extraLength + commentLength;
  }
  return patched;
}

/// Offset of the first central directory header, or null if the trailing
/// records do not parse.
Future<int?> _centralDirectoryOffset(RandomAccessFile raf, int length) async {
  final tailLength = length < _maxEocdSearch ? length : _maxEocdSearch;
  await raf.setPosition(length - tailLength);
  final tail = await raf.read(tailLength);
  final tailView = ByteData.sublistView(tail);
  final tailStart = length - tailLength;

  final eocd = _lastSignature(tailView, tail.length, 22, _eocdSignature);
  if (eocd == null) return null;

  final offset = tailView.getUint32(eocd + 16, Endian.little);
  if (offset != 0xFFFFFFFF) return offset;

  // Zip64: the real offset sits in the record the locator points at. Not
  // something an Obsidian vault is likely to reach, but the fallback is one
  // more hop rather than a wrong answer.
  final locator =
      _lastSignature(tailView, eocd, 20, _zip64LocatorSignature);
  if (locator == null) return null;
  final zip64Eocd = tailView.getUint64(locator + 8, Endian.little);
  if (zip64Eocd < tailStart || zip64Eocd + 56 > length) return null;
  final inTail = zip64Eocd - tailStart;
  if (tailView.getUint32(inTail, Endian.little) != _zip64EocdSignature) {
    return null;
  }
  return tailView.getUint64(inTail + 48, Endian.little);
}

/// Index of the last [signature] in `[0, limit)` that leaves at least
/// [recordSize] bytes of record behind it.
int? _lastSignature(
  ByteData view,
  int limit,
  int recordSize,
  int signature,
) {
  for (var i = limit - recordSize; i >= 0; i--) {
    if (view.getUint32(i, Endian.little) == signature) return i;
  }
  return null;
}
