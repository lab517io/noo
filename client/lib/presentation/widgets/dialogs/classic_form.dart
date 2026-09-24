import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/platform_info.dart';

/// Building blocks for the classic desktop "property sheet" look used by the
/// preferences dialog: fieldset-style group boxes, an aligned label column,
/// compact check boxes, combo boxes and spin boxes.
///
/// They deliberately sit closer to a native options dialog than to Material's
/// list-tile heavy defaults: controls are dense, labels live in their own
/// left-hand column and related settings are framed by a titled border.

/// Label column width and control height at the default 14pt UI font. Both are
/// scaled by [classicLabelWidth] / [classicControlHeight] so the dialog keeps
/// working at the larger UI scales offered in Appearance.
const double _kBaseLabelWidth = 128.0;
const double _kBaseControlHeight = 30.0;
const double _kBaseFontSize = 14.0;

/// Minimum width of a push button ("OK", "Cancel", …) at the default UI font,
/// and the height they keep whatever the caption is.
const double _kBaseButtonWidth = 96.0;
const double _kBaseButtonHeight = 36.0;

/// Effective UI font size at this point in the tree, honouring both the
/// chrome font scale (which rescales the text theme) and the platform's own
/// text scaler.
double _uiFontSize(BuildContext context) {
  // Above the dialog's own DefaultTextStyle (e.g. when sizing the dialog
  // itself) the inherited style carries no size, so fall back to the theme.
  final size = DefaultTextStyle.of(context).style.fontSize ??
      Theme.of(context).textTheme.bodyMedium?.fontSize ??
      _kBaseFontSize;
  return MediaQuery.textScalerOf(context).scale(size);
}

/// Width of the label column shared by every [ClassicField] in a tab, so the
/// controls of different group boxes line up vertically.
double classicLabelWidth(BuildContext context) =>
    _kBaseLabelWidth * (_uiFontSize(context) / _kBaseFontSize);

/// Height of the boxed controls (combo boxes, spin boxes).
double classicControlHeight(BuildContext context) =>
    (_uiFontSize(context) / _kBaseFontSize * _kBaseControlHeight)
        .clamp(_kBaseControlHeight, 64.0);

/// Factor to apply to hand-picked widths (controls, dialog) at the current UI
/// scale, so a larger UI font gets proportionally more room.
double classicUiScale(BuildContext context) =>
    (_uiFontSize(context) / _kBaseFontSize).clamp(1.0, 1.6);

/// Whether this dialog should stack labels above their controls instead of
/// keeping them in the left-hand column.
///
/// The label column costs [classicLabelWidth] on every row whether or not
/// there is room for it. On a phone the dialog is already full-screen and
/// still only ~290dp wide inside its group boxes, so the column would leave a
/// text field barely wider than the label beside it — and a [ClassicField]
/// hint stranded in a gutter. Stacking gives every control the full width.
///
/// Rows also stack on their own when the column would swallow their box
/// regardless of platform; see [ClassicField].
bool classicStackedLayout(BuildContext context) => isCompactLayout(context);

/// Share of a row's width the label column may take before the row is better
/// off stacked. Above this the control is squeezed into less than the label
/// beside it, which is where the classic layout stops reading as a form.
const double _kMaxLabelShare = 0.45;

/// Shared sizing for the dialogs' push buttons.
///
/// Buttons keep a uniform minimum width — the classic dialog look — but grow
/// with a longer caption instead of squeezing it, so labels such as "Test
/// Connection" stay on a single line at every UI scale. The horizontal padding
/// is tighter than Material's default for the same reason.
///
/// Stacked (phone) layouts drop the minimum width and tighten the padding: a
/// row of buttons there competes for a fraction of the width a property sheet
/// has, and a floor of 96dp each is what pushes them off the edge.
ButtonStyle classicButtonStyle(BuildContext context) {
  final scale = classicUiScale(context);
  final stacked = classicStackedLayout(context);
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(
      Size(stacked ? 0 : _kBaseButtonWidth * scale, _kBaseButtonHeight * scale),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: (stacked ? 12 : 16) * scale),
    ),
  );
}

