import 'dart:async';
import 'dart:math' as math;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/noo_chrome.dart';
import '../../../core/utils/task_link.dart';
import '../../../data/database/database.dart';

/// Every task of [db] a note can link to, in outline order, each with the
/// path of its ancestors. [excludeTaskId] — the note being written — is left
/// out: a link to the note it stands in goes nowhere.
Future<List<TaskLinkTarget>> loadTaskLinkTargets(
  NooDatabase db, {
  int? excludeTaskId,
}) async {
  final rows = await db.getTaskOutline();
  final byId = {for (final row in rows) row.id: row};

  String pathOf(TaskOutlineRow row) {
    final parts = <String>[];
    var parentId = row.parentId;
    // Bounded, so a corrupt parent cycle cannot spin.
    for (var hops = 0; parentId != null && hops < 64; hops++) {
      final parent = byId[parentId];
      if (parent == null) break;
      parts.add(parent.title.isEmpty ? kUntitledTaskLinkText : parent.title);
      parentId = parent.parentId;
    }
    return parts.reversed.join(' › ');
  }

  return [
    for (final row in rows)
      if (row.id != excludeTaskId && row.worldId.isNotEmpty)
        TaskLinkTarget(
          id: row.id,
          worldId: row.worldId,
          title: row.title,
          path: pathOf(row),
        ),
  ];
}

/// The suggestion list that follows a `[[` typed into a note.
///
/// Typing `[[` opens a list of tasks at the caret, narrowed by what is typed
/// after the brackets; picking one replaces `[[query` with the task's title
/// as a link to it (`noo-task://<worldId>`, see `task_link.dart`).
///
/// The list is an [OverlayEntry], not a route, and never takes focus: the
/// caret stays in the note and the keys reach it through the editor's own
/// key handler ([handleKey]) — which is also why it works on a phone, where
/// the soft keyboard sends no key events and the list is tapped instead.
///
/// It opens only on a *typed* change. A caret merely walked into an old
/// `[[draft` opens nothing: brackets are ordinary text too, and a list that
/// popped up on every visit to `x = [[1, 2` would be in the way.
class TaskLinkPicker {
  TaskLinkPicker({
    required this.controller,
    required this.overlayContext,
    required this.renderEditor,
    required this.loadTargets,
    required this.canSuggest,
    required this.titleStyle,
  });

  final QuillController controller;

  /// A context under the overlay the list is put in; null once unmounted.
  final BuildContext? Function() overlayContext;

  /// Quill's render object, which the caret is measured with.
  final RenderEditor? Function() renderEditor;

  /// Reads the tasks that can be linked to. Called once per opening, so the
  /// list reflects tasks added or renamed since the last one.
  final Future<List<TaskLinkTarget>> Function() loadTargets;

  /// Whether the editor is focused and editable right now.
  final bool Function() canSuggest;

  /// The style of a row's title — the tree's font, since these are its rows.
  final TextStyle Function(BuildContext context) titleStyle;

  static const double _width = 340;
  static const double _rowHeight = 44;
  static const int _visibleRows = 7;

  TaskLinkTrigger? _trigger;
  List<TaskLinkTarget>? _targets;
  List<TaskLinkTarget> _results = const [];
  int _highlighted = 0;
  OverlayEntry? _entry;
  final ScrollController _listScroll = ScrollController();

  /// Where the `[[` the user dismissed with Escape starts. Typing on in that
  /// query does not bring the list back; a new `[[` elsewhere does.
  int? _dismissedStart;

  /// Counts openings, so a load that finishes after its list was closed and
  /// another opened does not fill the wrong one.
  int _session = 0;

  bool _disposed = false;

  /// Whether the list is on screen.
  bool get isShowing => _entry != null;

  /// The rows on offer, best first. For tests.
  List<TaskLinkTarget> get results => _results;

  /// The document changed under the user's hands.
  void onTyped() => _evaluate(typed: true);

  /// The selection (or anything else about the controller) changed.
  void onControllerChanged() {
    if (_trigger != null) _evaluate(typed: false);
  }

  /// The editor scrolled or was laid out again: the caret has moved on
  /// screen, and the list with it.
  void reposition() => _entry?.markNeedsBuild();

  void _evaluate({required bool typed}) {
    if (_disposed) return;
    final selection = controller.selection;
    if (!canSuggest() || !selection.isCollapsed) return close();

    final trigger = taskLinkTriggerAt(
        controller.document.toPlainText(), selection.extentOffset);
    if (trigger == null) {
      _dismissedStart = null;
      return close();
    }
    if (trigger.start == _dismissedStart) return close();
    if (_trigger == null && !typed) return;

    final opening = _trigger == null;
    _trigger = trigger;
    if (opening) {
      final session = ++_session;
      _targets = null;
      unawaited(loadTargets().then((targets) {
        if (_disposed || session != _session || _trigger == null) return;
        _targets = targets;
        _refresh();
      }).catchError((Object _) {
        // The database went away under the list (a lock, a swap): there is
        // nothing to offer, which is what an empty list already means.
      }));
    }
    _refresh();
  }

