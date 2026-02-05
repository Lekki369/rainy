import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/bootstrap/app_bootstrap.dart';

import '../../helpers/test_bootstrap.dart';

void main() {
  group('AppBootstrap', () {
    late TestBootstrapContext ctx;

    setUp(() async {
      ctx = await createTestBootstrap();
    });

    test('exposes isar, settings, and location cache', () {
      final bootstrap = ctx.bootstrap;

      expect(bootstrap, isA<AppBootstrap>());
      expect(bootstrap.isar.isOpen, isTrue);
      expect(bootstrap.settings.onboard, isTrue);
      expect(bootstrap.locationCache.city, 'Moscow');
    });
  });
}
