import 'package:many_lints/src/text_distance.dart';
import 'package:test/test.dart';

void main() {
  group('computeEditDistance', () {
    test('identical strings return 0', () {
      expect(computeEditDistance('hello', 'hello'), 0);
    });

    test('empty strings return 0', () {
      expect(computeEditDistance('', ''), 0);
    });

    test('one empty string returns other length', () {
      expect(computeEditDistance('', 'abc'), 3);
      expect(computeEditDistance('abc', ''), 3);
    });

    test('single character difference', () {
      expect(computeEditDistance('cat', 'bat'), 1);
    });

    test('insertion', () {
      expect(computeEditDistance('abc', 'abcd'), 1);
    });

    test('deletion', () {
      expect(computeEditDistance('abcd', 'abc'), 1);
    });

    test('classic kitten-sitting example', () {
      expect(computeEditDistance('kitten', 'sitting'), 3);
    });

    test('completely different strings', () {
      expect(computeEditDistance('abc', 'xyz'), 3);
    });

    test('case sensitive', () {
      expect(computeEditDistance('Hello', 'hello'), 1);
    });
  });
}
