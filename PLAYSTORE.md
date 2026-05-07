# Play Store Listing

Google Play Console listing copy for Fud AI Android (current: v1.1.0 / versionCode 15). Each field is in a code block for easy copy-paste. Char counts are tracked because Play Console enforces hard caps and silently truncates anything over.

**Where to paste each field in Play Console:**
- App name / Short description / Full description → Grow → Store presence → **Main store listing** (default English) and Grow → Store presence → **Custom store listings** → Manage translations (per-language overrides)
- What's new → **Releases → Production / Closed testing → Create new release → Release notes** field (paste the entire `<lang-tag>` block; Play Console parses tags automatically)

---

## 1. App Name

**30 char hard cap per language.** Brand name stays as `Fud AI` untranslated; the descriptor after the dash is what gets localized. English-only on Play Console — non-English Play Store browsers see the English source as fallback.

### English (en-US) — 24 chars
```
Fud AI - Calorie Tracker
```

---

## 2. Short Description

**80 char hard cap per language. Cannot include price/promotion keywords ("free", "discount", "sale", "best", "#1", etc.) — Play Console will block promotion of the listing.** Live Play Store currently has "Snap, speak, or type a meal. AI logs the calories. Free & open source." which triggers the warning; replacement below drops "Free" while keeping the same rhythm. English-only on Play Console — non-English Play Store browsers see the English source as fallback.

### English (en-US) — 63 chars
```
Snap, speak, or type a meal. AI logs the calories. Open source.
```

---

## 3. Full Description

**4000 char hard cap per language.** This is the long-form "About this app" copy. English-only on Play Console — non-English Play Store browsers see the English source as fallback (deliberate decision; the in-app UI is fully translated via per-locale `values-{lang}/strings.xml` so users still get a localized experience once installed).

### English (en-US)
```
Fud AI makes calorie tracking effortless with AI-powered food recognition. Snap a photo, speak it, or type it — get instant nutrition: calories, protein, carbs, fats, and 9 micronutrients.

NEW in v1.1.0: Food logs can now be sorted by latest meal order, serving units are easier to edit, Gemini speech-to-text is available, and GPT-5/OpenAI requests are fixed.

Free, open source, privacy-first. Bring your own API key. All data stays on your device.

HOW TO USE
1) Set up your profile with goals + body stats
2) Snap, speak, type, or manually enter a meal — review and save
3) Ask Coach anything: trends, predictions, advice
4) Track progress on charts and home screen widgets

4 WAYS TO LOG A MEAL
• Photo — AI identifies the food and returns nutrition
• Voice — 5 STT engines with per-provider language selection
• Text — describe in plain language, AI parses it
• Manual Entry — name + calories + macros + meal type, no AI needed

BODY COMPOSITION TRACKING
Log body fat % over time, set a goal %, see it graphed alongside weight on the unified Progress chart. Health Connect sync auto-imports samples from Withings, Renpho, Samsung Health, Google Fit. "Use Body Fat for BMR" toggles Katch-McArdle ↔ Mifflin-St Jeor without losing the value.

13 AI PROVIDERS
Google Gemini, OpenAI, Anthropic Claude, xAI Grok, Groq, OpenRouter, Together AI, Hugging Face, Fireworks AI, DeepInfra, Mistral, Ollama (local), or any OpenAI-compatible endpoint. Switch anytime. OpenRouter defaults to a free vision model — test without loading credits. Keys stored encrypted (AES-256). Add Custom AI Instructions to send region, diet, or brand context with every request. Set a Fallback Provider so the app auto-retries on overload or rate-limit errors.

6 SPEECH-TO-TEXT ENGINES
Native Android, Gemini, OpenAI Whisper, Groq, Deepgram, AssemblyAI. Choose Provider Auto, Use Device Language, or a fixed language.

COACH (TOOL CALLING)
Multi-turn chat that sees your profile, weight, body fat, and food log. Ask "what was my weight in March?" or "how's my protein this week?" — Coach pulls the date range it needs via 5 on-demand tools. It now understands today's date/timezone and richer meal details. Goal-aware chips for Lose / Gain / Maintain.

SMART DAILY REMINDERS
Log Weight, Log Body Fat, Streak, Daily Summary — all skip firing on days you've already logged, so fully-tracking users get effectively zero pings.

PERSONALIZED GOALS
BMR via Katch-McArdle (with body fat) or Mifflin-St Jeor. TDEE with 6 activity levels. Auto-calculated calorie + protein + carbs + fat targets — fully customizable.

PROGRESS
Unified Weight / Body Fat chart with trend lines + goal overlays. Calorie trend vs goal. Macro averages over 1W, 1M, 3M, 6M, 1Y, All Time.

WIDGETS
Calorie widget (pink-gradient ring with today's calories + macros) and Protein widget — both in Small 2x2 and Medium 4x2, refresh the moment you log a meal.

SAVED MEALS + SEARCH
Recents, Frequent, and Favorites tabs. Search bar filters each tab separately — substring, case-insensitive, diacritic-insensitive.

15 LANGUAGES
Auto-selected by phone language: English, Spanish, French, German, Italian, Portuguese (BR), Dutch, Russian, Japanese, Korean, Chinese, Hindi, Arabic, Romanian, Azerbaijani.

PRIVACY FIRST
No account, no sign-in, no cloud sync, no analytics, no ads, no tracking. Local-only. MIT licensed.

HEALTH CONNECT
Two-way sync for nutrition, weight, body fat. Macros + 9 micronutrients per meal. Edits and deletes sync back.

Built solo because tracking calories shouldn't feel like a chore. Reach out at apoorv@fud-ai.app, GitHub, or Instagram @fudai.app.

NOTE: Not medical advice. All nutritional estimates are AI-generated. Consult a healthcare professional before significant diet changes.

Terms: https://fud-ai.app/terms.html
Privacy: https://fud-ai.app/privacy.html
Source: https://github.com/apoorvdarshan/fud-ai
```

