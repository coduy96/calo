<p align="center">
  <img src="appicon.png" width="120" height="120" alt="Fud AI Logo" style="border-radius: 22px;">
</p>

<h1 align="center">Fud AI</h1>

<p align="center">
  <strong>Eat Smart, Live Better</strong><br>
  Snap, speak, or type your food — AI handles the rest.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017.6+-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <a href="https://apps.apple.com/us/app/fud-ai-calorie-tracker/id6758935726"><img src="https://img.shields.io/badge/App%20Store-Download-black?logo=apple" alt="App Store"></a>
</p>

---

Open-source, privacy-first calorie tracker for iOS. Bring your own AI provider — Gemini, OpenAI, Claude, Grok, Groq, Ollama, and more. All data stays on your device. No accounts, no cloud sync, no tracking, no subscriptions.

[Download on the App Store](https://apps.apple.com/us/app/fud-ai-calorie-tracker/id6758935726) · [Website](https://fud-ai.app) · [Report an Issue](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=bug&title=Bug:%20) · [Request a Feature](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=enhancement&title=Feature:%20)

---

## Features

- **Snap food** — camera identifies meals and estimates nutrition
- **Camera + Note** — add a description with the photo for better accuracy
- **Nutrition label scan** — reads packaging for precise per-serving data
- **Photo library** — analyze existing photos
- **Text input** — type food descriptions
- **Voice input** — speak your meals hands-free
- **Saved Meals** — Recents, Frequent, and Favorites tabs with swipe actions and drag-to-reorder
- **13 nutrients** tracked per entry (calories, protein, carbs, fat + 9 micronutrients)
- **Scrollable week calendar** — swipe to any past week, configurable start day
- **Progress charts** — weight trends, calorie history, macro averages (1W to All Time)
- **Goal tracking** — set target weight, BMR/TDEE auto-calculation
- **Apple Health** — bidirectional sync for body measurements + 12 nutrition types written per meal
- **Meal reminders** — customizable breakfast, lunch, dinner notifications
- **Dark mode** — system, light, or dark
- **Metric & imperial** units

## Supported AI Providers

| Provider | Format | Needs API Key |
|----------|--------|:---:|
| Google Gemini | Gemini API | Yes |
| OpenAI | OpenAI | Yes |
| Anthropic Claude | Messages API | Yes |
| xAI Grok | OpenAI-compatible | Yes |
| OpenRouter | OpenAI-compatible | Yes |
| Together AI | OpenAI-compatible | Yes |
| Groq | OpenAI-compatible | Yes |
| Ollama | OpenAI-compatible (local) | No |

API keys are stored in **iOS Keychain** — encrypted, on-device only. Switch providers and models any time from Settings.

## How It Works

```
Photo / Text / Voice
        |
        v
  AI Provider API  ──>  JSON nutrition response
        |
        v
  User reviews & edits
        |
        v
  FoodStore.addEntry()  ──>  UserDefaults (local) + Apple Health (optional)
```

## Calorie & Macro Calculation

The app calculates personalized daily targets using established nutrition science formulas:

| Step | Formula | Details |
|------|---------|---------|
| **BMR** | Katch-McArdle | `370 + 21.6 × lean mass (kg)` — used when body fat % is known |
| **BMR** | Mifflin-St Jeor | `10w + 6.25h - 5a ± 5` — fallback when body fat is unknown |
| **TDEE** | BMR × activity | Multiplier ranges from 1.2 (sedentary) to 2.0 (extra active) |
| **Daily Calories** | TDEE + adjustment | Adjustment = `weeklyChangeKg × 7700 / 7` (deficit or surplus) |
| **Protein** | Activity-based | `1.0 – 2.2 g/kg` body weight depending on activity level |
| **Fat** | Fixed ratio | `0.6 g/kg` body weight |
| **Carbs** | Remainder | `(calories - protein×4 - fat×9) / 4` |

All values can be manually overridden in Settings.

## Architecture

| Component | Details |
|-----------|---------|
| **Language** | Swift 5, SwiftUI |
| **Target** | iOS 17.6+ |
| **Storage** | UserDefaults (local JSON), Keychain (API keys) |
| **AI** | Multi-provider via `GeminiService` (routes by provider format) |
| **Health** | HealthKit read/write (body measurements + 12 nutrition types) with background observers |
| **Pattern** | `@Observable` + `.environment()`, main actor isolation |
| **Dependencies** | Zero |

### Source Layout

```
calorietracker/
├── calorietrackerApp.swift      # Entry point, environment setup
├── ContentView.swift            # 4-tab layout (Home, Progress, Settings, About)
├── Models/
│   ├── AIProvider.swift         # Provider enum, model lists, settings
│   ├── UserProfile.swift        # BMR/TDEE/macro calculations
│   ├── FoodEntry.swift          # Food item with 13 nutrients
│   └── WeightEntry.swift        # Weight log entry
├── Views/
│   ├── OnboardingView.swift     # Onboarding flow
│   ├── FoodResultView.swift     # AI result review & edit
│   ├── RecentsView.swift        # Saved Meals (Recents / Frequent / Favorites)
│   ├── HomeComponents.swift     # Week strip, macro cards
│   └── ProgressComponents.swift # Charts, weight tracking
├── Services/
│   ├── GeminiService.swift      # Multi-provider AI router
│   ├── KeychainHelper.swift     # iOS Keychain wrapper
│   └── APIKeyManager.swift      # Keychain migration helper
└── Stores/
    ├── FoodStore.swift           # Food entry CRUD + favorites
    ├── WeightStore.swift         # Weight entry CRUD
    ├── NotificationManager.swift # Notification scheduler
    └── HealthKitManager.swift    # Apple Health bridge (body + nutrition)
```

## Build & Run

```bash
# Clone
git clone https://github.com/apoorvdarshan/fud-ai.git
cd fud-ai

# Build
xcodebuild -scheme calorietracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Open in Xcode, select your device, and run. On first launch, go to **Settings > AI Provider** to set your provider and API key. A free Gemini key is available at [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Bug reports and feature requests are welcome.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability disclosure. Use [private vulnerability reporting](https://github.com/apoorvdarshan/fud-ai/security/advisories/new) for sensitive issues.

## Privacy

All data is stored locally on your device. No accounts, no cloud sync, no analytics. API keys are stored in iOS Keychain. See [Privacy Policy](https://fud-ai.app/privacy.html).

## License

MIT License. See [LICENSE](LICENSE).

## Contact

- **Developer:** Apoorv Darshan
- **Email:** apoorv@fud-ai.app
- **Follow on X:** [@apoorvdarshan](https://x.com/apoorvdarshan)
- **Report an Issue:** [github.com/apoorvdarshan/fud-ai/issues/new?labels=bug&title=Bug:%20](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=bug&title=Bug:%20)
- **Request a Feature:** [github.com/apoorvdarshan/fud-ai/issues/new?labels=enhancement&title=Feature:%20](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=enhancement&title=Feature:%20)

## Support the Project

Fud AI is fully free, open source, and privacy-first. If it helps you, consider supporting development — every bit keeps this project alive.

[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?logo=paypal)](https://paypal.me/apoorvdarshan)
[![Product Hunt](https://img.shields.io/badge/Product%20Hunt-Vote-orange?logo=producthunt)](https://www.producthunt.com/products/fud-ai-calorie-tracker)

You can also help by [voting on Product Hunt](https://www.producthunt.com/products/fud-ai-calorie-tracker), [starring the repo](https://github.com/apoorvdarshan/fud-ai), [filing bugs](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=bug&title=Bug:%20), or [requesting features](https://github.com/apoorvdarshan/fud-ai/issues/new?labels=enhancement&title=Feature:%20).

## Contributors

Thanks to everyone who has contributed to making Fud AI better:

<a href="https://github.com/apoorvdarshan/fud-ai/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=apoorvdarshan/fud-ai" alt="Contributors" />
</a>
