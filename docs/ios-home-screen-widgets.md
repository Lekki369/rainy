# iOS home-screen widgets — requirements

**Status: not implemented.** Home-screen widgets work on Android and do not exist on
iOS. This document records what shipping them would require.

Nothing is broken — this is an unbuilt feature, not a regression. The one thing that
*was* wrong (an invalid App Group identifier) is fixed; see [Already done](#already-done).

## Why Android works and iOS doesn't

The two platforms build widgets in fundamentally different ways, and only the Android
half was ever built.

**Android** — a widget is an `AppWidgetProvider` (a `BroadcastReceiver`) declared in the
app's own manifest. It ships inside the app binary, runs in the app's process, and reads
the same storage the app writes. No extra target, no extra entitlement. This is what
`android/app/src/main/java/com/example/rainy/widget/` and the three `<receiver>` blocks
in `AndroidManifest.xml` are.

**iOS** — a widget is *not part of the app*. It is an App Extension: a separate build
target, compiled into a separate binary, run by iOS as a separate process with its own
sandbox container, written in SwiftUI against WidgetKit. The app cannot draw it and
cannot share memory with it.

Two consequences follow, and they are the whole reason this is a real project rather
than a config change:

1. Someone has to write the widget UI **in Swift**. None of the Kotlin rendering code
   (`WidgetBinders.kt`, `WidgetPalette.kt`, `WidgetIconHelper.kt`) is reusable.
2. The app and the extension need an **App Group** — the entitlement that grants both
   access to one shared container — because the extension cannot otherwise read
   anything the app wrote.

## Current state

| | Android | iOS |
|---|---|---|
| Widget target | in-app receivers | **none** |
| Widget UI code | 9 Kotlin files | **none** |
| Shared storage entitlement | n/a | **none** (no `.entitlements` file exists) |
| App Group id in Dart | n/a | set, see below |
| Data written at runtime | yes | **no** — guarded out |
| Refresh call | `androidName` / `qualifiedAndroidName` | **no iOS parameter passed** |

## Blockers

These gate everything else and are not engineering work:

1. **Paid Apple Developer Program membership.** App Groups are unavailable to free
   personal teams, so the shared container the widget depends on cannot be created.

2. **A real bundle identifier.** App Groups attach to a registered App ID, and the app
   currently ships as `com.example.rainy` — a placeholder for a domain nobody owns.
   A real reverse-DNS id you control is required first.

   ⚠️ **Ordering matters.** Changing `applicationId` after publishing creates a *new*
   store listing rather than updating the existing one. If iOS widgets are wanted, the
   rename should happen before first release, not after. The id is currently
   load-bearing in more places than the manifest — see
   [Bundle id blast radius](#bundle-id-blast-radius).

## Requirements

### Apple Developer portal

- Register the App Group (`group.<bundle-id>`) under Identifiers → App Groups.
- Register a second App ID for the extension, conventionally `<bundle-id>.WidgetExtension`.
- Enable the App Group capability on **both** App IDs.
- Regenerate both provisioning profiles.

### Xcode project

- Add a Widget Extension target. The project currently has exactly one target
  (`com.apple.product-type.application`).
- Add an `.entitlements` file to **each** target declaring
  `com.apple.security.application-groups` with the group id. There is currently no
  `.entitlements` file anywhere under `ios/`.
- Embed the extension in the Runner target; set its signing and deployment target.
- Give the extension its own asset catalog (see [The icon problem](#the-icon-problem)).

### Swift / SwiftUI — the bulk of the work

- A `TimelineProvider` reading `UserDefaults(suiteName: "group.<bundle-id>")`.
- Swift `Codable` models mirroring the `widget_bundle` JSON contract below.
- SwiftUI views for all three registered widget types:
  `material_you_forecast_1x1`, `material_you_current`, `clock` — reimplementing the
  layout, palette, and weather-icon mapping currently done in Kotlin.
- `supportedFamilies` mapped onto the existing Android shapes
  (`systemSmall` for 1×1, `systemMedium` for the horizontal clock).
- A refresh policy. iOS does not let a widget update on demand; WidgetKit decides,
  and budgets are tight.

### Dart wiring

Small, but currently absent entirely:

- Pass `iOSName:` to `HomeWidget.updateWidget()` in
  `lib/core/services/home_widget_service.dart`. Today it passes only `androidName` and
  `qualifiedAndroidName`, so the refresh call is Android-only.
- Remove the `Platform.isAndroid` guard around `HomeWidgetService.updateFromDisk` in
  `lib/core/bootstrap/app_initializer.dart`. **As written, iOS never writes widget data
  at all** — an extension would find an empty container.
- Decide iOS background refresh. Android uses Workmanager; iOS gets WidgetKit timeline
  policy plus `BGTaskScheduler`, which is far more restrictive.

## Data contract

The Dart side already writes everything a widget needs, via `home_widget`. An iOS
extension consumes these keys from the shared `UserDefaults` suite.

`widget_bundle` — JSON string, built by `HomeWidgetService._buildWidgetBundle`:

```json
{
  "current": {
    "location": "Lagos",
    "temperature": "21°",
    "icon": "/local/path/to/icon.png"
  }
}
```

Written as `null` when the weather cache is empty or incomplete — the widget must
render an unconfigured state.

Flat keys, all strings:

| Key | Source |
|---|---|
| `timeformat` | `Settings.timeformat` |
| `widget_theme_mode` | `Settings.theme` |
| `background_color_light` | `Settings.widgetBackgroundColorLight` |
| `background_color_dark` | `Settings.widgetBackgroundColorDark` |
| `text_color_light` | `Settings.widgetTextColorLight` |
| `text_color_dark` | `Settings.widgetTextColorDark` |
| `last_background_refresh_at` | `background_refresh_log.dart` |
| `last_background_refresh_error` | `background_refresh_log.dart` |

Colour keys are written as `null` when unset, and `#00000000` means "transparent —
hide the shape layer" (`AppConstants.transparentWidgetColorHex`).

## The icon problem

`widget_bundle.current.icon` is a **filesystem path**, produced by
`AssetCacheService.getLocalImagePath`, pointing into the app's own container.

On Android this is fine — the widget runs in the app's process. **On iOS it will not
work.** The extension is a separate sandbox and cannot read an arbitrary path inside the
app's container. Either:

- `AssetCacheService` must write cached icons into the **App Group container** so both
  processes can reach them, or
- the icons must be bundled into the extension's own asset catalog and the payload must
  carry a symbolic name instead of a path.

This is an easy detail to miss until the widget renders blank, so decide it early.

## Bundle id blast radius

If the bundle id is renamed as part of this work, `com.example.rainy` is currently
load-bearing in all of these:

```
android/app/build.gradle                          namespace + applicationId
android/app/src/main/kotlin/**/*.kt               package declarations (+ dir move)
android/app/src/main/java/**/widget/*.kt          package declarations (+ dir move)
lib/core/config/widget_registry.dart              provider class-name strings
lib/core/services/background_platform_service.dart  MethodChannel name
android/app/src/main/kotlin/**/MainActivity.kt    MethodChannel name (other side)
ios/Runner.xcodeproj/project.pbxproj              PRODUCT_BUNDLE_IDENTIFIER ×9
macos/Runner/Configs/AppInfo.xcconfig             PRODUCT_BUNDLE_IDENTIFIER
linux/CMakeLists.txt                              APPLICATION_ID
lib/core/config/app_config.dart                   appGroupId prefix
lib/core/constants/app_constants.dart             mapUserAgentPackageName
test/helpers/fake_package_info.dart               test fixture
test/core/config/widget_registry_test.dart        test expectations
```

The Dart-side provider class-name strings and the `MethodChannel` names are matched
pairs — changing one side without the other fails silently at runtime rather than at
compile time.

## Already done

- `appGroupId` in `lib/core/config/app_config.dart` was the literal string
  `'DARK NIGHT'`, which can never be a valid App Group identifier — Apple requires a
  `group.`-prefixed reverse-DNS form. It is now `group.com.example.rainy` and must be
  updated alongside any bundle-id rename.

Note that this fix alone changes nothing observable: `HomeWidget.setAppGroupId()` still
runs on iOS and still accomplishes nothing, because there is no entitlement backing the
group and no extension reading from it.

## Rough shape of the work

| Phase | Effort |
|---|---|
| Apple account + bundle id rename | blocked on account; rename is mechanical but wide |
| Portal + Xcode target + entitlements | hours |
| SwiftUI widgets ×3 + icon plumbing | the real cost — days |
| Dart wiring + background refresh | hours |
