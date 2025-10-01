import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Cached device capabilities used for theme and layout decisions.
class DeviceFeature {
  DeviceFeature._internal();

  static final DeviceFeature _singleton = DeviceFeature._internal();
  factory DeviceFeature() => _singleton;

  final _deviceInfoPlugin = DeviceInfoPlugin();
  AndroidDeviceInfo? _androidDeviceInfo;
  IosDeviceInfo? _iosDeviceInfo;
  bool? _isEdgeToEdgeAvailableCache;

  /// Loads device info and edge-to-edge support once at startup.
  Future<void> init() async {
    try {
      if (Platform.isAndroid) {
        _androidDeviceInfo = await _deviceInfoPlugin.androidInfo;
        _isEdgeToEdgeAvailableCache =
            _androidDeviceInfo != null &&
            _androidDeviceInfo!.version.sdkInt > 28;
      } else if (Platform.isIOS) {
        _iosDeviceInfo = await _deviceInfoPlugin.iosInfo;
        // iOS always supports edge-to-edge via safe area
        _isEdgeToEdgeAvailableCache = true;
      } else {
        _isEdgeToEdgeAvailableCache = false;
      }
    } catch (e) {
      debugPrint('Error initializing device info: $e');
      _isEdgeToEdgeAvailableCache = false;
    }
  }

  /// Whether transparent navigation bars are supported on this device.
  bool isEdgeToEdgeAvailable() => _isEdgeToEdgeAvailableCache ?? false;

  /// Android SDK version, or null when device info is unavailable.
  int? get sdkVersion => _androidDeviceInfo?.version.sdkInt;

  /// Device model name, or null when device info is unavailable.
  String? get model => _androidDeviceInfo?.model ?? _iosDeviceInfo?.model;

  /// Device brand name, or null when device info is unavailable.
  String? get brand =>
      _androidDeviceInfo?.brand ?? (_iosDeviceInfo != null ? 'Apple' : null);
}
