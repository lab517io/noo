/// How many columns text takes in a fixed-width font.
///
/// Format as table pads cells with spaces so their separators line up, which
/// only works if the padding is counted in columns rather than in characters:
/// a Chinese or Japanese character (and a full-width form) is drawn two
/// columns wide, the way terminals draw it (Unicode's East Asian Width "W" and
/// "F"). Counted by runes, so a character outside the BMP is one character,
/// not the two UTF-16 units `String.length` would count.
///
/// None of the bundled monospace fonts carries CJK, so those characters come
/// from a system font whose full width is about, not exactly, two Latin
/// columns — close enough to line up a table by eye, which is what a padded
/// plain-text table can promise anyway.
library;

/// Columns [text] occupies.
int displayWidth(String text) {
  var width = 0;
  for (final rune in text.runes) {
    width += isWideRune(rune) ? 2 : 1;
  }
  return width;
}

/// [text] followed by spaces up to [width] columns.
String padToWidth(String text, int width) {
  final missing = width - displayWidth(text);
  return missing > 0 ? text + ' ' * missing : text;
}

/// Whether [rune] is drawn two columns wide (East Asian Wide or Fullwidth).
bool isWideRune(int rune) =>
    (rune >= 0x1100 && rune <= 0x115F) || // Hangul Jamo initials
    (rune >= 0x2E80 && rune <= 0x303E) || // CJK radicals, punctuation
    (rune >= 0x3041 && rune <= 0x33FF) || // kana, CJK compatibility
    (rune >= 0x3400 && rune <= 0x4DBF) || // CJK extension A
    (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK unified ideographs
    (rune >= 0xA000 && rune <= 0xA4CF) || // Yi
    (rune >= 0xAC00 && rune <= 0xD7A3) || // Hangul syllables
    (rune >= 0xF900 && rune <= 0xFAFF) || // CJK compatibility ideographs
    (rune >= 0xFE30 && rune <= 0xFE4F) || // CJK compatibility forms
    (rune >= 0xFF00 && rune <= 0xFF60) || // full-width forms
    (rune >= 0xFFE0 && rune <= 0xFFE6) || // full-width signs
    (rune >= 0x20000 && rune <= 0x3FFFD); // CJK extensions B and beyond
