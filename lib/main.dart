import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rainy/app.dart';
import 'package:rainy/core/bootstrap/app_initializer.dart';
import 'package:rainy/core/di/provider_refs.dart';

/// Entry point: bootstraps dependencies and runs [RainApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppInitializer.initialize();
  runApp(
    ProviderScope(
      overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      child: RainApp(bootstrap: bootstrap),
    ),
  );
}
