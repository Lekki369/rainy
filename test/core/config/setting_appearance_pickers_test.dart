import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/config/setting_appearance_pickers.dart';

void main() {
  test(
    'settingAppearanceCatalogPickers includes palette, font, and icon theme',
    () {
      expect(settingAppearanceCatalogPickers, hasLength(3));
      expect(settingAppearanceCatalogPickers.map((def) => def.titleKey), [
        'colorPalette',
        'appFont',
        'weatherIconTheme',
      ]);

      final iconTheme = settingAppearanceCatalogPickers.last;
      expect(iconTheme.refreshWidgets, isTrue);
      expect(iconTheme.syncNotificationContent, isTrue);
    },
  );
}
