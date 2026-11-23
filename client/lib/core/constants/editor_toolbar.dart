import '../../l10n/l10n.dart';

/// The buttons of the editor toolbar a user can take off it.
///
/// Preferences → Behavior → Editor → Toolbar buttons lists these with a
/// checkbox each; an unticked one is left out of `QuillSimpleToolbarConfig`
/// (and, for the two custom buttons, out of its `customButtons`). The set of
/// hidden ones is stored by [name], so a button added later is shown until it
/// is unticked, and a name no build knows any more is ignored on read.
///
/// Cut / Copy / Paste, Search, Subscript / Superscript, Alignment and Line
/// height are not here: the toolbar never shows them, and a list of things
/// that cannot be turned on would only pad the dialog.
enum EditorToolbarButton {
  undoRedo,
  fontFamily,
  fontSize,
  bold,
  italic,
  underline,
  strikeThrough,
  inlineCode,
  textColor,
  highlightColor,
  clearFormat,
  headings,
  numberedList,
  bulletedList,
  checklist,
  codeBlock,
  quote,
  indent,
  link,
  insertImage,
  voiceMemo;

  /// The caption in Preferences, in the interface language.
  String get label {
    final l10n = appL10n;
    return switch (this) {
      undoRedo => l10n.prefsToolbarUndoRedo,
      fontFamily => l10n.prefsToolbarFont,
      fontSize => l10n.prefsToolbarSize,
      bold => l10n.prefsToolbarBold,
      italic => l10n.prefsToolbarItalic,
      underline => l10n.prefsToolbarUnderline,
      strikeThrough => l10n.prefsToolbarStrikeThrough,
      inlineCode => l10n.prefsToolbarInlineCode,
      textColor => l10n.prefsToolbarTextColor,
      highlightColor => l10n.prefsToolbarHighlightColor,
      clearFormat => l10n.prefsToolbarClearFormat,
      headings => l10n.prefsToolbarHeadings,
      numberedList => l10n.prefsToolbarNumberedList,
      bulletedList => l10n.prefsToolbarBulletedList,
      checklist => l10n.prefsToolbarChecklist,
      codeBlock => l10n.prefsToolbarCodeBlock,
      quote => l10n.prefsToolbarQuote,
      indent => l10n.prefsToolbarIndent,
      link => l10n.prefsToolbarLink,
      insertImage => l10n.prefsToolbarInsertImage,
      voiceMemo => l10n.prefsToolbarVoiceMemo,
    };
  }

  /// The buttons named in [names], ignoring any name this build does not
  /// know — a preference written by a newer build must not throw here.
  static Set<EditorToolbarButton> fromNames(Iterable<String>? names) => {
        if (names != null)
          for (final name in names)
            for (final button in values)
              if (button.name == name) button,
      };
}
