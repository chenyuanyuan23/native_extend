import 'package:flutter_test/flutter_test.dart';
import 'package:native_extend/native_extend.dart';

void main() {
  group('ScreenEdge', () {
    test('枚举值', () {
      expect(ScreenEdge.values, contains(ScreenEdge.top));
      expect(ScreenEdge.values, contains(ScreenEdge.left));
      expect(ScreenEdge.values, contains(ScreenEdge.bottom));
      expect(ScreenEdge.values, contains(ScreenEdge.right));
      expect(ScreenEdge.values.length, 4);
    });
    test('index 用于 mask 计算', () {
      var mask = 0;
      for (final e in ScreenEdge.values) {
        mask |= 1 << e.index;
      }
      expect(mask, 15);
    });
  });
}
