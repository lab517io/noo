import 'dart:convert';

/// Images embedded in task content are *not* stored inside the content itself.
/// The bytes live in the `file` table (the same table the attachments panel
/// shows), and the Delta only carries a reference:
///
/// ```json
/// {"insert": {"image": "noo-attachment://<attachment worldId>"}}
/// ```
///
/// That keeps `tasks.content` small — it is diffed into history on every edit
/// (see `DiffUtils.computeDiff`), searched with LIKE, and pushed in full on
/// every sync packet — while the bytes travel through the attachment sync path
/// that already exists (`SyncChangePackager` base64-encodes file content once,
/// and only when it changes).
///
/// The reference is the attachment's **worldId**, not its row id: row ids are
/// autoincrement and device-local, worldIds are the identity the sync layer
/// keys on.
const String kAttachmentUriScheme = 'noo-attachment';

const String _prefix = '$kAttachmentUriScheme://';

/// Build the content reference for the attachment identified by [worldId].
String attachmentUri(String worldId) => '$_prefix$worldId';

/// The attachment worldId [url] points at, or null when [url] is some other
/// kind of image source (http(s), a data: URI, a filesystem path).
///
/// Deliberately not `Uri.parse`: that lowercases the authority, and while
/// worldIds are lowercase UUIDs today nothing enforces it.
String? attachmentWorldIdOf(String? url) {
  if (url == null || !url.startsWith(_prefix)) return null;
  final worldId = url.substring(_prefix.length);
  return worldId.isEmpty ? null : worldId;
}

/// Every image source referenced by [content] (Delta JSON), in document order.
///
/// Returns an empty list for HTML/legacy content — those never carry
/// attachment references.
List<String> imageSourcesInContent(String? content) {
  if (content == null || content.isEmpty) return const [];
  final trimmed = content.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return const [];

  try {
    final ops = jsonDecode(trimmed) as List<dynamic>;
    final sources = <String>[];
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is! Map) continue;
      final image = insert['image'];
      if (image is String && image.isNotEmpty) sources.add(image);
    }
    return sources;
  } catch (_) {
    return const [];
  }
}

/// worldIds of the attachment-backed images referenced by [content].
Set<String> attachmentRefsInContent(String? content) {
  return imageSourcesInContent(content)
      .map(attachmentWorldIdOf)
      .whereType<String>()
      .toSet();
}
