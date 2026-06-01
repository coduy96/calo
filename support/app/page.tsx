import type { Metadata, Viewport } from "next";
import Image from "next/image";
import Link from "next/link";
import { LandingEnhancements } from "@/components/landing-enhancements";
import "./landing.css";

/*
 * voidpen.com landing page.
 * Ported pixel-for-pixel from the Claude Design HTML/CSS handoff
 * ("voidpen-landing"). Styles live in ./landing.css, scoped under
 * `.vp-landing`. Interactivity (sticky nav, mobile menu, scroll reveal)
 * is progressively enhanced by <LandingEnhancements />.
 *
 * Every "Download on the App Store" badge links to the live listing.
 * Region-agnostic URL (no /ma/ etc.) so visitors land in their own store.
 */
const APP_STORE_URL = "https://apps.apple.com/app/id6770921845";

export const metadata: Metadata = {
  title: { absolute: "voidpen — Hit Your Macros, Effortlessly" },
  description:
    "Snap, speak, scan or type. voidpen logs your food in seconds, tracks every macro, and coaches you to your goals with AI.",
  alternates: { canonical: "https://voidpen.com" },
};

export const viewport: Viewport = {
  themeColor: "#F6EFE4",
};

function AppStoreBadge({
  href,
  ariaLabel = "Download on the App Store",
}: {
  href: string;
  ariaLabel?: string;
}) {
  return (
    <a href={href} className="appstore" aria-label={ariaLabel}>
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M16.36 12.78c-.02-2.2 1.8-3.26 1.88-3.31-1.02-1.5-2.62-1.7-3.19-1.73-1.36-.14-2.65.8-3.34.8-.69 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.62 1.11 8.78.73 1.06 1.6 2.25 2.74 2.2 1.1-.04 1.51-.71 2.85-.71 1.32 0 1.71.71 2.87.69 1.19-.02 1.94-1.08 2.66-2.14.84-1.23 1.19-2.42 1.21-2.48-.03-.01-2.32-.89-2.34-3.52ZM14.17 6.0c.61-.74 1.02-1.77.91-2.8-.88.04-1.94.59-2.57 1.32-.56.65-1.06 1.69-.93 2.69.98.08 1.98-.5 2.59-1.21Z" />
      </svg>
      <span className="as-text">
        <span className="as-small">Download on the</span>
        <span className="as-big">App Store</span>
      </span>
    </a>
  );
}

function Check() {
  return (
    <span className="chk">
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M5 13l4 4 10-11" />
      </svg>
    </span>
  );
}

