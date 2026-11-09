import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/release_notes.dart';

/// What `publish_release.py` writes, before the marker existed.
const _generated = '''
Outliner, time tracking, encrypted database.

## Downloads

| File | Platform | Notes |
|---|---|---|
| `noo-1.2.18-x86_64.AppImage` | Linux x86-64 | `chmod +x` and run |
| `noo-1.2.18-android.apk` | Android 9+ (API 28) | Sideload it |

## Verifying a download

```bash
sha256sum -c SHA256SUMS
```

The APK is signed with the project's release key:

```
SHA-256 0E:B4:2D
```

Check it with `apksigner verify --print-certs noo-1.2.18-android.apk`.
''';

void main() {
  test('everything after the files marker is dropped', () {
    const body =
        'Fixes a crash on **start**.\n\n'
        '$kReleaseNotesFilesMarker\n\n'
        '## Downloads\n\nAnything at all.\n';
    expect(dialogReleaseNotes(body), 'Fixes a crash on **start**.');
  });

  test('tables, fences and the headings left empty by them go', () {
    expect(
      dialogReleaseNotes(_generated),
      'Outliner, time tracking, encrypted database.\n'
      '\n'
      '## Verifying a download\n'
      '\n'
      "The APK is signed with the project's release key:\n"
      '\n'
      'Check it with `apksigner verify --print-certs noo-1.2.18-android.apk`.',
    );
  });

  test('a heading over a non-empty subsection stays', () {
    const body =
        '## Changes\n\n### Editor\n\n- Faster paste\n\n### Sync\n\n'
        '| a | b |\n|---|---|\n';
    expect(
      dialogReleaseNotes(body),
      '## Changes\n\n### Editor\n\n- Faster paste',
    );
  });

  test('an unterminated fence runs to the end', () {
    expect(dialogReleaseNotes('Hello\n\n```\nnever closed\n'), 'Hello');
  });

  test('CRLF and blank runs are normalised', () {
    expect(dialogReleaseNotes('A\r\n\r\n\r\n\r\nB\r\n'), 'A\n\nB');
  });

  test('empty in, empty out', () {
    expect(dialogReleaseNotes(''), '');
    expect(dialogReleaseNotes('## Only a heading\n'), '');
  });
}
