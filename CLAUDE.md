# Fud AI — Claude Code Project Notes

Open-source iOS calorie tracker built with SwiftUI. This file is loaded automatically by Claude Code; keep it concise and current.

## Stack

- Swift 5, SwiftUI, iOS 17.6+ deployment target
- Single target `calorietracker` (no SwiftPM/CocoaPods — zero dependencies)
- `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers new files; do **not** edit `project.pbxproj` to add files
- Build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`

## Architecture

- State stores use `@Observable` macro (not `ObservableObject`) and are injected via `.environment()` (not `environmentObject`)
- `FoodStore`, `WeightStore`, `NotificationManager`, `HealthKitManager` are environment-scoped singletons created in `calorietrackerApp.swift`
- `GeminiService` is a pure struct with static methods that routes to the active provider (Gemini, OpenAI-compatible, or Anthropic Messages format)
- API keys live in iOS Keychain via `KeychainHelper` / `AIProviderSettings`; settings in `UserDefaults`
- Camera uses `UIImagePickerController` wrapped in `UIViewControllerRepresentable`
- HealthKit writes 12 nutrition types per meal tagged with `fudai_entry_id` UUID metadata, plus body measurements (weight/height/body fat)
- App is fully free — no subscriptions, no sign-in, no iCloud, all data local

## Build, Install, Launch (Apoorv's iPhone)

```bash
# Build
xcodebuild -scheme calorietracker -destination 'id=E2095CDC-E117-527C-818A-9F741A145103' build

# Install
xcrun devicectl device install app --device E2095CDC-E117-527C-818A-9F741A145103 \
  ~/Library/Developer/Xcode/DerivedData/calorietracker-gyjqfuacfxocddfrskbcdsbwqhxa/Build/Products/Release-iphoneos/calorietracker.app

# Launch
xcrun devicectl device process launch --device E2095CDC-E117-527C-818A-9F741A145103 com.apoorvdarshan.calorietracker
```

Device: Apoorv's iPhone (iPhone 16, ID `E2095CDC-E117-527C-818A-9F741A145103`).

## Workflow

After every change: build → install on iPhone → launch → git commit → git push. **No co-author line in commits.** Use simple, direct commit messages — no marketing fluff.

For code review, use the Codex CLI:
```bash
codex exec review --commit <SHA> --full-auto
```
Address P1/P2 findings; P3 is judgment-call.

## Gotchas

- **SourceKit shows false errors** for UIKit imports and cross-file references when editing on macOS. Ignore them; verify with an actual `xcodebuild`.
- `ProgressView` is renamed to `ProgressTabView` to avoid clash with SwiftUI's built-in `ProgressView`.
- **Multiple `.sheet()` modifiers** on the same view cause white/black screens — use a single `.sheet(item:)` driven by an enum instead.
- **`.buttonStyle(.plain)` kills row tap-highlight** in a `List`. Use `.tint(.primary)` if you want the highlight back while keeping primary text color.
- **Dead files** present but not referenced: `AuthManager.swift`, `StoreManager.swift`, `PaywallView.swift`, `SpinWheelView.swift`, `CloudKitService.swift`. Don't add new code to them.
- **CodeQL workflow** uses `maxim-lobanov/setup-xcode@v1` with `latest-stable` because the GitHub macOS runner's default Xcode is too old for our Swift Charts usage.

## HealthKit Conventions

- `authVersion` (in `HealthKitManager`) bumps when new HealthKit types are added so existing users get re-prompted.
- `requestAuthorization` only persists the new `authVersion` if **all** dietary share types are `.sharingAuthorized` — otherwise users who deny nutrition can never re-prompt.
- `writeNutrition`, `deleteNutrition`, and `updateNutrition` all guard on `healthKitEnabled`. `purgeNutrition` bypasses the guard for the destructive Delete-All-Data path.
- `backfillNutritionIfNeeded` is idempotent: it queries Apple Health for each entry's UUID before writing, so it's safe to call on every launch.
- Edits use `onEntryUpdated` (not `onEntryDeleted` + `onEntryAdded` back-to-back) so HealthKit can serialize delete-then-write atomically.

## URLs / Identity

- Website: https://fud-ai.app
- App Store: https://apps.apple.com/us/app/fud-ai-calorie-tracker/id6758935726
- Email: apoorv@fud-ai.app
- X: @apoorvdarshan
- Donations: https://paypal.me/apoorvdarshan
