/// Case folding for search: what "ignore case" means across the languages
/// the interface is offered in.
///
/// `toLowerCase` handles Cyrillic, Greek and accented Latin, and maps `İ` to
/// `i` without changing the length. What it does not do is Turkish's dotless
/// `ı`: a Turkish user types `ılık` for a note holding `ILIK`, which lower-cases
/// to `ilik`. Folding `ı` to `i` as well makes the two meet. One character for
/// one, so offsets found in the folded text are offsets into the original.
library;

/// [text] lower-cased, with the dotless `ı` folded to `i`.
String foldCase(String text) {
  final lower = text.toLowerCase();
  return lower.contains('ı') ? lower.replaceAll('ı', 'i') : lower;
}

/// Whether [text] is all ASCII — then SQLite's own `LIKE` already ignores
/// case correctly and no folding is needed.
bool isAscii(String text) => !text.codeUnits.any((c) => c > 0x7F);
