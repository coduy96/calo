# Voidpen 14-Day First-Customer Sprint
**Sprint window: Jun 7–20, 2026 · Cash budget: ≤$180 + $100 Apple Ads credit · Target: 2–4 real paying customers**

## The play
Fix the money plumbing today — Small Business Program (70%→85%), yearly cut to $29.99, a 2-option paywall (monthly hidden), and PPP pricing in 10 emerging storefronts — all zero-cost, zero-review changes that go live within hours. Then spend days 1–5 manufacturing the trust the listing lacks: 12–15 honest friend ratings concentrated on the US storefront, while batch-filmed faceless TikTok demos and $30–50 SEA nano-creator deals start the organic flywheel. Only when ≥5 US ratings exist do we light the $100 Apple Ads credit on exact-match keywords split US vs AU/CA/UK, where CPIs run ~45% cheaper. Vietnam is the unfair advantage: native-language content, "đếm calo" at traffic 8.1/difficulty 5.7, and 25.000₫/week pricing — the single fastest path to customer #1. Everything is attributed (RevenueCat Apple Ads integration + `ct=` campaign links), so by day 14 we know exactly which channel buys a trial cheapest.

## Funnel math

| Channel | Spend | Taps/Views | Installs | Onboarding completes | Trial starts | Paid | First $ lands |
|---|---|---|---|---|---|---|---|
| **ASA C1+C2** (days 6–12, $16/day) | $100 credit | ~90 taps (blended CPT ~$1.10) | ~32 (35% CVR: 46% benchmark, haircut for thin ratings) | ~20–24 reach paywall (65–75% through 16 steps) | 3–4 (8–12% hard-paywall rate) | 1–2 (39.9% H&F median trial→paid) | Day 11–14 (ads live day 6 + trial +3d) |
| **TikTok organic + 3–5 SEA creators** | $150 creators + $30 food | 25+ posts, 3–5 creator videos | 20–60 via `ct=` links | 14–40 | 2–5 | 1–2 (VN at 25.000₫/wk converts easiest) | Day 8–14 |
| **Friends/family review campaign** | $0 | 22–25 asks | 12–15 install + rate | n/a (cancel trials by design) | — | 0–1 genuine keeper | Day 4–7 if any |
| **Total** | **~$180 cash + $100 credit** | | **~60–105** | | **6–10 real trials by day 10** | **2–4 by day 14** (pessimistic 1, optimistic 6) | |

Reality check: a yearly conversion nets **$25.49** post-SBP, a weekly **$4.24**/cycle. Expected cost per first payer ~$60–110 via ASA, near-$0 via VN. This sprint buys proof and channel data, not profit — that's correct at this stage.

## Set these numbers today

| Setting | Exact value | How |
|---|---|---|
| Weekly `voidpen.plus.weekly` (6770928219) | **Keep $4.99**, 3-day trial, NOT preselected — "Try 3 days free, then $4.99/week" | No change |
| Yearly `voidpen.plus.yearly` (6770922464) | **Cut $39.99 → $29.99**, 3-day trial, preselected, "$2.49/mo · SAVE 88% · Best value" | `asc subscriptions pricing prices set` — immediate, no review |
| Monthly `voidpen.plus.monthly` (6770926195) | **Remove from paywall** (RC offering edit — paywall is dynamic, no app update); keep SKU dormant in ASC | RC dashboard, 5 min |
| Trial config | **3 days FREE_TRIAL on everything** — verified already set in all 150 territory rows; do NOT extend to 7 | No change |
| PPP (10 storefronts, weekly/yearly) | VN 25.000₫/249.000₫ · IN ₹99/₹999 · BR R$9,90/R$79,90 · MX $29/$249 · ID Rp29.000/Rp249.000 · PH ₱79/₱699 · TR ₺49/₺449 · TH ฿49/฿449 · EG E£49/E£449 · MY RM6.90/RM59.90 | asc-ppp-pricing skill; all decreases = instant |
| Small Business Program | Enroll today: proceeds 70% → **85%** ($3.50→$4.24/wk, $20.99→$25.49/yr at $29.99) | 5-min form, approval in days |
| ASA C1 `VP-US-Exact` | $8/day · 12 exact keywords · bids $1.25–1.75 · Search Match OFF · no CPA goal · **launch day 6, gated on ≥5 US ratings** | Console |
| ASA C2 `VP-AU/CA/UK-Exact` | $8/day · same 12 keywords at $0.80–1.15 (~65% of US bids) | Console |
| Attribution | RC Apple Ads integration toggle today + `enableAdServicesAttributionTokenCollection()` in v1.0.3 | Before dollar one |
| Promotional text (153 chars, live instantly) | "Point your camera at any meal — calories, protein, carbs & fat in seconds. Try everything free for 3 days. No account required. Syncs with Apple Health." | ASC, no review |

