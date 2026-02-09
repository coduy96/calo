<p align="center">
  <img src="appicon.png" width="120" height="120" alt="Fud AI Logo" style="border-radius: 22px;">
</p>

<h1 align="center">Fud AI</h1>

<p align="center">
  <strong>Eat Smart, Live Better</strong><br>
  Just snap, track, and thrive. Your nutrition, simplified.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2026.2+-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/AI-Gemini%202.5%20Flash-green?logo=google" alt="Gemini AI">
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies">
  <img src="https://img.shields.io/badge/license-All%20Rights%20Reserved-red" alt="License">
</p>

---

Fud AI is an AI-powered calorie and nutrition tracker for iOS. Snap a photo of your food or nutrition label, and Gemini 2.5 Flash instantly identifies the item and estimates its full nutritional breakdown — calories, macros, and 9 micronutrients. No barcode databases, no manual searching. Just point, shoot, and log.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [How It Works](#how-it-works)
- [Nutrition Tracking](#nutrition-tracking)
- [Apple Health Integration](#apple-health-integration)
- [iCloud Sync](#icloud-sync)
- [Subscription Plans](#subscription-plans)
- [Architecture & Developer Guide](#architecture--developer-guide)
- [Build & Run](#build--run)
- [Privacy Policy](#privacy-policy)
- [Terms of Service](#terms-of-service)
- [License](#license)
- [Contact](#contact)

---

## Features

### AI Food Recognition
- **Snap Food** — Take a photo of any meal and get instant calorie and macro estimates
- **Nutrition Label Scan** — Photograph a nutrition facts panel for precise per-serving data
- **Photo Library** — Analyze existing photos from your camera roll
- **Text Input** — Type a brand, food name, and quantity for AI-powered nutrition lookup

### Comprehensive Nutrition Tracking
- Track **13 nutrients** per entry: calories, protein, carbs, fat, sugar, added sugar, fiber, saturated fat, monounsaturated fat, polyunsaturated fat, cholesterol, sodium, and potassium
- Adjustable **serving sizes** with real-time nutrition recalculation
- Organize entries by **meal type** (Breakfast, Lunch, Dinner, Snack, Other)
- Browse past days with a **date selector**

### Smart Dashboard
- Daily calorie hero display with progress bar
- Macro cards for protein, carbs, and fat with gradient visuals
- Detailed nutrition breakdown view
- Food log grouped by meal type with swipe-to-delete

### Progress & Analytics
- **Weight chart** with trend visualization
- **Calorie trend chart** showing daily intake vs. goal
- **Macro averages** over selected time range
- **Streak tracking** — current streak, best streak, days on target
- Time range filters: Week, Month, Year, All Time

### Personalized Plans
- 24-step onboarding that collects your gender, age, height, weight, body fat %, activity level, goals, and dietary preferences
- **BMR calculation** using Katch-McArdle (with body fat) or Mifflin-St Jeor
- **TDEE** with 6 activity level multipliers (1.2x - 2.0x)
- Auto-calculated daily targets for calories, protein, carbs, and fat
- Fully customizable — override any calculated value

### Apple Health Integration
- **Writes** all 12 nutrition data types to Apple Health per food entry
- **Writes** body mass, height, and body fat percentage
- **Reads** weight, height, body fat, date of birth, and biological sex
- **Bidirectional sync** — profile updates when Health data changes
- Background observer for real-time measurement sync

### iCloud Sync
- Food entries, weight entries, and user profile sync to your private iCloud database
- Automatic sync on every add, delete, and profile save
- Returning users can restore all data on a new device during onboarding
- Sign in with Apple for secure authentication

### Smart Notifications
- Customizable **meal reminders** for breakfast, lunch, and dinner
- **Streak protection** — reminds you to log food before your streak breaks
- **Daily summary** — shows calories consumed vs. remaining

### Learn
- 11 educational articles on nutrition, weight loss science, macronutrients, AI tracking, and more
- Category filtering (Nutrition, Science, Lifestyle, Technology)
- Search and sort functionality
- Reading time estimates

### Additional
- **Dark mode** with system, light, and dark appearance options
- **Metric and imperial** unit support
- **Scratch card gamification** during onboarding for subscription discounts
- **Delete all data** option for full account removal (local + cloud)

---

## Screenshots

*Coming soon*

---

## How It Works

```
User captures photo ──> Gemini 2.5 Flash AI ──> JSON nutrition response
                                                        │
                        User reviews & edits  <─────────┘
                                │
                        FoodStore.addEntry()
                                │
                  ┌─────────────┼─────────────┐
                  │             │              │
            UserDefaults    CloudKit     Apple Health
            (local JSON)   (iCloud)     (if enabled)
```

1. **Capture** — Snap a photo, scan a label, pick from library, or type food details
2. **Analyze** — Gemini 2.5 Flash identifies the food and estimates full nutrition
3. **Review** — Edit the name, adjust serving size, and confirm meal type
4. **Log** — Entry is saved locally, synced to iCloud, and written to Apple Health
5. **Track** — Dashboard and progress charts update in real time via `@Observable`

---

## Nutrition Tracking

### Macronutrients (always tracked)
| Nutrient | Unit |
|----------|------|
| Calories | kcal |
| Protein | g |
| Carbohydrates | g |
| Fat | g |

### Micronutrients (AI-estimated when available)
| Nutrient | Unit |
|----------|------|
| Sugar | g |
| Added Sugar | g |
| Fiber | g |
| Saturated Fat | g |
| Monounsaturated Fat | g |
| Polyunsaturated Fat | g |
| Cholesterol | mg |
| Sodium | mg |
| Potassium | mg |

### Calorie & Macro Calculation

| Formula | Method |
|---------|--------|
| **BMR** | Katch-McArdle (if body fat known) or Mifflin-St Jeor |
| **TDEE** | BMR x activity multiplier (1.2 - 2.0) |
| **Daily Calories** | max(1200, TDEE + weeklyChangeKg x 7700 / 7) |
| **Protein** | activityLevel.proteinPerKg x weightKg (1.0 - 2.2 g/kg) |
| **Fat** | 0.6 x weightKg |
| **Carbs** | (dailyCalories - protein x 4 - fat x 9) / 4 |

---

## Apple Health Integration

### Data Written
- Dietary Energy, Protein, Carbohydrates, Fat, Sugar, Fiber
- Saturated Fat, Monounsaturated Fat, Polyunsaturated Fat
- Cholesterol, Sodium, Potassium
- Body Mass, Height, Body Fat Percentage

### Data Read
- Body Mass, Height, Body Fat Percentage
- Date of Birth, Biological Sex

Health data is written per food entry with timestamps and tracked by UUID for accurate deletion. A background observer monitors Health for external weight/height/body fat changes and syncs them back to the app.

---

## iCloud Sync

| Data | Synced | Notes |
|------|--------|-------|
| Food Entries | Yes | Excludes image data (stored locally only) |
| Weight Entries | Yes | Full bidirectional sync |
| User Profile | Yes | Single record, overwritten on save |
| Food Photos | No | Too large for CloudKit |

- **Container:** `iCloud.com.apoorvdarshan.calorietracker`
- **Database:** Private CloudKit database (only accessible to the signed-in user)
- **Merge strategy:** By UUID — cloud records replace local duplicates
- **Batch size:** Up to 400 records per sync operation

---

## Subscription Plans

| Plan | Price | Scans | Product ID |
|------|-------|-------|------------|
| **Free** | $0 | 3 total | — |
| **Monthly** | $7.99/mo | 25/day | `fudai.subscription.monthly` |
| **Yearly** | $29.99/yr ($2.50/mo) | 25/day | `fudai.subscription.yearly` |
| **Yearly Discount** | $21.99/yr ($1.83/mo) | 25/day | `fudai.subscription.yearly.discount` |

- Auto-renewable subscriptions via StoreKit 2
- Daily scan counter resets at midnight
- Restore Purchases available in profile and paywall screens
- Cancel anytime through iOS subscription management

---

## Architecture & Developer Guide

### Tech Stack
- **Language:** Swift 5
- **UI:** SwiftUI (iOS 26.2+)
- **AI:** Google Gemini 2.5 Flash API
- **Storage:** UserDefaults (local), CloudKit (cloud), HealthKit (health)
- **Payments:** StoreKit 2
- **Auth:** Sign in with Apple (ASAuthorization)
- **Dependencies:** Zero external dependencies

### Key Patterns

| Pattern | Details |
|---------|---------|
| `@Observable` macro | Not `ObservableObject`. Inject with `.environment()`, consume with `@Environment(Type.self)` |
| Main actor isolation | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — no manual `@MainActor` needed |
| File discovery | `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers new files, never edit pbxproj |
| Stateless services | `GeminiService` and `CloudKitService` are pure structs with static methods |
| Secrets management | `Secrets.plist` (gitignored) loaded via `APIKeyManager` |

### Environment Objects (injected at app root)

| Object | Purpose |
|--------|---------|
| `FoodStore` | Food entry CRUD, daily totals, streak calculation |
| `WeightStore` | Weight entry CRUD, trend data |
| `NotificationManager` | Local notification scheduling and permissions |
| `AuthManager` | Apple Sign-In, user identity |
| `HealthKitManager` | Apple Health read/write, background observers |
| `StoreManager` | StoreKit 2 subscriptions, scan limits, paywall state |

### Source Layout

```
calorietracker/
├── calorietrackerApp.swift      # App entry point, environment setup
├── ContentView.swift            # 4-tab layout, HomeView, ProfileView inline
├── Models/
│   ├── UserProfile.swift        # BMR/TDEE/macro calculations
│   ├── FoodEntry.swift          # Logged food item with 13 nutrients
│   ├── Article.swift            # Educational article content
│   └── WeightEntry.swift        # Weight log entry
├── Views/
│   ├── OnboardingView.swift     # 24-step onboarding flow
│   ├── FoodResultView.swift     # AI result review & edit screen
│   ├── LearnView.swift          # Educational articles browser
│   ├── PaywallView.swift        # Subscription purchase screen
│   ├── SpinWheelView.swift      # Scratch card discount reveal
│   ├── HomeComponents/          # Week strip, macro cards, nutrition detail
│   ├── ProgressComponents/      # Charts, streak stats, weight tracking
│   └── Theme/                   # AppColors, gradients, design tokens
├── Services/
│   ├── GeminiService.swift      # Gemini 2.5 Flash API integration
│   ├── APIKeyManager.swift      # Secrets.plist loader
│   ├── AuthManager.swift        # Apple Sign-In wrapper
│   └── CloudKitService.swift    # iCloud private database sync
└── Stores/
    ├── FoodStore.swift           # @Observable food entry store
    ├── WeightStore.swift         # @Observable weight entry store
    ├── NotificationManager.swift # @Observable notification scheduler
    ├── HealthKitManager.swift    # @Observable Apple Health bridge
    └── StoreManager.swift        # @Observable StoreKit 2 manager
```

### Data Flow

```
Photo/Text Input
      │
      ▼
GeminiService.autoAnalyze() ──> Gemini 2.5 Flash API
      │
      ▼
FoodAnalysis (parsed JSON)
      │
      ▼
FoodResultView (user review/edit)
      │
      ▼
FoodStore.addEntry()
      │
      ├──> UserDefaults (local persistence)
      ├──> CloudKitService.saveFoodEntry() (iCloud sync)
      └──> HealthKitManager.writeNutrition() (Apple Health)
```

### Build & Run

```bash
# Build for simulator
xcodebuild -scheme calorietracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for physical device
xcodebuild -scheme calorietracker \
  -destination 'id=00008140-000C02942169801C' build
```

### API Key Setup

1. Create `calorietracker/Secrets.plist`
2. Add a key `GEMINI_API_KEY` with your Gemini API key as the value
3. The file is gitignored — never commit API keys

---

## Privacy Policy

**Last updated: February 9, 2026**

Fud AI ("we", "our", "the app") is developed by Apoorv Darshan. This privacy policy explains how your information is collected, used, and protected when you use Fud AI.

### Information We Collect

**Information you provide directly:**
- Name, gender, date of birth, height, weight, and body fat percentage (entered during onboarding)
- Food photos taken within the app
- Food entries and nutrition data you log
- Weight log entries
- Dietary preferences and fitness goals
- Apple ID credentials (via Sign in with Apple)

**Information collected automatically:**
- Daily scan usage counts (for subscription limit enforcement)
- App preference settings (appearance, units, notification times)

### How We Use Your Information

- **AI Food Analysis:** Food photos and text descriptions are sent to the Google Gemini API for nutritional analysis. Photos are processed in real time and are not stored on Google's servers beyond the API request.
- **Local Storage:** All food entries, weight entries, user profile data, and food photos are stored locally on your device using UserDefaults.
- **iCloud Sync:** If you sign in with Apple, your food entries (excluding photos), weight entries, and user profile are synced to your private iCloud database via CloudKit. This data is only accessible to you through your Apple ID.
- **Apple Health:** If you enable Apple Health integration, the app writes nutrition data (12 types) and body measurements to HealthKit, and reads body measurements, date of birth, and biological sex from HealthKit.
- **Subscription Management:** Subscription status is managed entirely by Apple through StoreKit. We do not process or store payment information.

### Information We Do NOT Collect

- We do **not** use any third-party analytics services (no Firebase Analytics, Mixpanel, Amplitude, or similar)
- We do **not** use any crash reporting services
- We do **not** include any advertising SDKs or ad tracking
- We do **not** track your behavior, location, or browsing activity
- We do **not** sell, share, or transfer your personal data to any third parties
- We do **not** operate any servers — all data is stored on your device or in your private iCloud account

### Data Storage & Security

| Data | Storage Location | Accessible By |
|------|-----------------|---------------|
| Food entries & photos | Device (UserDefaults) | You only |
| Food entries (no photos) | Your private iCloud database | You only (via Apple ID) |
| Weight entries | Device + your private iCloud | You only |
| User profile | Device + your private iCloud | You only |
| Food photos (for AI) | Sent to Google Gemini API | Processed in transit, not stored |
| Subscription status | Apple App Store | You + Apple |
| Health data | Apple HealthKit | You + apps you authorize |

### Data Retention

- All local data remains on your device until you delete it or uninstall the app
- iCloud data remains in your private CloudKit database until you delete it through the app or through iCloud settings
- You can delete all data (local and cloud) at any time using the "Delete All Data" option in Profile settings

### Children's Privacy

Fud AI is not directed at children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe a child under 13 has provided us with personal data, please contact us so we can delete it.

### Changes to This Policy

We may update this privacy policy from time to time. Changes will be reflected in the "Last updated" date above. Continued use of the app after changes constitutes acceptance of the updated policy.

### Contact

For privacy questions or data deletion requests, contact: **info.fudai@gmail.com**

---

## Terms of Service

**Last updated: February 9, 2026**

By downloading, installing, or using Fud AI ("the app"), you agree to these Terms of Service. If you do not agree, do not use the app.

### 1. Description of Service

Fud AI is a nutrition tracking application that uses artificial intelligence to estimate the nutritional content of food from photos and text descriptions. The app provides tools for logging meals, tracking weight, monitoring nutritional intake, and viewing educational content about nutrition and health.

### 2. AI-Powered Estimates

Nutritional information provided by Fud AI is generated by AI (Google Gemini 2.5 Flash) and is **estimated, not exact**. These estimates should be used as general guidance only. Fud AI is not a medical device and does not provide medical advice. Always consult a healthcare professional or registered dietitian for dietary decisions, especially if you have medical conditions, allergies, or specific dietary requirements.

### 3. Account & Authentication

- You may sign in using Sign in with Apple to enable cloud sync and subscription features
- You are responsible for maintaining the security of your Apple ID
- You may delete your account and all associated data at any time through the app's Profile settings

### 4. Subscriptions & Payments

- Fud AI offers a free tier (3 AI scans) and premium subscription plans (Monthly and Yearly)
- Subscriptions are auto-renewable and managed through the Apple App Store
- Payment is charged to your Apple ID account at confirmation of purchase
- Subscriptions automatically renew unless canceled at least 24 hours before the end of the current billing period
- You can manage and cancel subscriptions in your iOS Settings > Apple ID > Subscriptions
- No refunds are provided for partial subscription periods; refund requests must be directed to Apple

### 5. Acceptable Use

You agree not to:
- Use the app for any unlawful purpose
- Attempt to reverse-engineer, decompile, or disassemble the app
- Interfere with or disrupt the app's functionality
- Use the app to collect data about other users
- Redistribute, sublicense, or resell the app or its content

### 6. Intellectual Property

All content, design, code, AI integrations, educational articles, and branding in Fud AI are the intellectual property of Apoorv Darshan and are protected by copyright law. You may not reproduce, distribute, or create derivative works from any part of the app without written permission.

### 7. Health Disclaimer

Fud AI is a **nutrition tracking tool, not a medical application**. The app does not diagnose, treat, cure, or prevent any disease or medical condition. Nutritional estimates are AI-generated approximations and may not be accurate for all foods. Users with medical conditions, eating disorders, allergies, or specific dietary needs should consult qualified healthcare professionals before relying on the app's data. The minimum calorie floor of 1,200 kcal/day is a general safety guideline, not medical advice.

### 8. Apple Health Integration

By enabling Apple Health integration, you authorize the app to read and write health data as described in our Privacy Policy. You can revoke this access at any time through iOS Settings > Health > Data Access.

### 9. Limitation of Liability

To the maximum extent permitted by law, Fud AI and its developer shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, profits, or goodwill, arising from your use of the app. The app is provided "as is" without warranties of any kind.

### 10. Availability

We strive to keep Fud AI available at all times, but we do not guarantee uninterrupted access. The app requires an internet connection for AI food analysis and iCloud sync. Offline functionality is limited to viewing previously logged data.

### 11. Modifications

We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the updated terms. Material changes will be communicated through an app update.

### 12. Governing Law

These terms are governed by and construed in accordance with the laws of the United States. Any disputes shall be resolved in the courts of competent jurisdiction.

### 13. Contact

For questions about these terms, contact: **info.fudai@gmail.com**

---

## License

Copyright (c) 2026 Apoorv Darshan. All Rights Reserved.

See [LICENSE](LICENSE) for details.

---

## Contact

- **Developer:** Apoorv Darshan
- **Developer Email:** ad13dtu@gmail.com
- **App Support:** info.fudai@gmail.com
- **Issues:** [GitHub Issues](../../issues)
