# BibleAPI Songs (Android)

Flutter APK for **Songs CRUD** against your TiDB Cloud database (same `SongDetails` / `SongLyrics` tables as BibleAPI).

## Download site

Static download page (GitHub Pages):

**https://slcc-bench.github.io/BibleAPI-Songs/**

The button always downloads the latest GitHub Release APK.

## Install

1. Open the download site (or grab `build/app/outputs/flutter-apk/app-release.apk`).
2. Allow install from unknown sources if prompted.
3. Open **BibleAPI Songs**, enter TiDB host / port / user / password / database, then **Save & continue**.

Credentials are stored with `flutter_secure_storage` on the device. The device needs outbound access to TiDB (typically port **4000**).

## Rebuild

```bash
export PATH="$HOME/development/flutter/bin:/opt/homebrew/opt/openjdk@17/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"

cd /Users/Bench/Desktop/Projects/BibleAPI-Songs
flutter build apk --release
```

## Verify TiDB CRUD (dev machine)

```bash
flutter test test/tidb_crud_test.dart
```

Uses `~/Library/Application Support/praisehub/bibleapi.env.json` by default (or set `TIDB_ENV_JSON`).