## Day-by-day (Day 1–14)

**Day 1 — Sat Jun 7 (dashboards day, ~3h)**
- 🤖 Reprice via `asc`: yearly → $29.99 US + PPP import for all 10 storefronts (VN first); set promotional text.
- 🤖 Remove monthly package from RC current offering; enable RC Apple Ads attribution integration.
- 👤 Enroll Small Business Program + claim $100 Apple Ads credit (link **top-level** ASC account, add card, **write down the credit expiry from the Billing page**).
- 👤 Send review Wave 1 (8–10 US-storefront-heavy contacts, Template A) + TestFlight-migration messages (delete beta → install from App Store).
- 👤 Create TikTok **Business** @voidpen.app (+ same-handle IG/YT); bio = ASC campaign link `ct=tiktok-bio`.

**Day 2 — Sun Jun 8 (build + film)**
- 🤖 Build v1.0.3 in ONE submission: title "Voidpen: AI Calorie Tracker", subtitle "Food Scanner & Macro Counter", VN locale gets "đếm calo", new frame-1 screenshot (camera → "520 kcal · 38g protein" chip), paywall copy ("Cancel anytime · No charge before day 3"), AdServices token call, 3-line review-prompt flag fix.
- 🤖 Compile 30-handle SEA nano-creator shortlist (5k–50k followers, EN-posting PH/MY/SG, ≥3% engagement) + personalized DMs.
- 👤 Batch-film scripts #1, #2, #4, #6, #8 — the week's one big time block (3–4h kitchen session).
- 👤 Walk Wave 1 friends through install + onboarding; remind them to cancel trial right after subscribing.

**Day 3 — Mon Jun 9**
- 🤖 Submit v1.0.3 for review via `asc`; collect Google-page-1 "best calorie app reddit" / "cal ai alternative reddit" thread list.
- 👤 Post #1 + #4 (11:30 / 19:30 ICT), cross-post natively to Shorts/Reels (~19:00–21:00 US ET); reply to every comment in hour 1.
- 👤 Send first 10 creator DMs; start burner FYP account (engage only calorie-deficit content).
- 👤 Set up @voidpen.vn sister account (`ct=tiktok-vn`).

**Day 4 — Tue Jun 10**
- 🤖 Translate the 10 scripts to Vietnamese with VN hooks ("Chụp 1 tấm ảnh là biết tô phở này bao nhiêu calo"); draft the VN FB group story post.
- 👤 Post #2 + #6 (EN) + first VN post; send **Template B** to any Wave-1 friend with 2+ days of real use — first ratings land today/tomorrow.
- 👤 10 more creator DMs.

**Day 5 — Wed Jun 11**
- 🤖 Count ratings per storefront; stage both ASA campaigns (exact keyword/bid tables ready to paste); draft replies for any reviews.
- 👤 Post #3 + #8; send review Wave 2 (UK/CA/AU + VN); final 10 creator DMs.
- 👤 Post the "mình tự làm app đếm calo bằng AI" story in 2–3 VN FB weight-loss/gym groups (VND pricing already live).

**Day 6 — Thu Jun 12**
- 👤 **GATE CHECK: ≥5 US ratings → launch ASA C1 + C2 ($16/day).** If <5, hold and push top-up review asks instead — a 0-star ad unit taxes every tap ~30–40%.
- 👤 Post #5 (AI vs Vietnamese street food) + re-cut of best performer; close first creator deals ($30 offer, $50 cap, +$10 for Spark code, pay 24h after post).
- 🤖 Reply to every review in ASC; watch RC for first trial events; check v1.0.3 approval (expect today/tomorrow).

**Day 7 — Fri Jun 13**
- 🤖 Week-1 readout: ratings by storefront, ASA spend/taps/installs, trials by `ct=` and keyword.
- 👤 Post #9 (solo-dev underdog — "be my first paying customer and I'll pin you forever"; single best first-customer bet) + #7 (accuracy test); 48h follow-up to silent creators.

**Day 8 — Sat Jun 14**
- 🤖 ASA hygiene: pause any keyword at $6 spend/0 installs (US) or $4 (AU/CA/UK); +20% bid on keywords with an install and <20% impression share.
- 👤 Post #10 + guess-the-calories v2; drop 2–3 transparent dev comments on the Reddit thread list ("full disclosure, I built Voidpen") — never promo-post in weight-loss subs.

