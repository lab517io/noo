import '../../l10n/l10n.dart';

/// The character the editor's **Format as table** splits a line into columns
/// on. Preferences → Behavior → Editor → Table columns; stored by [name].
///
/// A separator inside a URL (`https://host:8080/a`) or inside a quoted string
/// (`"a: b"`, `'x, y'`) is part of its cell, never a column break — see
/// `splitTableCells` in `editor_commands.dart`.
enum TableSeparator {
  colon(':', TableSeparatorStyle.attached),
  equals('=', TableSeparatorStyle.spaced),
  pipe('|', TableSeparatorStyle.spaced),
  semicolon(';', TableSeparatorStyle.attached),
  comma(',', TableSeparatorStyle.attached),
  tab('\t', TableSeparatorStyle.replaced);

  const TableSeparator(this.char, this.style);

  /// The character itself.
  final String char;

  /// How the editor's menu names it: the character itself, or the word for
  /// a tab, which has no visible character.
  String get label => this == tab ? appL10n.prefsSeparatorTab : char;

  /// Where the separator goes in the aligned line.
  final TableSeparatorStyle style;

  /// The stored value, falling back to [colon] — the separator the command
  /// always used — for anything unrecognised.
  static TableSeparator fromName(String? name) {
    return TableSeparator.values.firstWhere(
      (separator) => separator.name == name,
      orElse: () => TableSeparator.colon,
    );
  }
}

/// How an aligned row is written.
enum TableSeparatorStyle {
  /// Punctuation that hugs the cell before it, the padding after it:
  /// `Name:       Dmytro`.
  attached,

  /// A symbol standing between two cells, lined up in a column of its own:
  /// `Name       = Dmytro`.
  spaced,

  /// Replaced by the padding altogether (a tab, which would not line up in
  /// any case): `Name        Dmytro`. Being gone, it cannot be re-fitted.
  replaced,
}
