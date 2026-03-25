import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/utils/string_utils.dart';

void main() {
  group('capitalizeFirst', () {
    test('uppercases first letter', () {
      expect(capitalizeFirst('воскресенье'), 'Воскресенье');
      expect(capitalizeFirst('monday'), 'Monday');
      expect(capitalizeFirst('Monday'), 'Monday');
    });

    test('returns empty string unchanged', () {
      expect(capitalizeFirst(''), '');
    });
  });
}
