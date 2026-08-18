# Rainy

A fork of **[darkmoonight/Rain](https://github.com/darkmoonight/Rain)** (MIT) — an
open-source Open-Meteo weather app for Android and iOS. Upstream's copyright and
licence are retained in [LICENSE](./LICENSE); all upstream work is theirs.

## What this fork adds

A **radar and scalar-overlay layer**, which upstream has no counterpart for:

- RainViewer observed and nowcast radar frames on a time slider
- Temperature, humidity, pressure, precipitation and cloud fields drawn as
  colour rasters over the basemap
- Each field sampled into a cached colour lookup table, with debounced raster
  rebuilds and re-projection of the existing raster onto the live camera
  between rebuilds, so panning stays smooth

Source for that feature lives in `lib/features/map/**`,
`lib/data/datasources/radar_remote_datasource.dart` and
`lib/data/datasources/weather_grid_datasource.dart`.

## Third-party source ported into `lib/`

The temperature, humidity and pressure colour ramps are ported from
**[cambecc/earth](https://github.com/cambecc/earth)** (MIT, © 2014 Cameron
Beccario), with file-level attribution at the port sites. Because Flutter's
licence registry only scans declared package dependencies, ported source is
registered explicitly in `lib/core/bootstrap/ported_source_licenses.dart` so it
appears on the in-app licence screen alongside package licences.

The precipitation and cloud ramps are written from scratch.
