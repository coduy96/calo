# Play Store Listing

Google Play Console listing copy for Fud AI Android (current: v1.0.9 / versionCode 11). Each field is in a code block for easy copy-paste. Char counts are tracked because Play Console enforces hard caps and silently truncates anything over.

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

NEW in v1.0.9: Personalize Fud AI with a Theme Color setting. Pick pink/red, red, orange, green, mint, teal, blue, or purple; the Android launcher icon follows your choice.

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

5 SPEECH-TO-TEXT ENGINES
Native Android, OpenAI Whisper, Groq, Deepgram, AssemblyAI. Choose Provider Auto, Use Device Language, or a fixed language.

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

## 4. What's New (v1.0.9)

**500 char hard cap per language.** Paste the entire block below into Play Console's "Release notes" field — it auto-routes each `<lang-tag>` block to the matching locale.

```
<en-US>
• New Theme Color setting: pick pink/red, red, orange, green, mint, teal, blue, or purple.
• Android launcher icon now follows your selected theme color.
</en-US>

<ar>
• إعداد Theme Color جديد: اختر الوردي/الأحمر أو الأحمر أو البرتقالي أو الأخضر أو النعناعي أو الأزرق المخضر أو الأزرق أو البنفسجي.
• أيقونة تشغيل Android تتبع لون الثيم المختار.
</ar>

<az-AZ>
• Yeni Theme Color ayarı: pink/qırmızı, qırmızı, narıncı, yaşıl, mint, teal, mavi və ya bənövşəyi seçin.
• Android launcher ikonu seçdiyiniz rəngi izləyir.
</az-AZ>

<de-DE>
• Neue Theme Color-Einstellung: Pink/Rot, Rot, Orange, Grün, Mint, Teal, Blau oder Lila wählen.
• Das Android-Launcher-Icon folgt jetzt deiner Theme-Farbe.
</de-DE>

<es-ES>
• Nuevo ajuste Theme Color: elige rosa/rojo, rojo, naranja, verde, menta, teal, azul o morado.
• El icono launcher de Android ahora sigue tu color elegido.
</es-ES>

<fr-FR>
• Nouveau réglage Theme Color : rose/rouge, rouge, orange, vert, menthe, teal, bleu ou violet.
• L'icône Android suit maintenant la couleur choisie.
</fr-FR>

<hi-IN>
• नया Theme Color setting: pink/red, red, orange, green, mint, teal, blue या purple चुनें.
• Android launcher icon अब आपके चुने हुए theme color को follow करता है.
</hi-IN>

<it-IT>
• Nuovo Theme Color: scegli rosa/rosso, rosso, arancione, verde, mint, teal, blu o viola.
• L'icona launcher Android ora segue il colore scelto.
</it-IT>

<ja-JP>
• 新しいTheme Color設定：ピンク/赤、赤、オレンジ、緑、ミント、ティール、青、紫を選択。
• Androidランチャーアイコンも選択色に合わせて変わります。
</ja-JP>

<ko-KR>
• 새 Theme Color 설정: 핑크/레드, 레드, 오렌지, 그린, 민트, 틸, 블루, 퍼플 선택.
• Android 런처 아이콘도 선택한 테마 색상을 따릅니다.
</ko-KR>

<nl-NL>
• Nieuwe Theme Color-instelling: kies roze/rood, rood, oranje, groen, mint, teal, blauw of paars.
• Het Android launcher-icoon volgt nu je gekozen kleur.
</nl-NL>

<pt-BR>
• Novo Theme Color: escolha rosa/vermelho, vermelho, laranja, verde, menta, teal, azul ou roxo.
• O ícone launcher do Android agora segue a cor escolhida.
</pt-BR>

<ro>
• Setare Theme Color nouă: roz/roșu, roșu, portocaliu, verde, mint, teal, albastru sau mov.
• Iconița launcher Android urmează acum culoarea aleasă.
</ro>

<ru-RU>
• Новая настройка Theme Color: розовый/красный, красный, оранжевый, зеленый, мятный, бирюзовый, синий или фиолетовый.
• Значок Android launcher теперь следует выбранному цвету.
</ru-RU>

<zh-CN>
• 新增 Theme Color 设置：可选粉红/红、红、橙、绿、薄荷、青绿、蓝、紫。
• Android 启动器图标现在会跟随所选主题色。
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
