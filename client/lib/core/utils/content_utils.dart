import 'dart:convert';

/// Extract plaintext from stored content (Delta JSON or HTML).
String extractPlaintext(String? content) {
  if (content == null || content.isEmpty) return '';
  final trimmed = content.trim();

  // Delta JSON: extract "insert" string values
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    try {
      final ops = jsonDecode(trimmed) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString();
    } catch (_) {
      // Fall through to HTML stripping
    }
  }

  // HTML: strip tags
  return trimmed.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Wrap plain text as a minimal Quill Delta document.
///
/// The inverse of [extractPlaintext], and the only way text arriving from
/// outside the editor (today: the MCP server) becomes storable content.
///
/// The trailing newline is not cosmetic: `Document.fromJson` throws on a delta
/// whose last insert does not end in one, so a task written without it would
/// break the editor the next time it is opened rather than merely losing its
/// formatting.
String plaintextToDelta(String text) {
  final body = text.endsWith('\n') ? text : '$text\n';
  return jsonEncode([
    {'insert': body},
  ]);
}

/// Whether [content] is a delta carrying nothing but unformatted text.
///
/// False for formatting attributes and for embeds — inline images are embeds
/// (`noo-attachment://<worldId>`), and [extractPlaintext] drops them, so a
/// read-modify-write round trip through plain text would delete them silently.
/// Callers outside the editor use this to refuse that overwrite.
///
/// Legacy HTML rows are reported as not plain for the same reason: rewriting
/// one as a delta is a format conversion, not an edit.
bool contentIsPlain(String? content) {
  if (content == null || content.trim().isEmpty) return true;

  final trimmed = content.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return false;

  try {
    final ops = jsonDecode(trimmed) as List<dynamic>;
    for (final op in ops) {
      if (op is! Map) return false;
      // An embed inserts a map (image, video, custom block) rather than text.
      if (op['insert'] is! String) return false;
      // Any attributes at all mean bold/link/list/heading — formatting a
      // plain-text rewrite would discard.
      if (op['attributes'] != null) return false;
      // Retain/delete ops only appear in a change delta, never in a stored
      // document; treat their presence as "not something we should rewrite".
      if (op.containsKey('retain') || op.containsKey('delete')) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Extract a snippet around the first match of [query] in [plaintext].
/// Returns empty string if no match found.
String extractSnippet(String plaintext, String query, {int contextChars = 80}) {
  if (plaintext.isEmpty || query.isEmpty) return '';

  final lowerText = plaintext.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matchIndex = lowerText.indexOf(lowerQuery);

  if (matchIndex < 0) return '';

  final start = (matchIndex - contextChars).clamp(0, plaintext.length);
  final end = (matchIndex + query.length + contextChars).clamp(0, plaintext.length);

  var snippet = plaintext.substring(start, end).replaceAll('\n', ' ');
  if (start > 0) snippet = '...$snippet';
  if (end < plaintext.length) snippet = '$snippet...';
  return snippet;
}
