/// A name that can only denote a file *inside* the directory it is joined to.
///
/// Attachment names are free text: the Rename dialog accepts anything, and a
/// name arrives from another device through sync exactly as it was typed
/// there. Joining such a name onto a staging directory trusts it with the
/// path — `..` segments walk out of the directory and an absolute name
/// replaces it outright, and on Android the staging directory sits beside the
/// database. So only the last segment survives, with the characters no
/// filesystem here accepts turned into underscores.
String safeFilename(String filename, {String fallback = 'file'}) {
  final last = filename.split(RegExp(r'[/\\]')).last;
  final cleaned = last
      .replaceAll(RegExp(r'[\x00-\x1f:*?"<>|]'), '_')
      // A name that is nothing but dots is a directory reference, not a file.
      .replaceAll(RegExp(r'[.\s]+$'), '')
      .trim();
  return cleaned.isEmpty ? fallback : cleaned;
}