### Other 14 languages
English-only on Play Console — non-English Play Store browsers (ar, az-AZ, de-DE, es-ES, fr-FR, hi-IN, it-IT, ja-JP, ko-KR, nl-NL, pt-BR, ro, ru-RU, zh-CN) see the English source as fallback. The in-app UI itself is fully translated into all 14 locales via per-locale `values-{lang}/strings.xml`, so the localization gap is only on the Play Store listing surface, not inside the app.

---

## 4. What's New (v1.1.0)

**500 char hard cap per language.** Paste the entire block below into Play Console's "Release notes" field — it auto-routes each `<lang-tag>` block to the matching locale.

```
<en-US>
• New food log sort option for latest meal order.
• Easier serving unit edits, Gemini speech-to-text, and GPT-5/OpenAI fixes.
</en-US>

<ar>
• خيار جديد لترتيب سجل الطعام حسب أحدث وجبة.
• تحسين تعديل وحدات الحصة، وإضافة Gemini للصوت، وإصلاح GPT-5/OpenAI.
</ar>

<az-AZ>
• Yemək tarixçəsini ən son yemək sırasına görə çeşidləmə əlavə edildi.
• Porsiya vahidləri, Gemini səs mətni və GPT-5/OpenAI düzəldildi.
</az-AZ>

<de-DE>
• Neue Sortierung für Essenslogs nach neuester Mahlzeit.
• Einfachere Portionseinheiten, Gemini-Spracheingabe und GPT-5/OpenAI-Fixes.
</de-DE>

<es-ES>
• Nueva opción para ordenar comidas por registro más reciente.
• Mejor edición de unidades, voz con Gemini y correcciones GPT-5/OpenAI.
</es-ES>

<fr-FR>
• Nouveau tri du journal par repas les plus récents.
• Unités plus faciles à modifier, voix Gemini et correctifs GPT-5/OpenAI.
</fr-FR>

<hi-IN>
• Food log को latest meal order से sort करने का नया option.
• Serving unit edit बेहतर, Gemini speech-to-text और GPT-5/OpenAI fixes.
</hi-IN>

<it-IT>
• Nuovo ordinamento del diario per pasti più recenti.
• Unità porzione più semplici, voce Gemini e correzioni GPT-5/OpenAI.
</it-IT>

<ja-JP>
• 最新の食事順でフードログを並べ替えできます。
• 単位編集、Gemini音声入力、GPT-5/OpenAIの修正を追加。
</ja-JP>

<ko-KR>
• 최신 식사 순서로 음식 기록을 정렬할 수 있습니다.
• 단위 편집, Gemini 음성 입력, GPT-5/OpenAI 수정.
</ko-KR>

<nl-NL>
• Nieuwe sortering voor logs op nieuwste maaltijd.
• Portie-eenheden makkelijker bewerken, Gemini-spraak en GPT-5/OpenAI-fixes.
</nl-NL>

<pt-BR>
• Nova ordenação do diário por refeição mais recente.
• Unidades melhores, voz Gemini e correções para GPT-5/OpenAI.
</pt-BR>

<ro>
• Sortare nouă a jurnalului după cele mai recente mese.
• Unități mai ușor de editat, voce Gemini și remedieri GPT-5/OpenAI.
</ro>

<ru-RU>
• Новая сортировка журнала по последним приемам пищи.
• Улучшены единицы порций, Gemini для речи и исправления GPT-5/OpenAI.
</ru-RU>

<zh-CN>
• 新增按最新餐次排序食物日志。
• 优化份量单位编辑，加入 Gemini 语音，并修复 GPT-5/OpenAI。
</zh-CN>
```

---

## 5. Categorization

```
App category: Health & Fitness
Tags: Calorie tracker, Nutrition, AI, Food tracker
```

## 6. Contact details

```
Email: apoorv@fud-ai.app
Phone: (omit — optional, US-only enforcement)
Website: https://fud-ai.app
Privacy policy: https://fud-ai.app/privacy.html
```

## 7. App content declarations

These are one-time setup in Play Console → Policy → App content. Don't drift from these answers across submissions:

- **Privacy policy URL**: https://fud-ai.app/privacy.html
- **App access**: All functionality available without restrictions
- **Ads**: No
- **Content rating**: Everyone (E)
- **Target audience**: 13+
- **News app**: No
- **COVID-19 contact tracing**: No
- **Data safety**: All processing on-device. No data collected/shared. API keys stored in EncryptedSharedPreferences. Encryption in transit when calling AI provider APIs (HTTPS). User can request deletion via in-app "Delete All Data" — no server data exists.
- **Government app**: No
- **Financial features**: No
- **Health features**: Yes — fitness/nutrition tracking. Local-only.
