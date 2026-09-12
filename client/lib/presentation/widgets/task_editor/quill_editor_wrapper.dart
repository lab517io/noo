import 'dart:async';
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/fonts.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/value_controller.dart';
import '../../providers/voice_memo_provider.dart';
import 'attachment_image_embed.dart';
import 'attachment_image_ops.dart';
import 'paste_formatting.dart';
import 'pending_style_controller.dart';
import 'voice_memo_bar.dart';
import 'voice_memo_ops.dart';

/// Synchronous content parsing
Delta _parseContentSync(String content) {
  if (content.isEmpty) {
    return Delta()..insert('\n');
  }

  final trimmed = content.trim();
  final isJson = trimmed.startsWith('[') && trimmed.endsWith(']');

  if (isJson) {
    try {
      final deltaJson = jsonDecode(content) as List<dynamic>;
      return Delta.fromJson(deltaJson);
    } catch (e) {
      // JSON parse failed, try HTML
    }
  }

  // Parse as HTML (legacy content or JSON parse failed)
  try {
    return HtmlToDelta().convert(content);
  } catch (e) {
    return Delta()..insert('\n');
  }
}

/// A wrapper widget for flutter_quill that stores content as Delta JSON.
///
/// Delta JSON is the native format for Quill and preserves all formatting
/// without conversion losses (unlike HTML).
class QuillEditorWrapper extends ConsumerStatefulWidget {
  /// Initial content - can be Delta JSON string or legacy HTML
  final String? initialContent;

  /// Called immediately when content changes (no debounce)
  final ValueChanged<String>? onContentChanged;

  /// Hint text when editor is empty
  final String hintText;

  /// Whether the editor is read-only
  final bool readOnly;

  /// Focus node for the editor
  final FocusNode? focusNode;

  /// Identifies the document being edited (the task id). Used to tell a switch
  /// to a different task — where the caret belongs at the top — from a refresh
  /// of the *same* task, where the user's caret and selection must survive.
  final Object? contentKey;

  /// Task owning this content. Images inserted into the text are stored as
  /// attachments of this task; without it the image button is hidden.
  final int? taskId;

  const QuillEditorWrapper({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.hintText = 'Start typing...',
    this.readOnly = false,
    this.focusNode,
    this.contentKey,
    this.taskId,
  });

  @override
  ConsumerState<QuillEditorWrapper> createState() => QuillEditorWrapperState();
}

class QuillEditorWrapperState extends ConsumerState<QuillEditorWrapper> {
  late QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _changeSubscription;
  String? _loadedContent;

  /// Global position of the last right-click (secondary tap) inside the editor.
  /// flutter_quill's default context menu anchors to the text *selection*, so a
  /// right-click far from the selection pops the menu up far from the pointer.
  /// We record the pointer position here and anchor the menu to it instead.
  Offset? _lastSecondaryTapDownPosition;

