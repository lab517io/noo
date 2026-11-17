import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/safe_filename.dart';

void main() {
  group('safeFilename', () {
    test('keeps an ordinary name as it is', () {
      expect(safeFilename('report 2026.pdf'), 'report 2026.pdf');
      expect(safeFilename('memo 2026-09-25 10-00-00.opus'),
          'memo 2026-09-25 10-00-00.opus');
    });

    test('cannot walk out of the staging directory', () {
      expect(safeFilename('../../databases/noo.db'), 'noo.db');
      expect(safeFilename(r'..\..\noo.db'), 'noo.db');
      expect(safeFilename('/data/data/app/databases/noo.db'), 'noo.db');
      expect(safeFilename(r'C:\Users\x\noo.db'), 'noo.db');
    });

    test('a name that is only a directory reference falls back', () {
      expect(safeFilename('..'), 'file');
      expect(safeFilename('.'), 'file');
      expect(safeFilename('a/..'), 'file');
      expect(safeFilename('   '), 'file');
      expect(safeFilename('', fallback: 'attachment'), 'attachment');
    });

    test('drops the characters no filesystem here accepts', () {
      expect(safeFilename('a:b*c?d"e<f>g|h.txt'), 'a_b_c_d_e_f_g_h.txt');
      expect(safeFilename('line\nbreak.txt'), 'line_break.txt');
      expect(safeFilename('trailing... '), 'trailing');
    });
  });
}
