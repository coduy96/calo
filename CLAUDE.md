# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Fud AI is an open-source calorie tracker. iOS client (SwiftUI, iOS 17.6+) in `ios/` — App Store v3.2. Android client (Kotlin + Jetpack Compose, min SDK 26) in `android/` — feature-parity port, v1.0.4 in Play Store closed testing. Marketing site (plain HTML/CSS, Vercel at https://fud-ai.app) in `web/`. Both clients: snap/speak/type a meal → AI provider returns nutrition JSON → user reviews → lands in food store + Apple Health (iOS) or Health Connect (Android). "Coach" tab is multi-turn AI chat that sees the user's full profile + weight history + food log. Bring-your-own-key, all data local, no subscriptions, no sign-in, no cloud sync.

## Repo Layout

```
fud-ai/
├── ios/          ← iOS app (SwiftUI, Xcode project)
├── android/      ← Android app (Kotlin + Jetpack Compose)
├── web/          ← Marketing site
├── APPSTORE.md   ← App Store Connect listing copy (iOS)
└── …root-level meta (README, LICENSE, CONTRIBUTING, SECURITY, .github/)
```

## Build, Install, Launch (iOS)

Tested on Apoorv's physical iPhone 16 (`E2095CDC-E117-527C-818A-9F741A145103`). Run all three after every change. Release config is intentional. `-derivedDataPath ios/build` keeps the install path stable.

```bash
xcodebuild -project ios/calorietracker.xcodeproj -scheme calorietracker \
  -destination 'id=E2095CDC-E117-527C-818A-9F741A145103' \
  -derivedDataPath ios/build build

xcrun devicectl device install app --device E2095CDC-E117-527C-818A-9F741A145103 \
  ios/build/Build/Products/Release-iphoneos/calorietracker.app

xcrun devicectl device process launch --device E2095CDC-E117-527C-818A-9F741A145103 com.apoorvdarshan.calorietracker

# Onboarding reset:
xcrun devicectl device process launch --device E2095CDC-E117-527C-818A-9F741A145103 com.apoorvdarshan.calorietracker -- --reset-onboarding
```

## Tests

`calorietrackerTests` / `calorietrackerUITests` (iOS) and `androidTest/` / `test/` (Android) are Xcode/Android Studio boilerplate only — no real tests. Verify by hand on device. iOS: `xcodebuild test -project ios/calorietracker.xcodeproj -scheme calorietracker -destination 'id=E2095CDC-E117-527C-818A-9F741A145103'`.

## Code Review

Codex CLI before each PR / after each commit cluster: `codex exec review --commit <SHA> --full-auto`. Address P1/P2; P3 is judgment-call.

## Architecture (iOS)

### State / DI

All stores use `@Observable` (not `ObservableObject`), injected via `.environment(...)`. Created once in `calorietrackerApp.swift`:

- `FoodStore` — entries, favorites, macro aggregates
- `WeightStore` — weight entries; `addEntry` auto-syncs `profile.weightKg` to latest
- `BodyFatStore` — body-fat readings (Codable, UserDefaults key `bodyFatEntries`); `addEntry` auto-syncs `profile.bodyFatPercentage` via `syncProfileBodyFatToLatest()` so Katch-McArdle BMR + Settings Body Fat row never drift apart. HK-paired (writes tagged `fudai_bodyfat_id`, deletes by metadata predicate). Optional opt-in — only seeded when onboarding user picks "Yes I know my body fat %"
- `ProfileStore` — **source of truth for `UserProfile`**. Listens for `.userProfileDidChange` so external writers (WeightStore, HK observer) propagate
- `ChatStore` — Coach history (UserDefaults JSON, last 20 in LLM payload)
- `NotificationManager`, `HealthKitManager`

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` means most types are main-actor isolated by default. New files auto-discovered via `PBXFileSystemSynchronizedRootGroup` — **do not** edit `project.pbxproj` to register source files. (`knownRegions` *is* edited when adding a localization.)

### AI / LLM Routing (13 providers, 3 formats)

Two services dispatch on `AIProvider.apiFormat`:

- **`GeminiService`** — single-shot food/label analysis (`analyzeFood`, `analyzeTextInput`, `autoAnalyze`, `analyzeNutritionLabel` → `callAI`)
- **`ChatService`** — multi-turn Coach chat with **tool calling** (see Coach section)

API dialects (also used by Android — same shapes):
- **Gemini** (`.gemini`): `POST /models/{model}:generateContent` with `systemInstruction` + `contents[{role, parts}]`. Key in `X-goog-api-key` header
- **Anthropic Messages** (`.anthropic`): `POST /messages` with `system` + `messages`, `x-api-key` + `anthropic-version: 2023-06-01`
- **OpenAI-compatible** (`.openaiCompatible`): `POST /chat/completions` with `messages`. Covers OpenAI, xAI, OpenRouter, Together, Groq, Hugging Face (open-weight router), Fireworks, DeepInfra, Mistral (Pixtral), Ollama, and **Custom** (user supplies base URL + free-form model). OpenRouter + HF set `supportsCustomModelName = true`

Add a provider: case in `Models/AIProvider.swift` with `baseURL`/`models`/`apiFormat`/`apiKeyPlaceholder`. `.openaiCompatible` works automatically; otherwise add a branch in both `GeminiService.callAI` and `ChatService.sendMessage`.

503/529/429 auto-retry with 1s/2s/4s backoff (`GeminiService.makeRequest` and `ChatService.send`). Port the loop to any third LLM entry point. Final-failure copy is user-friendly ("provider is overloaded…") — never surface raw `HTTP 503` / provider JSON.

### Speech-to-Text (5 providers)

`VoiceInputView` branches on `SpeechSettings.selectedProvider`:
- **Native iOS** — `SFSpeechRecognizer` live partials. One-tap: Analyze stops + submits
- **Remote** (Whisper / Groq / Deepgram / AssemblyAI) — `AVAudioRecorder` → 16 kHz mono AAC m4a → `SpeechService.transcribe`. Two-tap: review transcript before Analyze

OpenAI + Groq share `/v1/audio/transcriptions` (multipart). Deepgram takes raw audio with `Token <key>`. AssemblyAI: upload → submit → poll 1s up to 60s.

### Coach (`ChatView` + `ChatStore` + `ChatService` + `CoachTools`)

5th tab in `ContentView` (Home / Progress / Coach / Settings / About). `ChatStore` keeps the full conversation in UserDefaults; `contextMessages()` returns the last 20 for the LLM (token cap; full history stays visible locally).

`buildSystemPrompt` is **slim**: profile (gender/age/height/weight/activity/goal + body fat + goal body fat), **active BMR formula** (Katch-McArdle when body fat is set AND `useBodyFatInBMR` is on, else Mifflin-St Jeor — distinguishes "body fat not set" vs "user disabled override"), BMR/TDEE, macros, `WeightAnalysisService.compute` output (predicted/observed trends, 30/60/90-day weight, days-to-goal, under-logging flag), and a one-line "Data available" snapshot. Bulk Recent weights / Recent body fat / Last N days dumps are **gone** — Coach pulls history on demand via tools.

**Tool calling** (`Services/CoachTools.swift`) — five functions: `get_data_summary` (counts + earliest/latest dates), `get_weight_history(from, to, limit?)`, `get_body_fat_history(from, to, limit?)`, `get_calorie_totals(from, to)`, `get_food_entries(from, to, limit?)`. Date-stamped JSON. List tools cap at 365 entries. Date parser is generous (defaults to last 30 days when `from` missing, end-of-day inclusive on `to`). The `nonisolated` static helpers (`iso`, `parseDate`, `isoFormatter`) avoid cross-actor warnings.

Per-format multi-turn loop in `ChatService` (`callGemini` / `callAnthropic` / `callOpenAICompatible`) capped at `maxToolRounds = 6`. OpenAI: `tool_choice:"auto"` + `role:"tool"` with `tool_call_id`. Anthropic: `tools` + `tool_use` content blocks with `tool_result` echoed in user-role. Gemini: `functionDeclarations` + `functionCall`/`functionResponse` parts in `role:"model"`/`role:"user"` echoes.

Goal-aware prompt chips — `ChatView.promptChips` differs for Lose / Gain / Maintain.

### Weight forecast (`WeightAnalysisService`)

Pure function. Up to 90 days, auto-scales. Returns `WeightForecast`: `predictedWeeklyChangeKg` (energy balance, 7700 kcal ≈ 1 kg), `observedWeeklyChangeKg` (linear regression, nil if <2 entries), 30/60/90-day predictions, `daysToGoal` if direction matches, `trendsDisagree` flag (>0.3 kg/wk gap). Used only as Coach context — no standalone UI card.

### Store → HealthKit callbacks

`FoodStore`:
- `onEntryAdded` → `writeNutrition(for:)`
- `onEntryDeleted` → `deleteNutrition(entryID:)`
- `onEntryUpdated` → `updateNutrition(for:)` (delete-then-write awaited atomically — don't replace with back-to-back delete+add)
- `onEntriesChanged` → notification rescheduling

`WeightStore`:
- `onEntryAdded` → `writeWeight(for:)` (tags `fudai_weight_id = entry.id.uuidString`)
- `onEntryDeleted` → `deleteWeight(entryID:)` (metadata predicate, bypasses `healthKitEnabled` flag)
- `addEntry` detects goal-weight crossings and posts `.weightGoalReached` (Progress tab shows "Congratulations!")
- **`init()` does NOT seed a starter entry.** Earlier version did, falling back to `UserProfile.default` (70 kg) before onboarding finished — dropped a phantom 70 kg entry on every fresh user. Seed now runs from `calorietrackerApp.onChange(of: hasCompletedOnboarding)` via `weightStore.seedInitialWeightFromProfileIfEmpty(profile.weightKg)`. Idempotent. Don't reintroduce init-time seeding
- `HealthKitManager.writeWeight(kg:date:)` (the profile-state push from onboarding/Settings, not per-entry) also tags with synthetic `fudai_weight_id = UUID().uuidString`. Untagged samples are invisible to `deleteWeight`'s metadata predicate

`BodyFatStore` — mirrors WeightStore: `onEntryAdded` → `writeBodyFat(for:)` tagging `fudai_bodyfat_id = entry.id.uuidString`; `onEntryDeleted` → `deleteBodyFat(entryID:)` by metadata predicate, bypasses `healthKitEnabled`. `fetchLatestBodyMeasurements()` returns `bodyFatDate` + `bodyFatFudaiID`. External body-fat samples (Withings / Renpho / Eufy / Apple Health manual) auto-import via observer with same skip-our-writes + same-day+fraction dedup as weight.

**One-shot HK backfill**: `backfillWeightFromHealthKitIfNeeded` and `backfillBodyFatFromHealthKitIfNeeded` pull every historical sample on first HK-enable, dedupe (skip our writes via metadata, dedupe externals by same-day + same-value), bulk-import via `WeightStore.importExternalEntries` / `BodyFatStore.importExternalEntries` (bypass `onEntryAdded` so imports don't echo back to HK). Each gated by its own UserDefaults version key (`healthKitWeightBackfillVersion`, `healthKitBodyFatBackfillVersion`) compared against `typesVersion`. `isBackfilling{Weight,BodyFat}` re-entrancy guards for the scene-active wire-up loop.

### HealthKit Conventions

`HealthKitManager` (`Stores/HealthKitManager.swift`) is the only HK boundary.

- **`typesVersion`** (renamed from `authVersion` to dodge a CodeQL "auth" heuristic) bumps when HK types are added. `needsReauthorization` returns `max(typesVersionKey, legacy healthKitAuthVersion)` < current so existing users aren't re-prompted after the rename
- `requestAuthorization` only persists the new version (`persistCurrentTypesVersion()`) when **all** dietary share types are `.sharingAuthorized` — users who deny nutrition can re-prompt
- Each nutrition sample carries `fudai_entry_id`; weight `fudai_weight_id`; body-fat `fudai_bodyfat_id`. Deletion via metadata predicate per quantity type. `fetchLatestSample` takes `fudaiMetadataKey` per type (height has none — we don't tag height writes)
- Change-token observer's gender-sync uses `switch ... default: break` (only update on explicit `.male`/`.female`). An earlier ternary mapped `.notSet` and `.other` to `Gender.other` and silently overwrote a user's onboarding-chosen gender on every scene-active when HK had no biological-sex value (default on simulator + users who never filled in Health). **Don't reintroduce the ternary.**
- `writeNutrition` guards on `healthKitEnabled`. `deleteNutrition` and the delete half of `updateNutrition` always run (even with sync off) so in-app edits/deletes still clean up samples exported before the user flipped sync off — otherwise they orphan in Apple Health forever
- `backfillNutritionIfNeeded` is idempotent (queries HK for each entry's UUID before writing), guarded by `isBackfillingNutrition`. Caller passes `currentEntryIDs: () -> Set<UUID>` so a meal deleted mid-backfill won't be re-exported
- Body-measurements observer skips weights with `fudai_weight_id` metadata (our own writes, handled by `WeightStore.addEntry` directly). External samples (Watch, scale, manual) go through the observer's date+value dedup with the sample's real date
- `startBodyMeasurementObserver()` calls `stopObserver()` **first** before registering the three `HKObserverQuery` instances — `wireUpHealthKit()` runs on every scene-active, and without tear-down `observerQueries` kept growing so one HK change fired the callback N times per session

Clear Food Log keeps Apple Health samples (only saves storage). **Delete All Data is local-only**: wipes in-memory stores, UserDefaults, Keychain API keys, Coach history, widget App Group snapshot — but intentionally NOT Apple Health. Users own that data; if they want it gone, Health app's Sources → Fud AI panel. (Earlier revisions purged HK nutrition here; reverted in favor of treating HK as untouched on resets.)

### Widgets (`FudAIWidgetsExtension` target + App Group)

Widget extension at `ios/FudAIWidgets/`, target `com.apoorvdarshan.calorietracker.FudAIWidgets`, embedded via `Embed Foundation Extensions` copy phase. Five families: `.systemSmall`, `.systemMedium`, `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`.

Widgets run in a separate process and can't read the main app's `UserDefaults`. Data flows through an **App Group**:

- **App Group ID**: `group.com.apoorvdarshan.calorietracker` (in both `ios/calorietracker/calorietracker.entitlements` and `ios/FudAIWidgets/FudAIWidgets.entitlements` — must match)
- **`WidgetSnapshot`** is a small Codable struct (today's totals + goals) at shared-suite key `widget_snapshot_v1`
- **Duplicated file**: `ios/calorietracker/Services/WidgetSnapshot.swift` and `ios/FudAIWidgets/WidgetSnapshot.swift` are identical — auto-discovery is per-target. Change one, change both
- **`WidgetSnapshotWriter.publish(...)`** (main app only) recomputes today's totals, writes the snapshot, calls `WidgetCenter.shared.reloadAllTimelines()`. Called from three places in `calorietrackerApp.swift`: `foodStore.onEntriesChanged`, `.userProfileDidChange` notification (goal edits), and scene-phase `.active` (so midnight rollover doesn't require an explicit food change)
- **Callback-wiring gotcha**: `wireUpFoodStoreCallback()` must run on **every** scene-active, not just the onboarding `false→true` transition. The `.onChange(of: hasCompletedOnboarding)` branch fires once ever; if it were the sole site, existing users would never get the callback. Closure assignment is idempotent
- **Timeline policy**: `CalorieProvider.getTimeline` emits one entry for "now" + 30 min refresh as a safety net
- **Freshness rules — don't regress these**:
  1. `WidgetSnapshot.read()` returns `nil` when `snapshot.dayStart` isn't today (fallback to `.empty`). Without this, the 30-min refresh kept showing yesterday's totals past midnight
  2. `WidgetSnapshotWriter.publish(...)` filters entries with `Calendar.isDate($0.timestamp, inSameDayAs: Date())` — NOT `>= startOfDay`. The latter folded tomorrow-dated entries (pre-logged via week strip) into today's totals
  3. `WidgetSnapshot.clear()` is called from Delete All Data and `refreshWidgetSnapshot()` when no profile is loaded. App Group container sits outside `UserDefaults.standard`, so `removePersistentDomain` doesn't touch it — without `clear()` the widget kept showing the previous profile's numbers after reset

Adding a widget: new `Widget` type in `ios/FudAIWidgets/`, add to `FudAIWidgetsBundle.body`, extend `CalorieWidgetView`'s `@Environment(\.widgetFamily)` switch for new families. New data → extend `WidgetSnapshot` in **both** files (Codable defaults so old snapshots still decode).

### Localization (15 languages)

`ios/calorietracker/Localizable.xcstrings` — ~200 UI strings × 15 locales: `en` (source), `ar`, `az`, `de`, `es`, `fr`, `hi`, `it`, `ja`, `ko`, `nl`, `pt-BR`, `ro`, `ru`, `zh-Hans`. No in-app picker (matches Cal AI / MyFitnessPal / Yazio). iOS auto-selects from device language.

**Rule**: every new `Text("...")`, `Button("...")`, `Section("...")`, `.alert("...")`, `.navigationTitle("...")`, placeholder, etc. lands in the catalog with all 14 non-English translations before commit. For batches of 10+ strings spawn a general-purpose agent; merge JSON into the catalog via a small Python script. `SWIFT_EMIT_LOC_STRINGS = YES` auto-extracts new English strings on build but leaves non-English entries empty — fill them in. Adding a language requires a code in the catalog + a `knownRegions` entry in `project.pbxproj`.

### UI Structure

- `ContentView` hosts a 5-tab layout: Home, Progress, Coach, Settings, About
- `OnboardingView` is the first-run flow including AI-provider setup
- Sheets/pickers route through a single `.sheet(item: $activeSheet)` driven by an enum (avoids SwiftUI's stacked-sheet bugs)
- `Views/Theme.swift` (`AppColors`) holds the gradient palette
- Picker sheets seed `@State` in `init()`, not `.onAppear`, to avoid a flash-to-default on open
- **Share sheets use `ActivityShareSheet`** (a `UIViewControllerRepresentable` over `UIActivityViewController` in `ContentView.swift`) — **not** SwiftUI's `ShareLink`. `ShareLink(item: URL, message:)` silently drops `message` for most targets (Messages, Mail, X), so only the URL gets shared. `[String, URL]` in `activityItems` forwards both. Used by About → Share the App

## Build, Install, Launch (Android)

Kotlin + Jetpack Compose. Target device: Apoorv's iQOO Z9 5G on OriginOS 6 (Android 15). Min SDK 26 (bumped from 24 for Health Connect).

```bash
# From /Users/ApoorvDarshan/fud-ai/android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