  /// Fallback focus node when the caller doesn't provide one; owned and
  /// disposed here (a per-build FocusNode() would leak).
  FocusNode? _fallbackFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_fallbackFocusNode ??= FocusNode());

  /// Whether the editor has held keyboard focus at least once — see
  /// [_returnFocusToEditor].
  bool _editorHadFocus = false;

  void _onFocusChanged() {
    if (_effectiveFocusNode.hasFocus) _editorHadFocus = true;
  }

  /// Get current content as Delta JSON string
  String get contentAsJson {
    final delta = _controller.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  /// Check if content is empty
  bool get isEmpty => _controller.document.isEmpty();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _effectiveFocusNode.addListener(_onFocusChanged);
    // Publish the controller so work that starts outside the editor can write
    // into the open document — "Transcribe" in the attachments panel is the
    // one caller today. Deferred to after the frame: mutating a provider
    // during build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controllerRegistration = ref.read(editorControllerProvider.notifier);
        _controllerRegistration!.value = _controller;
      }
    });
  }

  ValueController<QuillController?>? _controllerRegistration;

  @override
  void didUpdateWidget(QuillEditorWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _fallbackFocusNode)
          ?.removeListener(_onFocusChanged);
      _effectiveFocusNode.addListener(_onFocusChanged);
    }

    // If content changed externally (different task selected), update the document
    if (widget.initialContent != _loadedContent) {
      _updateContent(
        widget.initialContent,
        // A different task starts at the top; the same task being refreshed
        // (e.g. a sync pulled remote edits) keeps the caret where it was.
        resetCursor: widget.contentKey != oldWidget.contentKey,
      );
    }
  }

  void _initializeController() {
    final content = widget.initialContent;
    _loadedContent = content;

    // Parse synchronously for immediate display (small content is fast)
    final delta = (content != null && content.isNotEmpty)
        ? _parseContentSync(content)
        : Delta()..insert('\n');

    _controller = PendingStyleQuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          // Runs before the editor's own paste handling, and claims every
          // paste so it can be run a turn later — see [_pasteOffTurn].
          onClipboardPaste: _handleClipboardPaste,
          // Only reached for rich text coming from *another* app; an internal
          // copy pastes its own delta straight through.
          onRichTextPaste: _handleRichTextPaste,
        ),
      ),
    );

    // Listen for document changes
    _changeSubscription = _controller.document.changes.listen(_onDocumentChange);
  }

  /// Claims every paste and performs it one turn later — see [_pasteOffTurn].
  ///
  /// Returns false only for the nested [QuillController.clipboardPaste] that
  /// [_pasteOffTurn] makes, which is the paste the editor's own chain is meant
  /// to handle, and for a paste arriving while that nested call is in flight
  /// (rare: two Ctrl+V within a few milliseconds, e.g. key repeat), which then
  /// simply pastes the way it did before this deferral existed.
  Future<bool> _handleClipboardPaste() async {
    if (widget.readOnly) return false;
    if (_nestedPastes > 0) return false;

    unawaited(_pasteOffTurn());
    return true;
  }

  /// Pastes in flight through [_pasteOffTurn]'s nested `clipboardPaste()`.
  ///
  /// A counter rather than a flag: two overlapping deferred pastes would
  /// otherwise have the first one's exit clear the second one's guard, and the
  /// nested call that followed would be taken for a fresh paste and deferred
  /// again — a paste that schedules a paste, indefinitely.
  int _nestedPastes = 0;

  /// The paste itself, run after the turn that asked for it has finished.
  ///
  /// flutter_quill reveals the caret the instant the paste answers:
  /// `QuillRawEditorState.pasteText` calls `bringIntoView` as soon as
  /// `clipboardPaste()` returns true, in the same turn the document was
  /// mutated in — before the editor has rebuilt for the new content. The
  /// lookup behind that, `RenderEditor.childAtPosition`, resolves the caret's
  /// *node* through the document (already updated) and then hunts for it among
  /// the *render children* (not yet updated). A paste that adds lines — any
  /// rich paste, and any multi-line plain one — creates nodes no render child
  /// owns, so the hunt runs off the end and falls back to
  /// `childAtOffset(Offset(0, 0))`: the first line of the document. The editor
  /// jumps to the top and the caret-following that runs after the next layout
  /// scrolls back, which is the flicker the user sees on Ctrl+V.
  ///
  /// So the document must not change while that reveal is pending. Claiming
  /// the paste and doing it a turn later leaves `bringIntoView` looking at the
  /// document it was built for — where it correctly does nothing, the caret
  /// being where it already was — and leaves the reveal of the pasted text to
  /// `_showCaretOnScreen`, which runs after the frame and gets it right.
  ///
  /// A zero-duration timer rather than waiting for the frame: it is ordered
  /// after the microtasks that carry `pasteText` to `bringIntoView`, which is
  /// all this needs, and unlike `endOfFrame` it still fires when the window is
  /// producing no frames at all.
  Future<void> _pasteOffTurn() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    // An image on the clipboard is filed as an attachment of the open task,
    // and so needs one — without a task there is nowhere to put it.
    final taskId = widget.taskId;
    if (taskId != null &&
        await pasteImagesFromClipboard(ref, _controller, taskId)) {
      return;
    }
    if (!mounted) return;

    // Plain-text pasting is handled here rather than left to quill so that it
    // never goes looking for the clipboard's HTML.
    if (_pasteFormatting == PasteFormatting.plainText &&
        await _pastePlainText()) {
      return;
    }
    if (!mounted) return;

    // Everything else is quill's own paste chain — internal delta, HTML,
    // markdown, plain text. Entered directly rather than through `pasteText`,
    // so no `bringIntoView` follows it.
    _nestedPastes++;
    try {
      await _controller.clipboardPaste();
    } finally {
      _nestedPastes--;
    }
  }

  /// The paste preference as it stands *now* — read rather than watched,
  /// because the controller's clipboard config is built once in [initState]
  /// and a preference changed since then still has to take effect.
  PasteFormatting get _pasteFormatting =>
      ref.read(settingsProvider).pasteFormatting;

  /// Replace the selection with the clipboard's plain text, dropping whatever
  /// formatting came with it.
  ///
  /// Returns false when there is no text at all, so an unhandled clipboard
  /// (a file, an image the image path declined) still reaches the editor's own
  /// paste handling.
  Future<bool> _pastePlainText() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || text.isEmpty) return false;
    if (!mounted) return false;

    insertPlainText(_controller, text);
    return true;
  }

  /// Strip the pasted rich text down to what the user asked for.
  ///
  /// Returning null keeps flutter_quill's own delta. The plain-text mode never
  /// gets here — [_handleClipboardPaste] has already claimed the paste — but
  /// it is answered anyway so a future path into rich paste cannot leak
  /// formatting past the preference.
  Future<Delta?> _handleRichTextPaste(Delta delta, bool isExternal) async {
    switch (_pasteFormatting) {
      case PasteFormatting.keep:
        return null;
      case PasteFormatting.stripStyling:
        return stripAppearanceAttributes(delta);
      case PasteFormatting.plainText:
        return Delta()..insert(deltaToPlainText(delta));
    }
  }

  void _updateContent(String? content, {bool resetCursor = true}) {
    _loadedContent = content;
    final delta = _parseContentDirect(content);

    if (!mounted) return;

    // Remember where the user was before the document is swapped out.
    final previousSelection = _controller.selection;

    // Replace the document content. The changes stream lives on the Document
    // instance, so the old subscription is now stale — drop it and re-subscribe
    // to the new document's stream. The swap itself emits nothing on the new
    // stream (it is subscribed afterwards) and a selection move is not a
    // document change, so no notification has to be suppressed here.
    //
    // The swap is not a keystroke, and flutter_quill has to be told so: on a
    // controller change it otherwise behaves as if the user typed — on a phone
    // with the soft keyboard down that pops the keyboard, steals focus, and
    // skips refreshing the IME's copy of the text, after which real keystrokes
    // are diffed against stale text. With the flag set it refreshes the IME
    // and leaves focus alone.
    _changeSubscription?.cancel();
    _controller.ignoreFocusOnTextChange = true;
    try {
      _controller.document = Document.fromDelta(delta);
      _changeSubscription =
          _controller.document.changes.listen(_onDocumentChange);

      if (resetCursor) {
        _controller.moveCursorToStart();
      } else {
        _restoreSelection(previousSelection);
      }
    } finally {
      _controller.ignoreFocusOnTextChange = false;
    }
  }

  /// Re-applies [selection] to the freshly swapped document, clamped to its
  /// bounds.
  ///
  /// A refresh of the open task is usually the same text give or take a remote
  /// edit, so holding the offsets is much closer to the user's intent than
  /// snapping to the top. It also keeps an active selection alive — without it
  /// a sync landing mid-selection silently turns the next Ctrl+C into a no-op.
  void _restoreSelection(TextSelection selection) {
    // The document always ends with a trailing newline that the caret can't
    // sit past, hence length - 1.
    final maxOffset = _controller.document.length - 1;
    if (maxOffset <= 0) {
      _controller.moveCursorToStart();
      return;
    }
    _controller.updateSelection(
      TextSelection(
        baseOffset: selection.baseOffset.clamp(0, maxOffset),
        extentOffset: selection.extentOffset.clamp(0, maxOffset),
        affinity: selection.affinity,
      ),
      ChangeSource.local,
    );
  }

  /// Direct synchronous parsing - no async, no await, no event loop yield
  Delta _parseContentDirect(String? content) {
    if (content == null || content.isEmpty) {
      return Delta()..insert('\n');
    }
    return _parseContentSync(content);
  }

  void _onDocumentChange(DocChange change) {
    // Notify parent immediately so content is always up-to-date
    widget.onContentChanged?.call(contentAsJson);
  }

  @override
  void dispose() {
    // Unregister only if the registration is still ours: a replacement wrapper
    // may already have published its own controller.
    if (_controllerRegistration?.value == _controller) {
      _controllerRegistration!.value = null;
    }
    _changeSubscription?.cancel();
    widget.focusNode?.removeListener(_onFocusChanged);
    _controller.dispose();
    _scrollController.dispose();
    _fallbackFocusNode?.dispose();
    super.dispose();
  }

  /// Builds the editor's text-selection context menu, anchored at the last
  /// right-click position when available (falling back to flutter_quill's
  /// selection-based anchors for keyboard/other triggers).
  Widget _buildContextMenu(BuildContext context, QuillRawEditorState state) {
    // A right-click with nothing selected moves the caret to the pointer, and
    // quill still lists Copy and Cut for it — both silently do nothing on a
    // collapsed selection. Leave them out so the menu does not promise a copy
    // it cannot make.
    final collapsed = _controller.selection.isCollapsed;
    final buttonItems = state.contextMenuButtonItems
        .where((item) =>
            !collapsed ||
            (item.type != ContextMenuButtonType.copy &&
                item.type != ContextMenuButtonType.cut))
        .toList();
    if (buttonItems.isEmpty) return const SizedBox.shrink();

    final position = _lastSecondaryTapDownPosition;
    final anchors = position != null
        ? TextSelectionToolbarAnchors(primaryAnchor: position)
        : state.contextMenuAnchors;

    return TextFieldTapRegion(
      child: AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: buttonItems,
        anchors: anchors,
      ),
    );
  }

  /// Handles Ctrl+Shift+V (Cmd+Shift+V on macOS): paste the clipboard's plain
  /// text whatever the paste preference says.
  ///
  /// Nothing binds this combination — Flutter's text shortcuts only claim
  /// Ctrl+V — so the editor is free to, and every other editor the user knows
  /// pastes without formatting on it. The paste itself is asynchronous while
  /// key handling is not, so it is started and the event claimed straight
  /// away; the alternative is letting Ctrl+V's handler run as well and pasting
  /// twice.
  KeyEventResult? _handlePastePlainKey(KeyEvent event) {
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.keyV) return null;
    if (widget.readOnly) return null;

    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isShiftPressed) return null;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return null;

    unawaited(_pastePlainText());
    return KeyEventResult.handled;
  }

  /// Handles the Tab key so it inserts configurable whitespace instead of a
  /// literal tab. Runs before flutter_quill's own Tab handling (via
  /// [QuillEditorConfig.onKeyPressed]); returning null defers to the built-in
  /// behaviour, which we keep for list indentation and Shift+Tab outdent.
  KeyEventResult? _handleTabKey(
    KeyEvent event,
    Node? node,
    int tabWidth,
    bool tabAsSpaces,
  ) {
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey != LogicalKeyboardKey.tab) return null;
    if (widget.readOnly) return null;

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return null;
    }
    // Let the editor handle Shift+Tab (list outdent) itself.
    if (keyboard.isShiftPressed) return null;

    final selection = _controller.selection;
    // For a non-collapsed selection, defer to the built-in behaviour, which
    // indents list items (and does nothing otherwise).
    if (selection.baseOffset != selection.extentOffset) return null;

    // Inside a list/checklist, keep the built-in Tab-to-indent behaviour.
    final parent = node?.parent;
    if (parent is Block) {
      final style = parent.style;
      if (style.containsKey(Attribute.ol.key) ||
          style.containsKey(Attribute.ul.key) ||
          style.containsKey(Attribute.checked.key)) {
        return null;
      }
    }

    final insert = tabAsSpaces ? ' ' * tabWidth : '\t';
    final base = selection.baseOffset;
    _controller.replaceText(base, 0, insert, null);
    _controller.updateSelection(
      TextSelection.collapsed(offset: base + insert.length),
      ChangeSource.local,
    );
    return KeyEventResult.handled;
  }

  /// Hands the editor keyboard focus the moment a mouse press lands in it.
  ///
  /// flutter_quill only asks for focus on tap-*up*, and Flutter's own gesture
  /// builder behaves the same way, so selecting text by *dragging* never
  /// focuses the editor. The selection is painted regardless of focus, which
  /// leaves the editor looking ready while Ctrl+C/Ctrl+X — routed by focus —
  /// go to whoever still holds it (usually the tree) and do nothing at all.
  /// See also `editorFocusProvider`, which covers the same trap when the
  /// search panel or the tree's inline rename takes focus away.
  ///
  /// Precise pointers only: on a touch screen a press that becomes a drag is a
  /// scroll, and focusing there would pop the soft keyboard open mid-scroll.
  /// Touch taps still focus the editor through flutter_quill's own tap-up path.
  void _focusOnPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.touch) return;
    final node = _effectiveFocusNode;
    if (!node.hasFocus && node.canRequestFocus) node.requestFocus();
  }

  /// Puts focus back in the editor after a toolbar button that took it away.
  ///
  /// Pressing Italic/Bold with an empty selection only *arms* the style: quill
  /// parks it in `toggledStyle` and applies it to the next character typed.
  /// Any selection update wipes `toggledStyle`, so when the press costs the
  /// editor its focus, the click the user needs to get back into the text
  /// disarms the button again and they carry on typing in the plain font.
  ///
  /// The toolbar sits in a [TextFieldTapRegion] so an ordinary button press no
  /// longer unfocuses the editor at all; this covers the buttons that open a
  /// route of their own — the header dropdown, the link dialog, the image
  /// picker — which take focus with them regardless.
  void _returnFocusToEditor() {
    // Only ever reclaim focus that was ours: grabbing it from a user who never
    // put the caret in the text would pop the soft keyboard open on a phone.
    if (!_editorHadFocus) return;
    final node = _effectiveFocusNode;
    if (!node.hasFocus && node.canRequestFocus) node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final taskId = widget.taskId;
    // Watched, not read: the mic button is a stop button while recording.
    final recordingMemo = ref.watch(voiceMemoProvider).isRecording;
    final tabWidth = settings.editorTabWidth;
    final tabAsSpaces = settings.editorTabAsSpaces;
    final userFontStyle = fontSettingsToStyle(
      settings,
      base: theme.textTheme.bodyMedium,
    );
    final defaultStyles = DefaultStyles.getInstance(context).merge(
      DefaultStyles(
        paragraph: DefaultTextBlockStyle(
          userFontStyle,
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(6, 0),
          const VerticalSpacing(0, 0),
          null,
        ),
      ),
    );

    return Column(
      children: [
        // Toolbar. Inside a TextFieldTapRegion so that pressing a button
        // doesn't register as a tap outside the editor — which unfocuses it
        // and costs the user the style they just armed. See
        // _returnFocusToEditor.
        TextFieldTapRegion(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                showFontFamily: true,
                showFontSize: true,
                showBackgroundColorButton: true,
                showClearFormat: true,
                showColorButton: true,
                showSubscript: false,
                showSuperscript: false,
                showInlineCode: true,
                showCodeBlock: true,
                showQuote: true,
                showIndent: true,
                showLink: true,
                showSearchButton: false,
                showClipboardCut: false,
                showClipboardCopy: false,
                showClipboardPaste: false,
                multiRowsDisplay: false,
                toolbarIconCrossAlignment: WrapCrossAlignment.center,
                customButtons: [
                  if (taskId != null && !widget.readOnly)
                    QuillToolbarCustomButtonOptions(
                      icon: const Icon(Icons.image_outlined, size: 18),
                      tooltip: 'Insert image',
                      onPressed: () =>
                          insertImagesFromPicker(ref, _controller, taskId),
                    ),
                  if (taskId != null && !widget.readOnly)
                    QuillToolbarCustomButtonOptions(
                      icon: Icon(
                        recordingMemo ? Icons.stop_circle_outlined : Icons.mic_none,
                        size: 18,
                        color: recordingMemo ? theme.colorScheme.error : null,
                      ),
                      tooltip:
                          recordingMemo ? 'Stop recording' : 'Record voice memo',
                      onPressed: () =>
                          toggleVoiceMemo(context, ref, _controller, taskId),
                    ),
                ],
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconSize: 18,
                    iconButtonFactor: 1.2,
                    afterButtonPressed: _returnFocusToEditor,
                  ),
                  // Neither dropdown may be given a `width`: that switches its
                  // label to an Expanded inside a Row, and the single-row
                  // toolbar lays out unbounded, which asserts.
                  fontFamily: QuillToolbarFontFamilyButtonOptions(
                    items: kEditorFontFamilies,
                    // The menu labels render in their own family, which is the
                    // only preview of a font the user gets.
                    renderFontFamilies: true,
                    defaultDisplayText: 'Font',
                  ),
                  fontSize: const QuillToolbarFontSizeButtonOptions(
                    items: kEditorFontSizes,
                    defaultDisplayText: 'Size',
                  ),
                ),
              ),
            ),
          ),
        ),
        // Recording strip. Draws nothing unless a memo is being recorded or
        // the last attempt failed, and sits outside the editor so collapsing
        // the attachments panel cannot take a recording with it.
        if (!widget.readOnly)
          VoiceMemoBar(taskId: taskId, controller: _controller),
        // Editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Capture the right-click position before the editor builds its
            // context menu, so we can anchor the menu at the pointer.
            child: Listener(
              onPointerDown: (event) {
                if (event.buttons == kSecondaryButton) {
                  _lastSecondaryTapDownPosition = event.position;
                } else if (event.buttons == kPrimaryButton) {
                  // A left-click means the next toolbar (e.g. after a keyboard
                  // selection) should anchor to the selection, not a stale
                  // right-click spot.
                  _lastSecondaryTapDownPosition = null;
                  _focusOnPointerDown(event);
                }
              },
              child: QuillEditor(
                controller: _controller,
                scrollController: _scrollController,
                focusNode: _effectiveFocusNode,
                config: QuillEditorConfig(
                  placeholder: widget.hintText,
                  readOnlyMouseCursor: SystemMouseCursors.text,
                  padding: EdgeInsets.zero,
                  expands: true,
                  autoFocus: false,
                  scrollable: true,
                  customStyles: defaultStyles,
                  embedBuilders: [
                    AttachmentImageEmbedBuilder(taskId: widget.taskId),
                  ],
                  contextMenuBuilder: _buildContextMenu,
                  onKeyPressed: (event, node) =>
                      _handlePastePlainKey(event) ??
                      _handleTabKey(event, node, tabWidth, tabAsSpaces),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
