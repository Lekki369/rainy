import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/di/provider_refs.dart';
import 'package:rainy/core/navigation/app_router.dart';
import 'package:rainy/core/navigation/app_routes.dart';
import 'package:rainy/data/models/db.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_bootstrap.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(initTestEnvironment);

  group('appRouterProvider refresh', () {
    test(
      'syncBootstrapLocationCache clears geolocation redirect target',
      () async {
        final ctx = await createTestBootstrap(
          settings: onboardedSettings(),
          locationCache: LocationCache(),
        );
        final container = createTestContainer(bootstrap: ctx.bootstrap);
        addTearDown(container.dispose);

        expect(
          resolveAppRedirect(
            ctx.bootstrap.settings,
            container.read(locationCacheProvider),
            AppRoutes.home,
          ),
          AppRoutes.geolocationStart,
        );

        container.read(
          Provider<void>((ref) {
            syncBootstrapLocationCache(ref, sampleLocationCache());
          }),
        );

        expect(
          resolveAppRedirect(
            ctx.bootstrap.settings,
            container.read(locationCacheProvider),
            AppRoutes.home,
          ),
          isNull,
        );
      },
    );
  });
}
