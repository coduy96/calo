# Play Store Listing

Google Play Console listing copy for Fud AI Android (current: v1.0.7 / versionCode 9). Each field is in a code block for easy copy-paste. Char counts are tracked because Play Console enforces hard caps and silently truncates anything over.

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

NEW in v1.0.7: Per-provider speech languages, richer Coach context, Play Store update checks in About, update tab dot, plus keyboard, bottom nav, and rate-link polish.

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

Built solo because tracking calories shouldn't feel like a chore. Reach out at apoorv@fud-ai.app or on GitHub.

NOTE: Not medical advice. All nutritional estimates are AI-generated. Consult a healthcare professional before significant diet changes.

Terms: https://fud-ai.app/terms.html
Privacy: https://fud-ai.app/privacy.html
Source: https://github.com/apoorvdarshan/fud-ai
```

### Other 14 languages
English-only on Play Console — non-English Play Store browsers (ar, az-AZ, de-DE, es-ES, fr-FR, hi-IN, it-IT, ja-JP, ko-KR, nl-NL, pt-BR, ro, ru-RU, zh-CN) see the English source as fallback. The in-app UI itself is fully translated into all 14 locales via per-locale `values-{lang}/strings.xml`, so the localization gap is only on the Play Store listing surface, not inside the app.

---

## 4. What's New (v1.0.7)

**500 char hard cap per language.** Paste the entire block below into Play Console's "Release notes" field — it auto-routes each `<lang-tag>` block to the matching locale.

```
<en-US>
• Speech language per STT provider: Provider Auto, Use Device Language, or fixed.
• Coach has today/timezone plus richer meal details.
• About checks Play Store updates with a tab dot.
• Fixes: Coach tap-to-hide keyboard, bottom-nav spacing, release Play Store links from debug/onboarding.
</en-US>

<ar>
• لغة كلام لكل مزود STT: تلقائي، لغة الجهاز، أو لغة ثابتة.
• Coach يستخدم تاريخ اليوم والمنطقة الزمنية وتفاصيل وجبات أكثر.
• About يتحقق من تحديثات Play Store مع نقطة في التبويب.
• إصلاحات: إخفاء لوحة Coach بالنقر، تباعد الشريط السفلي، وروابط Play Store الصحيحة.
</ar>

<az-AZ>
• Hər STT provayderi üçün dil: Provider Auto, Device Language və ya sabit dil.
• Coach bugünkü tarix/saat qurşağı və daha zəngin yemək detallarından istifadə edir.
• About Play Store yeniləmələrini tab nöqtəsi ilə göstərir.
• Düzəlişlər: Coach klaviaturasını toxunuşla gizlətmə, alt naviqasiya aralığı, Play Store linkləri.
</az-AZ>

<de-DE>
• Sprache pro STT-Anbieter: Provider Auto, Gerätesprache oder feste Sprache.
• Coach nutzt jetzt Datum/Zeitzone und mehr Mahlzeitdetails.
• About prüft Play Store-Updates mit Tab-Punkt.
• Fixes: Coach-Tastatur per Tippen ausblenden, Bottom-Nav-Abstand, echte Play Store-Links aus Debug/Onboarding.
</de-DE>

<es-ES>
• Idioma por proveedor STT: automático, idioma del dispositivo o fijo.
• Coach usa fecha/zona horaria y más detalles de comidas.
• About busca actualizaciones de Play Store con punto en la pestaña.
• Correcciones: ocultar teclado de Coach al tocar, espaciado de barra inferior y enlaces reales de Play Store.
</es-ES>

<fr-FR>
• Langue par fournisseur STT : auto, langue de l'appareil ou langue fixe.
• Coach utilise date/fuseau horaire et plus de détails repas.
• About vérifie les mises à jour Play Store avec point d'onglet.
• Correctifs : masquer le clavier Coach au toucher, espacement nav bas, vrais liens Play Store.
</fr-FR>

<hi-IN>
• हर STT provider के लिए language: Provider Auto, Device Language, या fixed.
• Coach अब today/timezone और richer meal details use करता है.
• About Play Store updates और tab dot दिखाता है.
• Fixes: Coach keyboard tap से hide, bottom-nav spacing, debug/onboarding में real Play Store links.
</hi-IN>

<it-IT>
• Lingua per ogni provider STT: Provider Auto, lingua dispositivo o fissa.
• Coach usa data/fuso orario e più dettagli sui pasti.
• About controlla Play Store con punto nella scheda.
• Fix: nascondi tastiera Coach al tocco, spaziatura nav inferiore, link Play Store reali.
</it-IT>

<ja-JP>
• STTごとに音声言語を選択：Provider Auto、端末の言語、固定言語。
• Coachが今日/タイムゾーンと詳しい食事情報を使用。
• AboutでPlay Store更新確認とタブのドット表示。
• 修正：Coachキーボード非表示、下部ナビ間隔、debug/onboardingの実Play Storeリンク。
</ja-JP>

<ko-KR>
• STT 제공자별 언어: Provider Auto, 기기 언어, 고정 언어.
• Coach가 오늘/시간대와 더 자세한 식사 정보를 사용합니다.
• About에서 Play Store 업데이트와 탭 점을 표시합니다.
• 수정: Coach 키보드 탭 숨김, 하단 내비 간격, debug/onboarding 실제 Play Store 링크.
</ko-KR>

<nl-NL>
• Taal per STT-provider: Provider Auto, apparaattaal of vaste taal.
• Coach gebruikt datum/tijdzone en rijkere maaltijdgegevens.
• About controleert Play Store-updates met tabpunt.
• Fixes: Coach-toetsenbord verbergen bij tik, bottom-nav spacing, echte Play Store-links.
</nl-NL>

<pt-BR>
• Idioma por provedor STT: Provider Auto, idioma do dispositivo ou fixo.
• Coach usa data/fuso horário e mais detalhes das refeições.
• About verifica Play Store com ponto na aba.
• Correções: esconder teclado do Coach ao tocar, espaçamento da barra inferior, links reais da Play Store.
</pt-BR>

<ro>
• Limbă pentru fiecare furnizor STT: Provider Auto, limba dispozitivului sau fixă.
• Coach folosește data/fusul orar și detalii mai bogate despre mese.
• About verifică Play Store cu punct pe tab.
• Fixuri: ascunde tastatura Coach la atingere, spațiere nav jos, linkuri reale Play Store.
</ro>

<ru-RU>
• Язык для каждого STT: Provider Auto, язык устройства или фиксированный.
• Coach учитывает дату/часовой пояс и больше деталей еды.
• About проверяет Play Store и показывает точку на вкладке.
• Исправления: скрытие клавиатуры Coach по тапу, отступы нижней навигации, реальные Play Store ссылки.
</ru-RU>

<zh-CN>
• 每个 STT 提供商可选语言：Provider Auto、设备语言或固定语言。
• Coach 使用当天/时区和更丰富的餐食细节。
• About 检查 Play Store 更新并显示标签圆点。
• 修复：点击隐藏 Coach 键盘、底部导航间距、debug/onboarding 使用真实 Play Store 链接。
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
