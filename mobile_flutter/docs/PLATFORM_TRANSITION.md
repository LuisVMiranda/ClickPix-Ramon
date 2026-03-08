# Platform Transition Plan (Android + iOS)

## Current structure
- Android project folder: `mobile_flutter/android`
- iOS project folder: `mobile_flutter/ios`
- Flutter app root to open/run in Android Studio: `mobile_flutter`

## How to run (Windows + Android Studio)
- Open only `mobile_flutter` as the project root.
- Select run configuration `main.dart` (not `Flutter Test.*`).
- Choose device `Medium Phone API 36.1`.
- Run with the green Run button (`Shift+F10`), not "Run with Coverage".

## Legacy compatibility targets
- Android:
  - Keep `minSdk` inherited from Flutter baseline for broad device support.
  - Prefer lightweight UI trees and avoid heavy background processing on the main thread.
- iOS:
  - Keep default Flutter iOS baseline and avoid APIs that require only newest iOS versions unless guarded.

## Performance and footprint guidelines
- Load media lazily and process photos in batches.
- Keep history and local caches capped in size.
- Reuse existing local database tables and avoid duplicate copies of image metadata.
- Prefer async operations for ingestion, delivery queue, and statistics aggregation.

## Operational notes
- Core features are implemented in Flutter (`lib/`) and reused by both platforms.
- Platform-specific build and packaging remain isolated under `android/` and `ios/`.
