# Fud AI — Android

Jetpack Compose + Kotlin port of the iOS app. Min SDK 26 (Android 8.0), target SDK 36.

## Quick start

1. Open `android/` in Android Studio (Narwhal Feature Drop or newer).
2. Let Gradle sync — accept any AGP / Kotlin / Compose upgrade prompts.
3. Plug in a physical device with USB debugging enabled, or start an emulator (Pixel 8a API 34+ works well).
4. Click the green ▶ Run button — app installs + launches.

First launch goes through onboarding. In Settings → AI Provider paste a **Gemini API key** (free tier from https://aistudio.google.com/apikey) to start logging food.

## Build / install / launch from the CLI

For reproducible builds outside Android Studio:

```bash
# From /Users/<you>/fud-ai/android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# Build debug APK
./gradlew :app:assembleDebug

# Install on connected device
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch
adb shell am start -n com.apoorvdarshan.calorietracker/.MainActivity

# Launch with onboarding reset (parallel to iOS --reset-onboarding)
adb shell am start -n com.apoorvdarshan.calorietracker/.MainActivity --ez reset_onboarding true

# Tail logs
adb logcat -s FudAI:* AndroidRuntime:E
```

## iQOO / OriginOS USB debugging

On vivo / iQOO devices running OriginOS, USB debugging needs two toggles enabled:

1. Settings → About phone → tap **Software version** 7 times
2. Settings → System → Developer options → enable **USB debugging**
3. Settings → System → Developer options → enable **USB debugging (Security settings)** ← OriginOS-specific
4. After first install, Settings → Battery → Background battery usage → Fud AI → **Unrestricted** so alarm-based reminders aren't killed.

## Architecture

Full layout is documented in the root `CLAUDE.md` under "Architecture (Android)". Quick summary:

- **Models** (`models/`) — Kotlin data classes + enums, `@Serializable` via kotlinx.serialization.
- **Persistence** (`data/`) — `PreferencesStore` (DataStore Preferences) + `KeyStore` (EncryptedSharedPreferences for API keys).
- **Repositories** (`data/`) — `FoodRepository`, `WeightRepository`, `ProfileRepository`, `ChatRepository` exposing reactive `Flow<T>`.
- **Services** (`services/`) — `ai/` (Gemini + Anthropic + OpenAI-compatible clients + retry), `speech/` (native + 4 remote STT), `health/HealthConnectManager`, `FoodImageStore`, `NotificationService`, `WeightAnalysisService`.
- **UI** (`ui/`) — Compose screens per tab, `theme/` (fud-ai pink/red), `navigation/` (NavHost + bottom bar).
- **DI** — manual via `AppContainer` held on `FudAIApp` (Application). No Hilt.

## Tests

No automated tests yet (matches iOS). Validate by hand on device.

## Known TODOs post-v1

- Voice input UI (streaming native + remote two-tap flow) — the service layer is done, UI stub in Home
- Jetpack Glance widgets (3 sizes)
- Saved Meals sheet (Recents / Frequent / Favorites relog)
- CameraX live preview (currently uses PickVisualMedia system picker)
- String extraction + 14 non-English translations (currently English hardcoded)
- Health Connect change-token observer wired into scene-resume
- Custom spin-wheel picker for height/weight/body fat (currently text input)

## License

MIT. See `LICENSE` at the repo root.