  void _refresh() {
    final trigger = _trigger;
    final targets = _targets;
    if (trigger == null) return;
    final previous = _highlightedTarget;
    _results =
        targets == null ? const [] : rankTaskLinkTargets(targets, trigger.query);
    // Keep the highlight on the row it was on while the list narrows around
    // it; otherwise start from the best match.
    final kept = previous == null
        ? -1
        : _results.indexWhere((t) => t.id == previous.id);
    _highlighted = kept < 0 ? 0 : kept;

    if (_results.isEmpty) {
      // Nothing matches: get out of the way, but stay armed — a backspace
      // that makes the query match again brings the list back.
      _removeEntry();
      return;
    }
    if (_entry == null) {
      final context = overlayContext();
      final overlay = context == null ? null : Overlay.maybeOf(context);
      if (overlay == null) return;
      _entry = OverlayEntry(builder: _build);
      overlay.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
    _scrollToHighlight();
    // Once more after the frame: the entry builds before the editor has laid
    // out the character just typed, so the caret it measured is a keystroke
    // behind.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entry?.markNeedsBuild();
      _scrollToHighlight();
    });
  }

  TaskLinkTarget? get _highlightedTarget =>
      _highlighted < _results.length ? _results[_highlighted] : null;

  /// Takes the list down and forgets the query it was for.
  void close() {
    _trigger = null;
    _results = const [];
    _removeEntry();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void dispose() {
    _disposed = true;
    close();
    _listScroll.dispose();
  }

  /// The editor's key handler, asked first. Null leaves the key to the
  /// editor — every key does while the list is not on screen.
  KeyEventResult? handleKey(KeyEvent event) {
    if (!isShowing) return null;
    if (event is KeyUpEvent) return null;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _move(_visibleRows - 1);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _move(-(_visibleRows - 1));
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      if (event is KeyDownEvent) accept(_results[_highlighted]);
    } else if (key == LogicalKeyboardKey.escape) {
      _dismissedStart = _trigger?.start;
      close();
    } else {
      return null;
    }
    return KeyEventResult.handled;
  }

  void _move(int by) {
    final next = (_highlighted + by).clamp(0, _results.length - 1);
    if (next == _highlighted) return;
    _highlighted = next;
    _entry?.markNeedsBuild();
    _scrollToHighlight();
  }

  void _scrollToHighlight() {
    if (!_listScroll.hasClients) return;
    final position = _listScroll.position;
    final top = _highlighted * _rowHeight;
    final bottom = top + _rowHeight;
    if (top < position.pixels) {
      _listScroll.jumpTo(top);
    } else if (bottom > position.pixels + position.viewportDimension) {
      _listScroll.jumpTo(bottom - position.viewportDimension);
    }
  }

  /// Replaces the `[[query` with a link to [target].
  void accept(TaskLinkTarget target) {
    final trigger = _trigger;
    if (trigger == null) return;
    close();

    final document = controller.document;
    var length = trigger.end - trigger.start;
    // A closing pair typed ahead of the query belongs to it.
    final plain = document.toPlainText();
    if (plain.startsWith(']]', trigger.end)) length += 2;
    if (trigger.start + length > document.length - 1) return;

    final text = target.linkText;
    // One change, so one undo takes the link back to what was typed.
    controller.replaceText(
      trigger.start,
      length,
      Delta()..insert(text, {Attribute.link.key: taskLinkUri(target.worldId)}),
      null,
    );
    controller.updateSelection(
      TextSelection.collapsed(offset: trigger.start + text.length),
      ChangeSource.local,
    );
  }

  Widget _build(BuildContext context) {
    final render = renderEditor();
    final overlayBox = Overlay.of(context).context.findRenderObject();
    final selection = controller.selection;
    if (render == null ||
        overlayBox is! RenderBox ||
        !selection.isCollapsed ||
        selection.extentOffset > controller.document.length - 1) {
      return const SizedBox.shrink();
    }

    // The caret's foot in the overlay's coordinates. Measured here, on every
    // build, so the list follows the text as it scrolls.
    final Offset foot;
    final double lineHeight;
    try {
      final point = render.getEndpointsForSelection(selection).first.point;
      foot = render.localToGlobal(point, ancestor: overlayBox);
      lineHeight = render.preferredLineHeight(selection.extent);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final area = overlayBox.size;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final width = math.min(_width, area.width - 16);
    final height =
        math.min(_results.length, _visibleRows) * _rowHeight + 2;
    // Under the caret when there is room; otherwise over the line, so the
    // text being typed is never covered.
    final below = foot.dy + 4;
    final fitsBelow = below + height <= area.height - inset - 8;
    final top = fitsBelow
        ? below
        : math.max(8.0, foot.dy - lineHeight - 4 - height);
    final left = (foot.dx).clamp(8.0, math.max(8.0, area.width - width - 8));

    final theme = Theme.of(context);
    final chrome = NooChrome.of(context);
    final title = titleStyle(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Positioned(
      left: left.toDouble(),
      top: top,
      width: width,
      height: height.toDouble(),
      // A tap in the list is not a tap outside the editor: without this the
      // editor would drop focus, and the keyboard with it, before the tap
      // picked anything.
      child: TextFieldTapRegion(
        child: Material(
          elevation: 6,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: chrome.smallRadius,
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            controller: _listScroll,
            padding: EdgeInsets.zero,
            itemExtent: _rowHeight,
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final target = _results[index];
              return InkWell(
                // Focus stays in the note.
                canRequestFocus: false,
                onTap: () => accept(target),
                child: Container(
                  color: index == _highlighted
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.linkText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: title,
                      ),
                      if (target.path.isNotEmpty)
                        Text(
                          target.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
