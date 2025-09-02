/// Barrel export for core Riverpod providers and notifiers.
///
/// Import this from screens and notifiers. Leaf widgets that only need a single
/// provider should import [provider_refs.dart] directly to avoid pulling in
/// notifier exports.
library;

export 'package:rainy/core/di/provider_refs.dart';
export 'package:rainy/core/services/widget_settings_service.dart'
    show WidgetSettingsService;
export 'package:rainy/core/settings/app_settings_notifier.dart';
export 'package:rainy/core/theme/theme_mode_notifier.dart';
export 'package:rainy/features/cities/application/cities_notifier.dart';
export 'package:rainy/features/weather/application/main_weather_notifier.dart';