export default function Home() {
  return (
    <div className="vp-landing">
      <noscript>
        {/* If JS is unavailable, never leave reveal content hidden. */}
        <style>{`.vp-landing .reveal{opacity:1 !important;transform:none !important}`}</style>
      </noscript>

      {/* ================= NAV ================= */}
      <header className="nav" id="nav">
        <div className="wrap nav-inner">
          <a className="brand" href="#top">
            <span className="brand-mark">
              <Image
                src="/voidpen-logo.png"
                alt="voidpen logo"
                width={40}
                height={40}
              />
            </span>
            <span className="brand-name">voidpen</span>
          </a>
          <nav className="nav-links">
            <a href="#features">Features</a>
            <a href="#how">How it works</a>
            <a href="#coach">AI Coach</a>
            <a href="#faq">FAQ</a>
            <Link href="/blogs">Blog</Link>
          </nav>
          <div className="nav-cta">
            <AppStoreBadge href={APP_STORE_URL} />
          </div>
          <button className="nav-toggle" id="navToggle" aria-label="Open menu">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.2"
              strokeLinecap="round"
            >
              <path d="M4 7h16M4 12h16M4 17h16" />
            </svg>
          </button>
        </div>
      </header>
      <div className="mobile-menu" id="mobileMenu">
        <a href="#features">Features</a>
        <a href="#how">How it works</a>
        <a href="#coach">AI Coach</a>
        <a href="#faq">FAQ</a>
        <Link href="/blogs">Blog</Link>
        <AppStoreBadge href={APP_STORE_URL} />
      </div>

      <main id="top">
        {/* ================= HERO ================= */}
        <section className="hero">
          <div className="wrap hero-grid">
            <div className="hero-copy">
              <p className="eyebrow reveal">AI nutrition tracking</p>
              <h1 className="display reveal d1">
                Hit your
                <br />
                <span className="line2">macros</span>
                <br />
                effortlessly
              </h1>
              <p className="lead reveal d2">
                Calories, protein, carbs and fat at a glance. Snap a photo, say
                it out loud, or scan a label — <span className="brand-name">voidpen</span>{" "}
                does the math.
              </p>
              <div className="hero-actions reveal d2">
                <AppStoreBadge href={APP_STORE_URL} />
                <a href="#features" className="btn btn-ghost">
                  See how it works
                </a>
              </div>
              <div className="hero-proof reveal d3">
                <div className="avatars">
                  <span
                    style={{ backgroundImage: "url('https://i.pravatar.cc/80?img=32')" }}
                  />
                  <span
                    style={{ backgroundImage: "url('https://i.pravatar.cc/80?img=12')" }}
                  />
                  <span
                    style={{ backgroundImage: "url('https://i.pravatar.cc/80?img=45')" }}
                  />
                  <span
                    style={{ backgroundImage: "url('https://i.pravatar.cc/80?img=5')" }}
                  />
                </div>
                <div className="proof-text">
                  <div className="stars">★★★★★</div>
                  <span>
                    <strong>4.9</strong> from <strong>12,000+</strong> reviews
                  </span>
                </div>
              </div>
            </div>

            {/* Real app home screen, framed in a phone */}
            <div className="hero-stage">
              <div className="hero-glow" />
              <div className="hero-phone reveal d2">
                <Image
                  src="/screenshots/hero-home.png"
                  alt="voidpen app home screen — calorie ring and macro breakdown"
                  width={1206}
                  height={2622}
                  priority
                  sizes="(max-width: 480px) 80vw, 300px"
                />
              </div>
            </div>
          </div>
        </section>

        {/* ================= TRUST STATS ================= */}
        <section className="stats">
          <div className="wrap">
            <div className="stats-inner reveal">
              <div className="stat">
                <div className="num grad-text">4.9★</div>
                <div className="lbl">App Store rating</div>
              </div>
              <div className="stat">
                <div className="num">2M+</div>
                <div className="lbl">Meals logged</div>
              </div>
              <div className="stat">
                <div className="num">5s</div>
                <div className="lbl">Avg. log time</div>
              </div>
              <div className="stat">
                <div className="num">600k+</div>
                <div className="lbl">Foods in database</div>
              </div>
            </div>
          </div>
        </section>

        {/* ================= SCREENSHOT GALLERY ================= */}
        <section className="sec gallery" id="features">
          <div className="wrap sec-head">
            <p className="eyebrow reveal">Built for real life</p>
            <h2 className="display reveal d1">
              Everything you need,
              <br />
              <span className="accent-text">nothing you don&apos;t</span>
            </h2>
            <p className="lead reveal d2">
              A complete look at the app — log food, track macros, chat with your
              coach and watch real progress add up.
            </p>
          </div>
          <div className="gallery-rail reveal d1">
            <div className="shot">
              <Image
                src="/screenshots/screen-macros.png"
                alt="Macro dashboard with calorie ring"
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-input.png"
                alt="Multiple ways to log food"
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-coach.png"
                alt="AI coach chat"
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-progress.png"
                alt="Progress charts"
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-widgets.png"
                alt="Home screen widgets"
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
          </div>
          <p className="gallery-hint reveal">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            >
              <path d="M5 12h14M13 6l6 6-6 6" />
            </svg>
            Swipe to explore every screen
          </p>
        </section>

        {/* ================= FEATURE ROWS ================= */}
        <section className="sec">
          <div className="wrap">
            <div className="frow">
              <div className="frow-copy">
                <p className="eyebrow reveal">Snap. Speak. Scan. Type.</p>
                <h3 className="reveal d1">Log food in seconds</h3>
                <p className="lead reveal d2">
                  Multiple ways to input. One smart way to log. However you eat,
                  there&apos;s a faster way to track it — no endless searching.
                </p>
                <ul className="flist reveal d2">
                  <li>
                    <Check />
                    <div>
                      <b>Photo &amp; voice</b>
                      <p>
                        Point your camera at a plate or just describe your meal
                        out loud.
                      </p>
                    </div>
                  </li>
                  <li>
                    <Check />
                    <div>
                      <b>Barcode &amp; label scan</b>
                      <p>
                        Scan packaged foods and nutrition labels for exact
                        numbers.
                      </p>
                    </div>
                  </li>
                  <li>
                    <Check />
                    <div>
                      <b>AI text input</b>
                      <p>
                        Type &quot;two eggs and toast&quot; — the AI estimates the
                        macros instantly.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>
              <div className="frow-media reveal d1">
                <div className="blob" />
                <Image
                  src="/screenshots/screen-input.png"
                  alt="Multiple ways to log food in voidpen"
                  width={1242}
                  height={2688}
                  style={{ height: "auto" }}
                />
              </div>
            </div>

            <div className="frow flip">
              <div className="frow-media reveal d1">
                <div className="blob" />
                <Image
                  src="/screenshots/screen-macros.png"
                  alt="Macro dashboard at a glance"
                  width={1242}
                  height={2688}
                  style={{ height: "auto" }}
                />
                <div className="media-tag" style={{ top: "14%", left: "-6%" }}>
                  <span className="fi">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2c1 3-1 4-1 6 0 1 .8 1.8 2 2 .5-1 1.5-1.5 1.5-3 2 1.5 3.5 4 3.5 7a6 6 0 1 1-12 0c0-3 2-5 3-7 .5 1 1 1.5 2 2-.5-2-1-5 1-7Z" />
                    </svg>
                  </span>
                  104 / 115g
                </div>
              </div>
              <div className="frow-copy">
                <p className="eyebrow reveal">Hit your macros</p>
                <h3 className="reveal d1">
                  Your whole day,
                  <br />
                  one glance
                </h3>
                <p className="lead reveal d2">
                  Calories, protein, carbs and fat — all on one beautiful
                  dashboard. See what&apos;s left in your day the moment you open
                  the app.
                </p>
                <ul className="flist reveal d2">
                  <li>
                    <Check />
                    <div>
                      <b>Live calorie ring</b>
                      <p>Watch your budget fill up in real time as you log.</p>
                    </div>
                  </li>
                  <li>
                    <Check />
                    <div>
                      <b>Per-meal breakdown</b>
                      <p>
                        Tap any meal to see exactly where your macros came from.
                      </p>
                    </div>
                  </li>
                  <li>
                    <Check />
                    <div>
                      <b>Home screen widgets</b>
                      <p>
                        Keep your targets one tap away, right on your lock screen.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* ================= HOW IT WORKS ================= */}
        <section className="sec steps" id="how">
          <div className="wrap">
            <div className="sec-head">
              <p className="eyebrow reveal">How it works</p>
              <h2 className="display reveal d1">Three taps to tracked</h2>
              <p className="lead reveal d2">
                No food scales, no spreadsheets, no guilt. Just open, log, and get
                on with your day.
              </p>
            </div>
            <div className="steps-grid">
              <div className="step reveal d1">
                <span className="step-num">1</span>
                <span className="si">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M4 8a2 2 0 0 1 2-2h1.5l1-1.6h7l1 1.6H18a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z" />
                    <circle cx="12" cy="12.5" r="3.4" />
                  </svg>
                </span>
                <h4>Capture it</h4>
                <p>
                  Snap a photo, speak, scan a barcode or type. Whatever&apos;s
                  fastest in the moment.
                </p>
              </div>
              <div className="step reveal d2">
                <span className="step-num">2</span>
                <span className="si">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6L12 3Z" />
                    <path d="M18 14l.7 2 2 .8-2 .7L18 20l-.7-2-2-.7 2-.8.7-1.5Z" />
                  </svg>
                </span>
                <h4>AI does the math</h4>
                <p>
                  voidpen identifies the food and fills in calories and every
                  macro automatically.
                </p>
              </div>
              <div className="step reveal d3">
                <span className="step-num">3</span>
                <span className="si">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M4 17l5-5 3 3 7-8" />
                    <path d="M16 7h4v4" />
                  </svg>
                </span>
                <h4>Watch progress</h4>
                <p>
                  See weight, calories and trends line up over weeks — and stay on
                  track for good.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ================= AI COACH ================= */}
        <section className="sec" id="coach">
          <div className="wrap">
            <div className="coach">
              <div className="coach-inner">
                <div>
                  <p className="eyebrow reveal" style={{ color: "var(--accent-2)" }}>
                    Meet your AI coach
                  </p>
                  <h2 className="reveal d1">
                    Smart help for
                    <br />
                    meals, goals <span className="g">&amp; habits</span>
                  </h2>
                  <p className="lead reveal d2">
                    Ask anything. Your coach knows your targets and your history —
                    so the advice actually fits your day, not a generic plan.
                  </p>
                  <div className="coach-chips reveal d2">
                    <span className="chip">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                      >
                        <circle cx="12" cy="12" r="8" />
                        <circle cx="12" cy="12" r="3.2" />
                      </svg>
                      Hit my protein goal
                    </span>
                    <span className="chip">
                      <svg viewBox="0 0 24 24" fill="currentColor">
                        <circle
                          cx="12"
                          cy="12"
                          r="9"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        />
                        <circle cx="9" cy="10" r="1.3" />
                        <circle cx="15" cy="10" r="1.3" />
                        <path
                          d="M8 14a4 4 0 0 0 8 0"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                          strokeLinecap="round"
                        />
                      </svg>
                      Suggest meals
                    </span>
                    <span className="chip">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="M4 17l5-5 3 3 7-8" />
                        <path d="M16 7h4v4" />
                      </svg>
                      Track my progress
                    </span>
                  </div>
                </div>
                <div className="coach-media reveal d2">
                  <Image
                    src="/screenshots/screen-coach.png"
                    alt="AI coach conversation in voidpen"
                    width={1242}
                    height={2688}
                    style={{ height: "auto" }}
                  />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================= TESTIMONIALS ================= */}
        <section className="sec">
          <div className="wrap">
            <div className="sec-head">
              <p className="eyebrow reveal">Loved by trackers</p>
              <h2 className="display reveal d1">People stick with it</h2>
            </div>
            <div className="quotes-grid">
              <div className="quote reveal d1">
                <div className="stars">★★★★★</div>
                <p>
                  &quot;I&apos;ve tried every tracker out there. Snapping a photo
                  and getting macros back in seconds is the only reason I&apos;ve
                  logged 90 days straight.&quot;
                </p>
                <div className="who">
                  <span
                    className="av"
                    style={{ backgroundImage: "url('https://i.pravatar.cc/88?img=47')" }}
                  />
                  <div>
                    <b>Maya R.</b>
                    <span>Down 14 lbs</span>
                  </div>
                </div>
              </div>
              <div className="quote reveal d2">
                <div className="stars">★★★★★</div>
                <p>
                  &quot;The AI coach feels like texting a nutritionist who actually
                  remembers my goals. It nudged me to fix my protein and it
                  worked.&quot;
                </p>
                <div className="who">
                  <span
                    className="av"
                    style={{ backgroundImage: "url('https://i.pravatar.cc/88?img=15')" }}
                  />
                  <div>
                    <b>Daniel K.</b>
                    <span>Lean bulk, +6 lbs muscle</span>
                  </div>
                </div>
              </div>
              <div className="quote reveal d3">
                <div className="stars">★★★★★</div>
                <p>
                  &quot;The dashboard is gorgeous and the widgets keep me honest.
                  First app that&apos;s made tracking feel light instead of like a
                  chore.&quot;
                </p>
                <div className="who">
                  <span
                    className="av"
                    style={{ backgroundImage: "url('https://i.pravatar.cc/88?img=31')" }}
                  />
                  <div>
                    <b>Priya S.</b>
                    <span>Maintaining for 1 year</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ================= FAQ ================= */}
        <section className="sec steps" id="faq">
          <div className="wrap">
            <div className="sec-head">
              <p className="eyebrow reveal">Questions</p>
              <h2 className="display reveal d1">Good to know</h2>
            </div>
            <div className="faq-list">
              <details className="faq-item reveal" open>
                <summary>
                  How accurate is the photo logging?
                  <span className="q-ico">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                    >
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </span>
                </summary>
                <div className="a">
                  voidpen&apos;s AI recognizes thousands of common foods and
                  estimates portion size from the photo. You can always tap to
                  adjust grams or pick a more specific match — and it learns the
                  foods you eat most.
                </div>
              </details>
              <details className="faq-item reveal">
                <summary>
                  Is there a free version?
                  <span className="q-ico">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                    >
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </span>
                </summary>
                <div className="a">
                  Yes. You can log food, track macros and use widgets for free. The
                  AI coach and unlimited photo logging are part of voidpen Pro,
                  with a free trial to start.
                </div>
              </details>
              <details className="faq-item reveal">
                <summary>
                  Does it work with Apple Health?
                  <span className="q-ico">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                    >
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </span>
                </summary>
                <div className="a">
                  voidpen syncs weight, calories and activity with Apple Health, so
                  your nutrition data lives alongside the rest of your health
                  picture.
                </div>
              </details>
              <details className="faq-item reveal">
                <summary>
                  Can it set my macro targets for me?
                  <span className="q-ico">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                    >
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </span>
                </summary>
                <div className="a">
                  Absolutely. Tell the app your goal — lose, maintain or gain — and
                  it calculates calorie and macro targets, then adjusts them as
                  your weight trends change.
                </div>
              </details>
            </div>
          </div>
        </section>

        {/* ================= FINAL CTA ================= */}
        <section className="sec cta-band" id="download">
          <div className="cta-inner reveal">
            <h2>
              Your macros,
              <br />
              finally handled
            </h2>
            <p>
              Download <span className="brand-name">voidpen</span> and log your
              first meal in under five seconds. Free to start.
            </p>
            <div className="cta-actions">
              <AppStoreBadge href={APP_STORE_URL} />
            </div>
          </div>
        </section>
      </main>

      {/* ================= FOOTER ================= */}
      <footer className="footer">
        <div className="wrap">
          <div className="footer-grid">
            <div>
              <a className="brand" href="#top">
                <span className="brand-mark">
                  <Image
                    src="/voidpen-logo.png"
                    alt="voidpen logo"
                    width={40}
                    height={40}
                  />
                </span>
                <span className="brand-name">voidpen</span>
              </a>
              <p className="footer-about">
                AI nutrition tracking that keeps up with how you actually eat.
                Snap, speak, scan or type.
              </p>
            </div>
            <div>
              <h5>Product</h5>
              <ul>
                <li>
                  <a href="#features">Features</a>
                </li>
                <li>
                  <a href="#how">How it works</a>
                </li>
                <li>
                  <a href="#coach">AI Coach</a>
                </li>
                <li>
                  <a href="#download">Download</a>
                </li>
              </ul>
            </div>
            <div>
              <h5>Company</h5>
              <ul>
                <li>
                  <a href="#">About</a>
                </li>
                <li>
                  <Link href="/blogs">Blog</Link>
                </li>
                <li>
                  <a href="#">Careers</a>
                </li>
                <li>
                  <a href="#">Press</a>
                </li>
              </ul>
            </div>
            <div>
              <h5>Support</h5>
              <ul>
                <li>
                  <Link href="/support">Help center</Link>
                </li>
                <li>
                  <a href="mailto:info@voidpen.com">info@voidpen.com</a>
                </li>
                <li>
                  <Link href="/privacy">Privacy</Link>
                </li>
                <li>
                  <Link href="/terms">Terms</Link>
                </li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <span>
              © 2026 <span className="brand-name">voidpen</span>. All rights
              reserved.
            </span>
            <div className="socials">
              <a href="#" aria-label="X">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M17.5 3h3l-6.6 7.5L21.8 21h-6l-4.3-5.6L6.4 21H3.3l7-8L2.5 3h6.1l3.9 5.1L17.5 3Zm-1.1 16h1.7L7.8 4.8H6L16.4 19Z" />
                </svg>
              </a>
              <a href="#" aria-label="Instagram">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="3" width="18" height="18" rx="5" />
                  <circle cx="12" cy="12" r="4" />
                  <circle cx="17.5" cy="6.5" r="1.2" fill="currentColor" stroke="none" />
                </svg>
              </a>
              <a href="#" aria-label="TikTok">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M15 3c.3 2.2 1.7 3.8 4 4v3c-1.5 0-2.9-.5-4-1.2V15a6 6 0 1 1-6-6c.3 0 .7 0 1 .1v3.1A3 3 0 1 0 12 15V3h3Z" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </footer>

      <LandingEnhancements />
    </div>
  );
}
