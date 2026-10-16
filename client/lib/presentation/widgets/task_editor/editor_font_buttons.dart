import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/constants/fonts.dart';

/// The editor toolbar's Font and Size menus, drawn in place of flutter_quill's
/// own through their options' `childBuilder`.
///
/// quill's buttons name a value only when the text under the caret carries
/// the attribute itself, with a value that is one of the menu's items, and
/// read "Font" / "Size" otherwise. Most text carries neither attribute — it is
/// in the content font from Preferences — so moving through a note mostly
/// showed the placeholders, and a family or size set by a paste (or a family
/// hidden by *Monospace fonts only*) did too. These name what the text is
/// actually drawn in.

/// The Font menu: the `font` attribute's family, whatever it is, and
/// otherwise [contentFamily].
class EditorFontFamilyButton extends StatelessWidget {
  const EditorFontFamilyButton({
    super.key,
    required this.controller,
    required this.items,
    required this.contentFamily,
    this.afterPressed,
  });

  final QuillController controller;

  /// Menu entries, label → stored `font` value; `Clear` removes the attribute.
  final Map<String, String> items;

  /// The content font from Preferences (null = system default): what text
  /// without a `font` attribute is drawn in.
  final String? contentFamily;

  final VoidCallback? afterPressed;

  String _label() {
    final value =
        controller.getSelectionStyle().attributes[Attribute.font.key]?.value;
    if (value is String && value.isNotEmpty) {
      for (final entry in items.entries) {
        if (entry.value == value) return entry.key;
      }
      return fontFamilyLabel(value);
    }
    return fontFamilyLabel(contentFamily);
  }

  @override
  Widget build(BuildContext context) => _ToolbarDropdown(
        controller: controller,
        tooltip: 'Font family',
        label: _label,
        maxLabelWidth: 140,
        afterPressed: afterPressed,
        items: [
          for (final entry in items.entries)
            _DropdownItem(
              label: entry.key,
              isClear: entry.value == 'Clear',
              // The menu labels render in their own family, which is the
              // only preview of a font the user gets.
              fontFamily: entry.value == 'Clear' ? null : entry.value,
              onSelected: () => controller.formatSelection(
                Attribute.fromKeyValue(
                  Attribute.font.key,
                  entry.value == 'Clear' ? null : entry.value,
                ),
              ),
            ),
        ],
      );
}

/// The Size menu: the `size` attribute's size, whatever it is; on a heading
/// line the heading's size; and otherwise the paragraph size, which is the
/// content font size from Preferences. All of it is read from [styles], the
/// styles the editor itself renders with, so the label cannot disagree with
/// the text.
class EditorFontSizeButton extends StatelessWidget {
  const EditorFontSizeButton({
    super.key,
    required this.controller,
    required this.items,
    required this.styles,
    this.afterPressed,
  });

  final QuillController controller;

  /// Menu entries, label → stored `size` value; `0` removes the attribute.
  final Map<String, String> items;

  final DefaultStyles styles;

  final VoidCallback? afterPressed;

  String _label() {
    final attributes = controller.getSelectionStyle().attributes;
    final value = attributes[Attribute.size.key]?.value;
    switch (value) {
      case 'small':
        return _named('Small', styles.sizeSmall?.fontSize);
      case 'large':
        return _named('Large', styles.sizeLarge?.fontSize);
      case 'huge':
        return _named('Huge', styles.sizeHuge?.fontSize);
      case num():
        return formatFontSize(value.toDouble());
      case String() when double.tryParse(value) != null:
        return formatFontSize(double.parse(value));
    }
    final header = switch (attributes[Attribute.header.key]?.value) {
      1 => styles.h1,
      2 => styles.h2,
      3 => styles.h3,
      4 => styles.h4,
      5 => styles.h5,
      6 => styles.h6,
      _ => null,
    };
    final size = (header ?? styles.paragraph)?.style.fontSize;
    return size == null ? 'Size' : formatFontSize(size);
  }

  /// quill's named sizes are a size of their own in the editor's styles;
  /// the number is what the user can compare against the menu.
  static String _named(String name, double? size) =>
      size == null ? name : formatFontSize(size);

  @override
  Widget build(BuildContext context) => _ToolbarDropdown(
        controller: controller,
        tooltip: 'Font size',
        label: _label,
        afterPressed: afterPressed,
        items: [
          for (final entry in items.entries)
            _DropdownItem(
              label: entry.key,
              isClear: entry.value == '0',
              onSelected: () => controller.formatSelection(
                Attribute.fromKeyValue(
                  Attribute.size.key,
                  // Stored as a number, as quill's own button stores it.
                  entry.value == '0' ? null : double.parse(entry.value),
                ),
              ),
            ),
        ],
      );
}

/// A point size as the toolbar writes it: `14`, not `14.0`; `10.5` as is.
String formatFontSize(double size) => size == size.roundToDouble()
    ? size.round().toString()
    : size.toStringAsFixed(1);

class _DropdownItem {
  const _DropdownItem({
    required this.label,
    required this.onSelected,
    this.isClear = false,
    this.fontFamily,
  });

  final String label;
  final VoidCallback onSelected;
  final bool isClear;
  final String? fontFamily;
}

/// The shell both menus share: a label that follows the caret, and a menu.
class _ToolbarDropdown extends StatefulWidget {
  const _ToolbarDropdown({
    required this.controller,
    required this.tooltip,
    required this.label,
    required this.items,
    this.maxLabelWidth,
    this.afterPressed,
  });

  final QuillController controller;
  final String tooltip;

  /// Recomputed whenever the controller changes — selection or content.
  final String Function() label;
  final List<_DropdownItem> items;

  /// Bounds a long label, so it cannot push the rest of the single-row
  /// toolbar around as the caret moves.
  final double? maxLabelWidth;
  final VoidCallback? afterPressed;

  @override
  State<_ToolbarDropdown> createState() => _ToolbarDropdownState();
}

class _ToolbarDropdownState extends State<_ToolbarDropdown> {
  static const double _iconSize = 18;
  static const double _iconButtonFactor = 1.2;

  final _menuController = MenuController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _ToolbarDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _toggleMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    widget.afterPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      widget.label(),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: _iconSize / 1.15),
    );
    if (widget.maxLabelWidth != null) {
      label = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxLabelWidth!),
        child: label,
      );
    }
    return Tooltip(
      message: widget.tooltip,
      child: MenuAnchor(
        controller: _menuController,
        menuChildren: [
          for (final item in widget.items)
            MenuItemButton(
              key: ValueKey(item.label),
              onPressed: () {
                item.onSelected();
                widget.afterPressed?.call();
              },
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: item.fontFamily,
                  color: item.isClear ? Colors.red : null,
                ),
              ),
            ),
        ],
        child: QuillToolbarIconButton(
          isSelected: false,
          iconTheme: null,
          onPressed: _toggleMenu,
          icon: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                label,
                const Icon(
                  Icons.arrow_drop_down,
                  size: _iconSize * _iconButtonFactor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
