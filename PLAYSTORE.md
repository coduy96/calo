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

NEW in v1.0.7: Per-provider speech languages, richer Coach context, Play Store update checks in About, plus a tab dot when an update is available.

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
• Pick a speech language per STT provider: Provider Auto, Use Device Language, or a fixed language.
• Coach now has today/timezone plus richer meal details for better answers.
• About checks Play Store updates and shows a tab dot when one is available.
</en-US>

<ar>
• اختر لغة الكلام لكل مزود STT: تلقائي من المزود، لغة الجهاز، أو لغة ثابتة.
• Coach يعرف الآن تاريخ اليوم والمنطقة الزمنية وتفاصيل وجبات أكثر لإجابات أدق.
• About يتحقق من تحديثات Play Store ويعرض نقطة عند توفر تحديث.
</ar>

<az-AZ>
• Hər STT provayderi üçün nitq dili seçin: Provider Auto, Device Language və ya sabit dil.
• Coach daha yaxşı cavablar üçün bugünkü tarix/saat qurşağı və daha zəngin yemək detalları görür.
• About Play Store yeniləmələrini yoxlayır və yeniləmə olanda tab nöqtəsi göstərir.
</az-AZ>

<de-DE>
• Sprache pro STT-Anbieter wählen: Provider Auto, Gerätesprache oder feste Sprache.
• Coach kennt jetzt Datum/Zeitzone und mehr Mahlzeitdetails für bessere Antworten.
• About prüft Play Store-Updates und zeigt einen Punkt im Tab, wenn ein Update verfügbar ist.
</de-DE>

<es-ES>
• Elige idioma por proveedor STT: automático del proveedor, idioma del dispositivo o idioma fijo.
• Coach ahora usa fecha/zona horaria y más detalles de comidas para mejores respuestas.
• About busca actualizaciones de Play Store y muestra un punto en la pestaña si hay una.
</es-ES>

<fr-FR>
• Choisis la langue par fournisseur STT : auto fournisseur, langue de l'appareil ou langue fixe.
• Coach utilise maintenant la date, le fuseau horaire et plus de détails repas pour mieux répondre.
• About vérifie les mises à jour Play Store et affiche un point dans l'onglet si disponible.
</fr-FR>

<hi-IN>
• हर STT प्रोवाइडर के लिए भाषा चुनें: Provider Auto, Device Language, या fixed language.
• Coach अब बेहतर जवाबों के लिए आज की तारीख/टाइमज़ोन और ज्यादा meal details समझता है.
• About Play Store updates जांचता है और update available होने पर tab dot दिखाता है.
</hi-IN>

<it-IT>
• Scegli la lingua per ogni provider STT: Provider Auto, lingua del dispositivo o lingua fissa.
• Coach ora usa data/fuso orario e più dettagli sui pasti per risposte migliori.
• About controlla gli aggiornamenti Play Store e mostra un punto nella scheda se disponibili.
</it-IT>

<ja-JP>
• STTプロバイダーごとに音声言語を選択：Provider Auto、端末の言語、固定言語。
• Coachは今日の日付/タイムゾーンと詳しい食事情報を使い、回答精度が向上。
• AboutでPlay Store更新を確認し、更新があるとタブにドットを表示。
</ja-JP>

<ko-KR>
• STT 제공자별 음성 언어 선택: Provider Auto, 기기 언어, 고정 언어.
• Coach가 오늘 날짜/시간대와 더 자세한 식사 정보를 사용해 답변을 개선합니다.
• About에서 Play Store 업데이트를 확인하고, 업데이트가 있으면 탭에 점을 표시합니다.
</ko-KR>

<nl-NL>
• Kies per STT-provider een taal: Provider Auto, apparaattaal of vaste taal.
• Coach gebruikt nu datum/tijdzone en rijkere maaltijdgegevens voor betere antwoorden.
• About controleert Play Store-updates en toont een tabpunt wanneer er een update is.
</nl-NL>

<pt-BR>
• Escolha idioma por provedor STT: Provider Auto, idioma do dispositivo ou idioma fixo.
• Coach agora usa data/fuso horário e mais detalhes das refeições para responder melhor.
• About verifica atualizações da Play Store e mostra um ponto na aba quando houver uma.
</pt-BR>

<ro>
• Alege limba pentru fiecare furnizor STT: Provider Auto, limba dispozitivului sau limbă fixă.
• Coach folosește acum data/fusul orar și detalii mai bogate despre mese pentru răspunsuri mai bune.
• About verifică actualizări Play Store și afișează un punct pe tab când există una.
</ro>

<ru-RU>
• Выбирайте язык для каждого STT-провайдера: Provider Auto, язык устройства или фиксированный язык.
• Coach теперь учитывает дату/часовой пояс и больше деталей еды для лучших ответов.
• About проверяет обновления Play Store и показывает точку на вкладке, если есть обновление.
</ru-RU>

<zh-CN>
• 可为每个 STT 提供商选择语音语言：Provider Auto、设备语言或固定语言。
• Coach 现在使用当天日期/时区和更丰富的餐食细节，回答更准确。
• About 会检查 Play Store 更新，有更新时在标签栏显示圆点。
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