/// Background the group box title is painted on, so it can sit on the border.
Color _dialogBackground(ThemeData theme) =>
    theme.dialogTheme.backgroundColor ?? theme.colorScheme.surfaceContainerHigh;

/// A titled frame around a group of related settings — the Win32 "group box".
class ClassicGroupBox extends StatelessWidget {
  final String title;
  final Widget child;

  const ClassicGroupBox({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 9),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(3),
          ),
          child: child,
        ),
        // Bounded on both sides so a long title ellipsizes instead of
        // spilling past the frame.
        Positioned(
          left: 10,
          right: 10,
          top: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              color: _dialogBackground(theme),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A labelled settings row: fixed-width label column on the left, control on
/// the right, with an optional explanatory [hint] underneath.
///
/// Narrow layouts stack instead — label, then control at full width, then the
/// hint — either because the whole dialog is stacked
/// ([classicStackedLayout]) or because the column would take more than
/// [_kMaxLabelShare] of this particular row, which is what a large UI font
/// does to an otherwise roomy dialog.
class ClassicField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;

  /// Overrides the shared [classicLabelWidth] for this row.
  final double? labelWidth;

  /// When true the control stretches to fill the remaining width, otherwise it
  /// keeps its intrinsic size and hugs the label column.
  final bool expand;

  const ClassicField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.labelWidth,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidth = this.labelWidth ?? classicLabelWidth(context);

    if (classicStackedLayout(context)) return _buildStacked(context);

    // The dialog is wide enough in general, but this row may still not be:
    // measure before committing to the column.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        if (available.isFinite && labelWidth > available * _kMaxLabelShare) {
          return _buildStacked(context);
        }
        return _buildColumns(context, labelWidth);
      },
    );
  }

  /// The classic property-sheet row: label column, then the control.
  Widget _buildColumns(BuildContext context, double labelWidth) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(label.isEmpty ? '' : '$label:'),
              ),
            ),
            if (expand) Expanded(child: child) else Flexible(child: child),
          ],
        ),
        if (hint != null)
          Padding(
            padding: EdgeInsets.only(left: labelWidth, top: 3),
            child: Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
      ],
    );
  }

  /// Label above the control, both at full width. [expand] no longer decides
  /// the width — there is only one column — but it still decides whether the
  /// control fills it or keeps its intrinsic size at the left edge.
  Widget _buildStacked(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('$label:'),
          ),
        if (expand)
          SizedBox(width: double.infinity, child: child)
        else
          Align(alignment: Alignment.centerLeft, child: child),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Indents [child] so it lines up with the control column of the
/// [ClassicField] rows above it — the classic look for a row of buttons that
/// belongs to the fields it follows.
///
/// Drops the indent whenever those rows stack, by exactly the rule
/// [ClassicField] uses, so the two never disagree: there is no column left to
/// line up with, and the inset would only take width the buttons need.
class ClassicFieldIndent extends StatelessWidget {
  final Widget child;

  const ClassicFieldIndent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (classicStackedLayout(context)) return child;
    final labelWidth = classicLabelWidth(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        if (available.isFinite && labelWidth > available * _kMaxLabelShare) {
          return child;
        }
        return Padding(
          padding: EdgeInsets.only(left: labelWidth),
          child: child,
        );
      },
    );
  }
}

/// A compact check box with its caption to the right and an optional hint
/// underneath, aligned with the caption.
class ClassicCheckbox extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ClassicCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    final labelColor = enabled ? null : theme.disabledColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
                ),
              ),
              const SizedBox(width: 8),
              // Flexible, not a bare Text: captions such as "Transcribe after
              // recording" are wider than a phone's group box, and a caption
              // that cannot wrap is a caption that runs off the edge.
              Flexible(
                child: Text(label, style: TextStyle(color: labelColor)),
              ),
            ],
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 1),
            child: Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled ? theme.hintColor : theme.disabledColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// A compact radio button with its caption to the right. Must be placed inside
