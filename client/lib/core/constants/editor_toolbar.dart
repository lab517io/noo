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
  undoRedo('Undo / Redo'),
  fontFamily('Font'),
  fontSize('Size'),
  bold('Bold'),
  italic('Italic'),
  underline('Underline'),
  strikeThrough('Strikethrough'),
  inlineCode('Code'),
  textColor('Text colour'),
  highlightColor('Highlight colour'),
  clearFormat('Clear formatting'),
  headings('Headings'),
  numberedList('Numbered list'),
  bulletedList('Bulleted list'),
  checklist('Checklist'),
  codeBlock('Code block'),
  quote('Quote'),
  indent('Indent'),
  link('Link'),
  insertImage('Insert image'),
  voiceMemo('Voice memo');

  const EditorToolbarButton(this.label);

  /// The caption in Preferences.
  final String label;

  /// The buttons named in [names], ignoring any name this build does not
  /// know — a preference written by a newer build must not throw here.
  static Set<EditorToolbarButton> fromNames(Iterable<String>? names) => {
        if (names != null)
          for (final name in names)
            for (final button in values)
              if (button.name == name) button,
      };
}
