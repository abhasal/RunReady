# RunReady — Setup Instructions

## Requirements

- macOS 14+ (Sonoma) with Xcode 15.2+
- iOS 17.0+ deployment target
- Apple Developer account (free works for personal device; paid for App Store)

---

## Option A: Generate with XcodeGen (recommended)

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Clone / open the project folder:
   ```bash
   cd /path/to/RunReady
   ```

3. Edit `project.yml`:
   - Replace `com.yourname` with your reversed-domain prefix (e.g. `com.johndoe`)
   - Insert your Apple Team ID (10-char string from developer.apple.com/account)

4. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

5. Open the generated project:
   ```bash
   open RunReady.xcodeproj
   ```

---

## Option B: Manual Xcode project

1. Open Xcode → **File → New → Project → iOS App**
2. Product name: `RunReady`, Interface: SwiftUI, Storage: SwiftData
3. Drag all source folders (`App`, `Models`, `Services`, `ViewModels`, `Views`, `Preview Content`) into the Xcode project navigator
4. Add the `RunReadyTests` folder as a Unit Test target
5. Continue with the Capabilities section below

---

## Required Capabilities (Signing & Capabilities tab)

In your Xcode target, add these capabilities:

| Capability | Why |
|------------|-----|
| **HealthKit** | Read workouts, heart rate, and route data from Apple Health |
| **Background Modes → Audio, AirPlay** | Keep music playing when app is backgrounded during a run |
| **Background Modes → Location updates** | Continue GPS tracking when screen is off |

> HealthKit also requires adding the entitlement. XcodeGen adds it via `RunReady.entitlements`. For manual setup, Xcode adds it automatically when you toggle the capability.

---

## Info.plist Keys (already provided)

The `Info.plist` in this repo includes all required usage descriptions:
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSMotionUsageDescription`
- `UIBackgroundModes: [audio, location]`

If you created a fresh Xcode project, **replace** its generated `Info.plist` with the one from this repo.

---

## Adding Audio Tracks

The music player is wired but the sample `.mp3` files are not included. To add tracks:

1. Obtain royalty-free `.mp3` or `.m4a` files
2. Add them to the Xcode project under the main target (check **Target Membership**)
3. Name them exactly: `pace_setter.mp3`, `steady_stride.mp3`, `final_push.mp3`
   — or update the filenames in `AudioModels.swift` under `Playlist.builtIn`

The app will show the music UI and controls regardless; playback will only be silent if no audio files are present.

---

## Running on Simulator vs. Device

| Feature | Simulator | Device |
|---------|-----------|--------|
| SwiftData / local storage | ✅ | ✅ |
| Manual run entry | ✅ | ✅ |
| HealthKit (requires real data) | Limited | ✅ |
| GPS route tracking | ❌ | ✅ |
| Background audio | ✅ | ✅ |
| Background location | ❌ | ✅ |

---

## Running Tests

In Xcode: **⌘U** or Product → Test

Tests are in `RunReadyTests/`:
- `UnitConversionTests.swift` — distance/pace/duration formatting
- `PredictionEngineTests.swift` — five scenario-based readiness tests + spike/determinism tests

All tests use in-memory data and a fixed `now` date; no network or HealthKit access required.

---

## Before App Store Submission

- [ ] Replace privacy policy URL placeholder in `SettingsView.swift`
- [ ] Add real audio tracks (see above)
- [ ] Set `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` or Xcode
- [ ] Review HealthKit entitlement for App Store approval (Apple reviews HealthKit apps more carefully)
- [ ] Add an App Store icon in `Assets.xcassets/AppIcon`
- [ ] Enable push notifications and schedule `UNUserNotificationCenter` if using run reminders

---

## Architecture Notes

```
App/           — entry point, root view, global app state
Models/        — SwiftData models + value types (no business logic)
Services/      — HealthKitManager, RunStore, PredictionEngine, UnitConversionService, AudioPlaybackManager
ViewModels/    — @Observable classes, one per major screen
Views/         — SwiftUI views, one folder per feature
Preview Content/ — in-memory test data, never shipped in release builds
RunReadyTests/ — XCTest unit tests
```

All state flows downward via `@Environment`. There are no singletons injected via ViewModels directly — the `AppState` object is the single point of injection.