/// a [RadioGroup].
class ClassicRadio<T> extends StatelessWidget {
  final String label;
  final T value;

  const ClassicRadio({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Radio<T>(
            value: value,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

/// The bordered box shared by the combo and spin boxes.
///
/// [preferredWidth] is what the control asks for, not what it takes: a
/// hand-picked width sized for a desktop property sheet is wider than the row
/// it sits in once the dialog is a phone screen, and a plain `Container` with
/// a fixed width would simply overflow. Clamping keeps the control inside its
/// row and leaves the desktop sizes untouched.
class _ClassicControlBox extends StatelessWidget {
  final double preferredWidth;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BoxBorder border;
  final Widget child;

  const _ClassicControlBox({
    required this.preferredWidth,
    required this.height,
    required this.border,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? math.min(preferredWidth, constraints.maxWidth)
            : preferredWidth;
        return Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: child,
        );
      },
    );
  }
}

/// A boxed combo box, sized like the other classic controls.
class ClassicDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double width;

  const ClassicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ClassicControlBox(
      preferredWidth: width * classicUiScale(context),
      height: classicControlHeight(context),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      border: Border.all(color: theme.dividerColor),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
      ),
    );
  }
}

/// A single-line entry field with the dense border used across the dialog.
class ClassicTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final VoidCallback? onEditingComplete;

  /// Displayed but not editable — the field still selects and copies.
  ///
  /// Distinct from [enabled]: a disabled field greys out to say "not now",
  /// while a value the app generated and the user only ever copies should read
  /// as ordinary text.
  final bool readOnly;

  /// Trailing control inside the border, such as a reveal or copy button.
  final Widget? suffix;

  const ClassicTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.onEditingComplete,
    this.readOnly = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
        suffixIcon: suffix,
        // Without this a dense field carrying two icon buttons grows taller
        // than the spin box beside it and the row stops lining up.
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      ),
    );
  }
}

/// A spin box: a boxed value with stacked up/down arrows on the right.
///
/// Pass a [controller] to make the value typeable (committed via [onCommit]);
/// otherwise [text] is displayed read-only and only the arrows change it.
class ClassicSpinBox extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? text;
  final String? suffix;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onCommit;
  final double width;
  final bool enabled;

  const ClassicSpinBox({
    super.key,
    this.controller,
    this.focusNode,
    this.text,
    this.suffix,
    this.onIncrement,
    this.onDecrement,
    this.onCommit,
    this.width = 96,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = enabled ? theme.dividerColor : theme.disabledColor;
    final height = classicControlHeight(context);

    return _ClassicControlBox(
      preferredWidth: width * classicUiScale(context),
      height: height,
      border: Border.all(color: borderColor),
      child: Row(
        children: [
          Expanded(
            child: controller != null
                ? TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: onCommit,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(8, 0, 4, 0),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        text ?? '',
                        style: TextStyle(
                          color: enabled ? null : theme.disabledColor,
                        ),
                      ),
                    ),
                  ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                suffix!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled ? theme.hintColor : theme.disabledColor,
                ),
              ),
            ),
          Container(width: 1, color: borderColor),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _arrow(theme, Icons.arrow_drop_up, height,
                  enabled ? onIncrement : null),
              _arrow(theme, Icons.arrow_drop_down, height,
                  enabled ? onDecrement : null),
            ],
          ),
        ],
      ),
    );
  }

  /// One half of the stacked spinner arrows, sized to fill half the box.
  Widget _arrow(
    ThemeData theme,
    IconData icon,
    double boxHeight,
    VoidCallback? onTap,
  ) {
    final half = (boxHeight - 2) / 2;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 18,
        height: half,
        child: Icon(
          icon,
          size: half,
          color: onTap == null ? theme.disabledColor : null,
        ),
      ),
    );
  }
}

/// Vertical gap between two rows inside a group box.
const Widget kClassicRowGap = SizedBox(height: 10);

/// Vertical gap between two group boxes.
const Widget kClassicGroupGap = SizedBox(height: 16);
