import 'package:diff_match_patch/diff_match_patch.dart';
// ignore: implementation_imports
import 'package:diff_match_patch/src/patch.dart' as patch_lib;

/// Utility class for computing and applying text diffs
class DiffUtils {
  DiffUtils._();

  static final _dmp = DiffMatchPatch();

  /// Fields that should use diff-based storage
  static const _diffFields = {'title', 'content'};

  /// Check if a field should use diff (text fields) or full value
  static bool shouldUseDiff(String fieldName) {
    return _diffFields.contains(fieldName);
  }

  /// Whether a stored history value is a dmp patch rather than a full value.
  /// The textual patch format always opens with a hunk header; legacy rows
  /// (and creation rows) store the full text instead.
  static bool isPatch(String value) => value.startsWith('@@ -');

  /// Compute a diff between two text strings.
  /// Returns a patch string that can be applied to oldText to get newText.
  /// Returns null if texts are identical.
  static String? computeDiff(String? oldText, String? newText) {
    final old = oldText ?? '';
    final current = newText ?? '';

    if (old == current) {
      return null; // No change
    }

    // Create patches from the two texts
    final patches = _dmp.patch(old, current);

    // Convert patches to string
    return patch_lib.patchToText(patches);
  }

  /// Apply a diff patch to oldText to produce newText.
  ///
  /// Returns null when the patch does not apply cleanly — a hunk whose context
  /// is not found in [oldText], which happens when the chain being replayed is
  /// missing a row. dmp then returns the text with that hunk skipped, and
  /// passing that on as the value would show a mix of two versions as though
  /// it had been stored. A malformed patch string is reported the same way.
  static String? applyDiff(String oldText, String patch) {
    if (patch.isEmpty) {
      return oldText;
    }

    final List<patch_lib.Patch> patches;
    try {
      patches = patch_lib.patchFromText(patch);
    } on ArgumentError {
      return null;
    }
    final result = _dmp.patch_apply(patches, oldText);

    // result[0] is the patched text, result[1] is one success flag per hunk.
    final applied = (result[1] as List).cast<bool>();
    if (applied.any((ok) => !ok)) return null;
    return result[0] as String;
  }
}