**Day 9 — Sun Jun 15**
- 🤖 Publish SEO blog post on voidpen.com/blogs (honest "Cal AI alternatives / photo calorie counter" comparison including Voidpen).
- 👤 Re-post week's winner with a new hook + video-reply to the best comment; start Template B drip to Wave 2 (expect 4–6 more ratings days 9–11).

**Day 10 — Mon Jun 16**
- 🤖 Mid-flight ASA shift: move budget to whichever campaign has the lower RC cost-per-trial.
- 👤 Post 1–2 (start numbered series of the winning format); review creator drafts — enforce scan result on screen by second 3.

**Day 11 — Tue Jun 17**
- 👤 Creator videos go live (verify `ct=cr-[handle]` bio links; pay via Wise/PayPal 24h after posting); continue Wave 2 Template B.
- 🤖 Watch ASC Sources → Campaigns for `ct=` installs; reply to new reviews. First ASA trials from days 7–8 convert to **PAID** around now.

**Day 12 — Wed Jun 18**
- 🤖 ASA keyword pass #2 (same kill/scale rules); reconcile trial→paid conversions in RC — first payers expected days 11–14.
- 👤 Post 1–2; polite follow-up to review non-responders + 3–5 top-up asks (never >2–3 new ratings/day/storefront).

**Day 13 — Thu Jun 19**
- 🤖 Reconcile payers by channel, cost per trial, ASA credit burn-down vs the expiry date noted on Day 1.
- 👤 Post 1–2 (VN account: daily street-food scans are near-zero effort); second VN FB story in different groups.

**Day 14 — Fri Jun 20**
- 🤖 Sprint readout + week-3 plan: scale the cheapest cost-per-trial channel; queue 3 hook variants of the best video; explicitly defer all pricing A/Bs (n still too small).
- 👤 Pin top 3 videos; thank every reviewer via ASC replies; confirm SBP approval (85% rate active).

## Watch these numbers

| Metric | On track | Kill threshold | Scale threshold |
|---|---|---|---|
| **US-storefront ratings** | ≥5 by Day 6 (the ASA gate), 10–15 total by Day 14 | <3 by Day 7 → keep ads OFF, escalate top-up asks | ≥5 US → light the credit same day |
| **ASA cost-per-trial** (RC-attributed) | ≤$35 blended | 0 trials after $60 spend → kill US, go 100% AU/CA/UK; >$35 after $80 → stop, bank remaining credit | Any keyword with a trial → +20% bid; campaign cost-per-trial <$25 → take the other campaign's budget |
| **Real trial starts, all channels** | ≥5 by Day 10 | <2 by Day 10 → traffic isn't the leak; audit the 16-step onboarding drop-off before another dollar | ≥10 by Day 10 → trial volume is the whole game; double posting + creator count |
| **Trial→paid** (3-day clock; verdict on trials started by Day 11) | ~40% (H&F median 39.9%) | <20% on ≥5 trials → paywall trust problem (copy/price framing), not traffic | ≥40% → every channel is profitable on yearly conversions; pour into volume |

## What we deliberately ignore for 30 days
- **Product Hunt** (max half a day, once, for the backlink) — audience is founders not dieters; spike fades in 48h; verified no-payer channel for niche consumer apps.
- **X build-in-public as a strategy** — verifiably 6–8 weeks to a first customer with zero audience; keep a lightweight account for credibility only.
- **Promo posts in weight-loss subreddits** (r/loseit, r/CICO, r/intermittentfasting) — self-promo bans; account flags would kill the Reddit comment channel that actually converts.
- **US/UK creators ($50–100+) and TikTok Smart+ at $50/day** — these are the proven *next* steps, funded by first revenue, not this budget; running them now violates the $200/mo ceiling.
- **All pricing experiments** (weekly $5.99 bump, paid intro offers, PPO tests) — n = 2 trials; nothing is statistically testable before ~30 real trials.
- **ASA Discovery campaigns, CPA goals, audience refinement** — statistically dead under 30 installs; they throttle or fragment a tiny account.
- **New product features and retention work** beyond the 3-line review-prompt fix — distribution is the bottleneck, not the product; every dev hour spent on features this month is a marketing hour burned.
- **Anything in the review DO-NOT list** — paid/incentivized/swapped/templated reviews, custom rating UIs, rating resets: each is a documented Developer Program expulsion risk, and an expulsion ends the business entirely.