./gradlew :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.apoorvdarshan.calorietracker/.MainActivity

# Onboarding reset:
adb shell am start -n com.apoorvdarshan.calorietracker/.MainActivity --ez reset_onboarding true

# Logs:
adb logcat -s FudAI:* AndroidRuntime:E
```

**adb is not on PATH** — binary at `~/Library/Android/sdk/platform-tools/adb`. Alias or use absolute path; `command not found: adb` from a fresh shell is the giveaway.

**Debug builds install side-by-side with the Play Store release**, never overwriting it. `buildTypes.debug` sets `applicationIdSuffix = ".debug"` + `versionNameSuffix = "-debug"` so `assembleDebug` produces `com.apoorvdarshan.calorietracker.debug` — separate package, separate DataStore, separate widgets. Apoorv has the live closed-test build (`com.apoorvdarshan.calorietracker`, signed by production keystore) installed from Play Store; **always use the debug variant** for iteration so production install + real-user state stay intact. Debug-package adb commands:

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.apoorvdarshan.calorietracker.debug/com.apoorvdarshan.calorietracker.MainActivity
adb shell am start -n com.apoorvdarshan.calorietracker.debug/com.apoorvdarshan.calorietracker.MainActivity --ez reset_onboarding true
```

Both packages stay as plain "Fud AI" launcher icon — Apoorv distinguishes by install order / position.

