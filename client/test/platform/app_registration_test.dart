import 'package:flutter_test/flutter_test.dart';
import 'package:noo/platform/app_registration.dart';

/// The `Exec=` line of the .desktop entry written on Linux. An AppImage sits
/// wherever the user dropped it, and a launcher parses the line shell-style,
/// so a path with a space in it has to be quoted or the entry cannot start
/// the app.
void main() {
  group('linuxDesktopExec', () {
    test('leaves a plain path unquoted', () {
      expect(
        linuxDesktopExec('/opt/noo/Noo-x86_64.AppImage'),
        '/opt/noo/Noo-x86_64.AppImage %f',
      );
    });

    test('quotes a path holding a space', () {
      expect(
        linuxDesktopExec('/home/me/My Apps/Noo.AppImage'),
        '"/home/me/My Apps/Noo.AppImage" %f',
      );
    });

    test('escapes the characters the specification reserves inside quotes',
        () {
      // Inside quotes: `"`, `` ` ``, `$` and `\` take a backslash, and the
      // backslash is doubled again because the value is unescaped as a
      // string before the quoting is read.
      expect(
        linuxDesktopExec(r'/x/a"b$c`d\e'),
        r'"/x/a\\"b\\$c\\`d\\\\e" %f',
      );
    });

    test('doubles a percent sign, quoted or not', () {
      expect(linuxDesktopExec('/x/100%/noo'), '/x/100%%/noo %f');
      expect(linuxDesktopExec('/x/100% done/noo'), '"/x/100%% done/noo" %f');
    });

    test('quotes on every other reserved character', () {
      for (final c in ['\'', '>', '<', '~', '|', '&', ';', '*', '?', '#', '(', ')']) {
        final exec = linuxDesktopExec('/x/a${c}b');
        expect(exec, '"/x/a${c}b" %f', reason: 'character $c');
      }
    });
  });
}
