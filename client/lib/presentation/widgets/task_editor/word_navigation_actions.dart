import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Repairs forward word navigation at the very end of the document.
///
/// quill builds the "next word boundary" for Ctrl+Right out of two steps: skip
/// whitespace, then take the end of the word that follows. When nothing but
/// whitespace is left — the caret sits in the last word of the last line, and
/// the only character after it is the newline every quill document ends with —
/// the first step runs past the last character and hands the second one an
/// offset equal to the document length. `RenderEditor.getWordBoundary` cannot
/// resolve that offset to a line (`queryChild` returns no node for it) and
/// falls back to the *first* line of the document, so the boundary comes back
/// measured in the wrong paragraph. The caret jumps backwards instead of
/// stopping at the end of the text; Ctrl+Shift+Right drags the selection
/// backwards with it, and Ctrl+Delete throws a RangeError on the reversed
/// range it produces.
///
/// The three intents below are quill's own, registered with
/// `Action.overridable`, so an [Actions] ancestor of the editor replaces them.
/// Each override handles only that end-of-document case — where the correct
/// answer is simply "the end of the text" — and delegates everything else,
/// unchanged, to quill via [Action.callingAction].
class WordNavigationActions extends StatelessWidget {
  const WordNavigationActions({
    required this.controller,
    required this.child,
    super.key,
  });

  final QuillController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ExtendSelectionToNextWordBoundaryIntent:
            _ExtendSelectionToDocumentEndAction(controller),
        ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
            _ExtendSelectionOrCaretToDocumentEndAction(controller),
        DeleteToNextWordBoundaryIntent: _DeleteToDocumentEndAction(controller),
      },
      child: child,
    );
  }
}

/// The last offset the caret may take: a quill document always ends with a
/// newline that cannot be selected past.
int _endOfText(QuillController controller) => controller.document.length - 1;

/// Whether moving forward from [offset] would run off the end of the document,
/// which is exactly when quill's word boundary misreads the position: every
/// remaining character is whitespace, so its whitespace step finds no word to
/// stop in front of.
bool _onlyWhitespaceAfter(QuillController controller, int offset) {
  final text = controller.document.toPlainText();
  if (offset < 0 || offset >= text.length) {
    return true;
  }
  return text.substring(offset).trim().isEmpty;
}

/// Shared plumbing: keep quill's own enablement (it gates deletion on
/// `readOnly` and every intent on a valid selection) by asking the action we
/// are standing in for.
abstract class _WordBoundaryOverride<T extends Intent> extends Action<T> {
  _WordBoundaryOverride(this.controller);

  final QuillController controller;

  @override
  bool get isActionEnabled => callingAction?.isActionEnabled ?? true;

  Object? _delegate(T intent) => callingAction?.invoke(intent);
}

/// Ctrl+Right and Ctrl+Shift+Right.
class _ExtendSelectionToDocumentEndAction
    extends _WordBoundaryOverride<ExtendSelectionToNextWordBoundaryIntent> {
  _ExtendSelectionToDocumentEndAction(super.controller);

  @override
  Object? invoke(ExtendSelectionToNextWordBoundaryIntent intent) {
    final selection = controller.selection;
    if (!intent.forward ||
        !selection.isValid ||
        !_onlyWhitespaceAfter(controller, selection.extentOffset)) {
      return _delegate(intent);
    }

    final end = _endOfText(controller);
    final extended = selection.extendTo(TextPosition(offset: end));
    // quill moves the extent first and collapses afterwards, including when
    // the move turned the selection around.
    final reversed = !selection.isCollapsed &&
        intent.collapseAtReversal &&
        (selection.baseOffset < selection.extentOffset !=
            extended.baseOffset < extended.extentOffset);
    controller.updateSelection(
      intent.collapseSelection
          ? TextSelection.collapsed(offset: end)
          : reversed
              ? TextSelection.collapsed(offset: selection.baseOffset)
              : extended,
      ChangeSource.local,
    );
    return null;
  }
}

/// Alt+Shift+Right on macOS.
class _ExtendSelectionOrCaretToDocumentEndAction extends _WordBoundaryOverride<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  _ExtendSelectionOrCaretToDocumentEndAction(super.controller);

  @override
  Object? invoke(
      ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent) {
    final selection = controller.selection;
    if (!intent.forward ||
        !selection.isValid ||
        !_onlyWhitespaceAfter(controller, selection.extentOffset)) {
      return _delegate(intent);
    }

    final end = _endOfText(controller);
    // Moving the extent past the anchor collapses to the anchor instead, which
    // is what this intent means by "or caret location".
    final reverses = (end - selection.baseOffset) *
            (selection.extentOffset - selection.baseOffset) <
        0;
    controller.updateSelection(
      reverses
          ? TextSelection.collapsed(offset: selection.baseOffset)
          : selection.extendTo(TextPosition(offset: end)),
      ChangeSource.local,
    );
    return null;
  }
}

/// Ctrl+Delete: with only whitespace left there is no next word, so the
/// trailing blank lines are what gets deleted.
class _DeleteToDocumentEndAction
    extends _WordBoundaryOverride<DeleteToNextWordBoundaryIntent> {
  _DeleteToDocumentEndAction(super.controller);

  @override
  Object? invoke(DeleteToNextWordBoundaryIntent intent) {
    final selection = controller.selection;
    if (!intent.forward ||
        !selection.isValid ||
        !selection.isCollapsed ||
        !_onlyWhitespaceAfter(controller, selection.extentOffset)) {
      return _delegate(intent);
    }

    final at = selection.extentOffset;
    final length = _endOfText(controller) - at;
    if (length <= 0) {
      return null;
    }
    controller.replaceText(
      at,
      length,
      '',
      TextSelection.collapsed(offset: at),
    );
    return null;
  }
}