OriginOS quirks: USB debugging needs **two** toggles (USB debugging + USB debugging Security settings under Developer options). Whitelist Fud AI in battery optimization so alarm-based reminders survive. Forcing dark/light mode via `cmd uimode night yes|no` or `settings put secure ui_night_mode` is **silently ignored** by the OEM skin — to verify both themes either toggle Settings → Appearance inside Fud AI (System / Light / Dark, persisted in DataStore, read by `MainActivity`'s `FudAITheme(darkTheme = ...)` wrap) or flip OS Settings → Display.

## Architecture (Android)

### Package layout

```
android/app/src/main/java/com/apoorvdarshan/calorietracker/
├── MainActivity.kt              ← entry point, checks onboarding flag, wires NavHost
├── FudAIApp.kt                  ← Application + AppContainer (manual DI)
├── models/                      ← UserProfile, FoodEntry, WeightEntry, BodyFatEntry,
│                                   ChatMessage, AIProvider, SpeechProvider, WidgetSnapshot,
│                                   Gender/ActivityLevel/WeightGoal/MealType/FoodSource/AutoBalanceMacro
├── data/                        ← PreferencesStore (DataStore), KeyStore (EncryptedSharedPreferences),
│                                   FoodRepository, WeightRepository, BodyFatRepository,
│                                   ProfileRepository, ChatRepository
├── services/
│   ├── ai/                      ← AiError, RetryPolicy, GeminiClient, AnthropicClient,
│   │                              OpenAICompatibleClient, FoodAnalysisService, ChatService, CoachTools,
│   │                              FoodAnalysis (+ NutritionLabelAnalysis + FoodJsonParser)
│   ├── speech/                  ← NativeSpeechRecognizer, AudioRecorder, SpeechService,
│   │                              WhisperClient, DeepgramClient, AssemblyAIClient
│   ├── health/HealthConnectManager.kt
│   ├── FoodImageStore.kt        ← filesDir/fudai-food-images/
│   ├── NotificationService.kt   ← 3 channels, AlarmManager scheduling, ReminderReceiver
│   └── WeightAnalysisService.kt ← pure forecast math
└── ui/
    ├── theme/                   ← AppColors (iOS pink/red), FudAITheme, Typography
    ├── navigation/              ← FudAINavHost, FudAIBottomNavBar, FudAIRoutes
    ├── onboarding/              ← OnboardingScreen + OnboardingViewModel (10-step)
    ├── home/                    ← HomeScreen + HomeViewModel
    ├── progress/                ← ProgressScreen + ProgressViewModel (Canvas line chart)
    ├── coach/                   ← CoachScreen + CoachViewModel
    ├── settings/                ← SettingsScreen + SettingsViewModel (sheet-driven pickers)
    └── about/                   ← AboutScreen
```

### State / DI

Manual DI via `FudAIApp.container` (`AppContainer` singleton) — no Hilt. Repos/services instantiated once in `FudAIApp.onCreate()` and handed to ViewModels via `ViewModelProvider.Factory`. Screens pull with `viewModel(factory = ...)`. Reactive reads via `Flow<T>`; ViewModels expose `StateFlow<UiState>` collected with `collectAsState()`. Matches iOS `@Observable` + `.environment()` in spirit.

### AI / Coach / Speech

Same 13 providers, 3 dialects, retry policy, and friendly-copy rules as iOS. Clients: `GeminiClient`, `AnthropicClient`, `OpenAICompatibleClient` (covers OpenAI / xAI / OpenRouter / Together / Groq / HF / Fireworks / DeepInfra / Mistral / Ollama / Custom). `FoodAnalysisService` + `ChatService` dispatch on `AIProvider.apiFormat`. `RetryPolicy` does 1s/2s/4s on 503/429/529.

**Coach tool calling** (`services/ai/CoachTools.kt`) — same 5 functions and contract as iOS, returning date-stamped JSON via `org.json`. List tools cap at 365 entries. Per-format multi-turn loops in `ChatService` (`runOpenAIToolLoop` / `runAnthropicToolLoop` / `runGeminiToolLoop`) capped at `MAX_TOOL_ROUNDS = 6`. Same wire conventions as iOS (OpenAI tool_choice/tool_call_id, Anthropic tool_use/tool_result blocks, Gemini functionDeclarations/functionCall/functionResponse). `buildSystemPrompt` is slim with the same "Data available" snapshot — no bulk dumps.

**Speech**: native `android.speech.SpeechRecognizer` wrapped as cold `Flow<SttEvent>` with streaming partials. Remote (Whisper / Groq / Deepgram / AssemblyAI): `AudioRecorder` writes 16 kHz mono AAC to cache, per-provider client uploads + parses.

### Health Connect

Single boundary in `HealthConnectManager`. Weight + Nutrition + Body Fat read/write with `Metadata.manualEntry(clientRecordId = "fudai_<uuid>")` for dedup. Combined `ChangesTokenRequest` watches both `WeightRecord` + `BodyFatRecord` (single token). `consumeWeightChanges` / `consumeBodyFatChanges` drain externals; `writeBodyFat(entry)` / `deleteBodyFat(entryId)` mirror weight. `CURRENT_TYPES_VERSION = 2` (bumped from 1 when BodyFat permissions added — existing users re-prompt). Min SDK 26 is required by Health Connect.

**Caveat**: HC manager methods exist but `BodyFatRepository` + `WeightRepository` don't yet wire `onEntryAdded`/`onEntryDeleted` callbacks into `writeBodyFat`/`writeWeight`, and there's no scene-active observer loop draining `consumeChanges`. Full sync wire-up is pending — when added, do both metrics together (shared change-token + `*BackfillVersion` orchestration).

### Persistence

| iOS | Android |
|---|---|
| UserDefaults JSON blobs | DataStore Preferences + kotlinx.serialization |
| iOS Keychain | EncryptedSharedPreferences (AES-256) |
| Application Support/ | `context.filesDir/fudai-food-images/` |
| App Group shared UserDefaults | Widget reads same DataStore (same process by default) |

### UI

5-tab bottom navigation (Home / Progress / Coach / Settings / About) mirroring iOS. NavHost hides the bar on the onboarding route. Pink `#FF375F → #FF6B8A` gradient, cream/dark semantic backgrounds, rounded typography via `FontFamily.Default`.

### Localization (Android)

Same 15 languages. Resource qualifiers, not String Catalog: `values/strings.xml` (English source, ~509 keys) + `values-{ar,az,de,es,fr,hi,it,ja,ko,nl,pt-rBR,ro,ru,zh-rCN}/strings.xml`. Auto-resolved from `Locale.getDefault()`, no in-app picker.

**Enum displayName pattern**: model enums (`Gender`, `ActivityLevel`, `WeightGoal`, `MealType`, `AIProvider`, `SpeechProvider`, `AutoBalanceMacro`) expose `@get:StringRes val displayNameRes: Int`, never hardcoded `displayName: String`. Call sites wrap with `stringResource(it.displayNameRes)`. New enum case → matching `<string>` in `values/` + all 14 locales.

**Composable scope gotcha**: `stringResource(...)` only works inside `@Composable`. `LazyColumn { ... }` lambdas have `LazyListScope` (not @Composable) — resolve strings before the LazyColumn and capture them. `EditFoodEntrySheet.kt` "More Nutrition" hoists `gUnit`/`mgUnit`/`micros` for exactly this reason.

**Glance widgets** can't use `stringResource`; use `LocalContext.current.getString(R.string.x)`.

### Release Build & Signing (Android)

Release config in `app/build.gradle.kts` enables `isMinifyEnabled = true` + `isShrinkResources = true`. Without, APK is ~29 MB; with R8 it's ~4.4 MB.

**Signing**: `signingConfigs.release` reads from `android/keystore.properties` (gitignored — see `keystore.properties.template`). Absent file (fresh checkout, CI without secrets) still builds, just unsigned. Keystore at `~/Documents/fudai-keystore/fudai-release.jks` outside the repo. **Losing the keystore means a 1–2 week recovery flow with Google Play App Signing reset** — back it up.

AAB for Play Console: `./gradlew :app:bundleRelease` → `app/build/outputs/bundle/release/app-release.aab`.

**Shipped artifacts live in `android/release/`** (tracked in git). After every Play-Store-bound build, copy signed outputs as `fudai-v<MARKETING>.aab` + `fudai-v<MARKETING>.apk` and commit. Older versions are never deleted — offline archive of every Play Console upload.

**ProGuard/R8 keep rules** (`app/proguard-rules.pro`) — caught real release-only crashes, don't strip:

1. **kotlinx.serialization** — every `@Serializable` class is reflected at runtime to find its `$$serializer`. Without keeps, DataStore + widget snapshot decode fails with `NoSuchMethodError: serializer()`
2. **WorkManager + Room** — Glance uses WorkManager which uses Room for `WorkDatabase`. R8 strips `@Database` without explicit keeps, crashing `Application.onCreate` with `Failed to create an instance of androidx.work.impl.WorkDatabase`
3. **Glance widgets** — `CalorieAppWidget` / `ProteinAppWidget` are reflected from `AndroidManifest.xml`; keep the whole `widget/` package
4. **Health Connect** — defensive keep on `androidx.health.connect.client.records.**` even though the AAR ships consumer rules

If release crashes but debug works, R8 stripping is suspect #1 — check `app/build/outputs/mapping/release/missing_rules.txt`.

**Verify release before uploading**: `./gradlew :app:assembleRelease` → sign with keystore (or debug-sign with `apksigner` for sideload) → install → exercise reflection-hitting surfaces (food log persistence, widget refresh, KeyStore reads) on device.

## Website (`web/`)

Plain static HTML + CSS, Vercel, domain `fud-ai.app`. Vercel git integration must point at this repo with **Root Directory = `web/`** (previously pointed at obsolete `apoorvdarshan/fud-ai-web`).

- **Pages**: `web/index.html`, `web/privacy.html`, `web/terms.html`
- **Assets**: `web/assets/` — logo, OG preview, screenshots
- **OG image**: `web/assets/og-preview.png` referenced with `?v=N` in `index.html` meta tags. Bump version when replacing so X / Facebook / LinkedIn re-scrape
- **SEO**: `web/robots.txt`, `web/sitemap.xml`
- **Preview locally**: `cd web && python3 -m http.server 8000`

## Gotchas (Android)

- **EncryptedSharedPreferences AEAD recovery**: on Android 14/15 the AndroidKeystore master-key alias survives `pm uninstall` but the encrypted prefs file does not, so a reinstall hits `javax.crypto.AEADBadTagException` on first read and crashes `Application.onCreate` before any UI shows. `KeyStore.openOrRecover()` catches, deletes the prefs file + master-key alias, and rebuilds. Don't strip the recovery path — every Play Store update from a wiped install would crash users
- **Glance bitmap rasterization**: Glance has no `Canvas`/arc primitives. The pink-gradient progress ring on Calorie/Protein widgets is rendered into a Bitmap (`widget/RingBitmap.kt`) and passed via `ImageProvider(bitmap)`. Computed in `provideGlance` per recomposition — small enough (~100×100×4 bytes) not to matter
- **NavController + start destination**: tapping the Home tab while *on* Home is a no-op for `nav.navigate(HOME) { popUpTo(HOME); launchSingleTop = true }`. Use `nav.popBackStack(HOME, inclusive = false)`. Bottom-nav code already does this
- **OriginOS USB debugging**: needs **two** toggles in Developer options — USB debugging *plus* USB debugging (Security settings). Without the second, `adb install` works but `adb shell input tap` and `am start --es ...` extras get blocked
- **OriginOS battery optimization**: `AlarmManager.setAndAllowWhileIdle` reminders get killed unless the app is whitelisted. Settings deep-links to per-app whitelist via `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (with fallback chain to `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` + `ACTION_APPLICATION_DETAILS_SETTINGS` for OEMs that block the direct intent)
- **No exact alarms**: reminders use inexact `setAndAllowWhileIdle`, never `setExactAndAllowWhileIdle`. Play Console blocks `USE_EXACT_ALARM` for any app whose core function isn't a calendar or alarm clock — Fud AI is neither, and the v1.0.0 closed-test upload was rejected the one time we shipped that permission. Manifest deliberately omits both `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM`. A few-minute drift is fine — don't reintroduce exact alarms
- **Notifications wiring**: Settings has a single master "Notifications" toggle (no per-reminder sub-controls — the iOS-side per-reminder UI was not ported). Toggle controls one daily reminder: a **weight-log nudge at 08:00** ("Time to weigh in / Log today's weight to keep your progress chart accurate."). `NotificationService.scheduleStreakReminder` and `scheduleDailySummary` exist for parity but are **not wired to UI** — only `scheduleWeightReminder` fires. Wire-up site is `SettingsViewModel.setNotificationsEnabled`: ON + `canPostNotifications()` → schedule, OFF → cancel. `FudAIApp.onCreate` re-arms on every cold start (gated by same prefs+permission check) because `AlarmManager` drops scheduled alarms across reboots and some app-update paths. If you add streak/summary scheduling later, wire those re-arms into the same `onCreate` block
- **DataStore singleton**: `Context.fudaiDataStore` is a `preferencesDataStore` extension. Both main app and widget receivers call `PreferencesStore(context)` and get the same backing DataStore as long as application context is used — that's how widgets see writes without IPC. Don't reach for a separate widget store
- **Drag-to-reorder inside ModalBottomSheet** is fundamentally fragile on Android — sheet's drag-to-dismiss and any internal vertical scroll compete for the same gesture. Favorites in Saved Meals uses native ↑/↓ buttons (`MoveButtons`). If you reach for drag-to-reorder again, expect to fight it
- **Light-mode visibility for white-on-glass overlays**: the iOS-26-style liquid-glass + button on the Home top bar uses `Color.White` at 0.22/0.08 alpha — reads against `AppBackgroundDark` (#0C0C0C) but vanishes against `AppBackgroundLight` (#FFF8F2). v1.0.1 shipped with an invisible + button in light mode. Fix in `HomeScreen.kt`: `MaterialTheme.colorScheme.background.luminance() < 0.5f` decides which fill+border to use, swapping in brand pink gradient for light mode. **Use `MaterialTheme.colorScheme.background.luminance()` rather than `isSystemInDarkTheme()`** — OriginOS overrides uimode at the OEM layer and the two can drift; the rendered theme is the only reliable source of truth. Same swap applies to any new glass overlay (Coach FAB, Saved-Meals header, etc.)

## Gotchas (iOS)

- **SourceKit false positives**: editing surfaces "no module 'UIKit'" / "Cannot find type 'FoodEntry' in scope" errors that aren't real. Build with `xcodebuild` to verify
- **`.buttonStyle(.plain)` kills row tap-highlight** in a `List`. Use `.tint(.primary)` to keep the highlight while preserving primary text color
- **Multiple `.sheet()` modifiers** on the same view cause white/black-screen bugs. Always single `.sheet(item:)` driven by an enum
- **`ProgressView`** is renamed to `ProgressTabView` to avoid clashing with SwiftUI's built-in `ProgressView`
- **`@Observable` tracking can miss property access buried in computed vars.** HomeView, ProgressTabView, NutritionDetailView each read `let _ = profileStore.profile` at the top of `body` to force observation tracking. Don't remove
- **Dead files** (kept for git history, not referenced): `StoreManager.swift`, `PaywallView.swift`, `SpinWheelView.swift`, `CloudKitService.swift`. Don't add new code to them
- **Persistent state** lives in two places: `UserDefaults` (preferences + JSON `entries`/`weights`/`bodyFatEntries`/`favorites`/`coachChatHistory` arrays + `*Enabled`/`*Reminder*` keys via `@AppStorage`) and iOS Keychain (LLM + STT API keys via `KeychainHelper`). No Core Data / SwiftData / iCloud
- **CodeQL is not configured** anymore — the workflow was removed because it produced almost entirely false positives on UserDefaults writes near "auth"-keyword variables for a local-only app with no auth flows

## Commit Style

- Plain factual messages. No co-author trailer. No marketing language
- Commit and push immediately after each working change
- When a commit adds user-facing strings, mention the catalog was updated

## Release Artifacts

- **`APPSTORE.md`** holds App Store Connect listing copy for iOS — name, subtitle, promo text, keywords, What's New, full description, reviewer notes. Update on every iOS version bump (current header: `v3.2`). **Description has a 4000-char hard cap** (App Store Connect rejects anything over) — trim per-section bullets into single dense lines if you bloat past it (the v3.2 trim went 4515 → 3159 chars without losing any feature)
- **Play Console listing copy** is maintained directly in Play Console (no in-repo `PLAYSTORE.md` — it kept drifting from what's actually live; canonical source for store description / Data Safety / App Content declarations is the Play Console UI itself)
- **App Store screenshots** live in `~/Documents/fud ai/appstore screenshots/` (raw 1179×2556 captures from device) and get composited into 1242×2688 marketing PNGs by ad-hoc Python scripts in `/tmp/`. Scripts are not in the repo — rebuilt per release. Current iteration uses PIL gradient backgrounds + a pixel-perfect iPhone 15 Pro Max frame + Bricolage Grotesque ExtraBold typography
- Bump `MARKETING_VERSION` in `ios/calorietracker.xcodeproj/project.pbxproj` (two occurrences — main app + widget extension) before each App Store submission. `CURRENT_PROJECT_VERSION` is the build number

## Identity

- Website: https://fud-ai.app
- App Store: https://apps.apple.com/us/app/fud-ai-calorie-tracker/id6758935726
- Play Store: https://play.google.com/store/apps/details?id=com.apoorvdarshan.calorietracker
- Email: apoorv@fud-ai.app
- X: @apoorvdarshan
- Donations: https://paypal.me/apoorvdarshan
