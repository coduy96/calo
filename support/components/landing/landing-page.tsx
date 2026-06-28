import { Fragment, type ReactNode } from "react";
import Image from "next/image";
import Link from "next/link";
import { LandingEnhancements } from "@/components/landing-enhancements";
import { LanguageSwitcher } from "@/components/landing/language-switcher";
import type { LocaleConfig } from "@/lib/i18n/config";
import { SITE_URL } from "@/lib/i18n/config";
import type { Dictionary } from "@/lib/i18n/dictionaries";
import "@/app/landing.css";

/*
 * Shared, fully-localized voidpen.com landing page.
 *
 * Ported pixel-for-pixel from the original Claude Design handoff, then
 * parameterized: every visible string comes from `dict`, and the wrapper
 * carries the locale's `lang`/`dir` (the root <html> stays `en` because the
 * legal/blog pages share it). Styles live in app/landing.css, scoped under
 * `.vp-landing`. Interactivity is progressively enhanced by
 * <LandingEnhancements />.
 */
const APP_STORE_URL = "https://apps.apple.com/app/id6770921845";

// Fabricated-but-fixed marketing numbers — never translated, only the labels
// around them are. Kept here so the dictionaries stay copy-only.
const RATING = "4.9";
const REVIEW_COUNT = "12,000+";

/** Replace `{token}` placeholders in a string with React nodes. */
function tmpl(template: string, values: Record<string, ReactNode>): ReactNode[] {
  return template.split(/(\{[a-z]+\})/gi).map((part, i) => {
    const key = part.replace(/^\{|\}$/g, "");
    const value = part.startsWith("{") && part.endsWith("}") ? values[key] : undefined;
    return <Fragment key={i}>{value ?? part}</Fragment>;
  });
}

const Brand = () => <span className="brand-name">voidpen</span>;

function AppStoreBadge({
  dict,
}: {
  dict: Dictionary;
}) {
  const ariaLabel = `${dict.appStore.download} ${dict.appStore.store}`;
  return (
    <a href={APP_STORE_URL} className="appstore" aria-label={ariaLabel}>
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M16.36 12.78c-.02-2.2 1.8-3.26 1.88-3.31-1.02-1.5-2.62-1.7-3.19-1.73-1.36-.14-2.65.8-3.34.8-.69 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.62 1.11 8.78.73 1.06 1.6 2.25 2.74 2.2 1.1-.04 1.51-.71 2.85-.71 1.32 0 1.71.71 2.87.69 1.19-.02 1.94-1.08 2.66-2.14.84-1.23 1.19-2.42 1.21-2.48-.03-.01-2.32-.89-2.34-3.52ZM14.17 6.0c.61-.74 1.02-1.77.91-2.8-.88.04-1.94.59-2.57 1.32-.56.65-1.06 1.69-.93 2.69.98.08 1.98-.5 2.59-1.21Z" />
      </svg>
      <span className="as-text">
        <span className="as-small">{dict.appStore.download}</span>
        <span className="as-big">{dict.appStore.store}</span>
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

export function LandingPage({
  dict,
  locale,
}: {
  dict: Dictionary;
  locale: LocaleConfig;
}) {
  // Per-locale structured data so each language surfaces correctly in search.
  const appJsonLd = {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: "Voidpen: Calorie Tracker",
    operatingSystem: "iOS",
    applicationCategory: "HealthApplication",
    description: dict.meta.appDescription,
    url: SITE_URL,
    installUrl: APP_STORE_URL,
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    author: { "@id": `${SITE_URL}/#organization` },
    inLanguage: locale.hrefLang,
  };

  const faqJsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    inLanguage: locale.hrefLang,
    mainEntity: dict.faq.items.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: { "@type": "Answer", text: item.a },
    })),
  };

  return (
    <div className="vp-landing" lang={locale.hrefLang} dir={locale.dir}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(appJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />
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
            <a href="#features">{dict.nav.features}</a>
            <a href="#how">{dict.nav.how}</a>
            <a href="#coach">{dict.nav.coach}</a>
            <a href="#faq">{dict.nav.faq}</a>
            <Link href="/blogs">{dict.nav.blog}</Link>
          </nav>
          <div className="nav-cta">
            <LanguageSwitcher current={locale.code} label={dict.nav.language} />
            <AppStoreBadge dict={dict} />
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
        <a href="#features">{dict.nav.features}</a>
        <a href="#how">{dict.nav.how}</a>
        <a href="#coach">{dict.nav.coach}</a>
        <a href="#faq">{dict.nav.faq}</a>
        <Link href="/blogs">{dict.nav.blog}</Link>
        <LanguageSwitcher current={locale.code} label={dict.nav.language} />
        <AppStoreBadge dict={dict} />
      </div>

      <main id="top">
        {/* ================= HERO ================= */}
        <section className="hero">
          <div className="wrap hero-grid">
            <div className="hero-copy">
              <p className="eyebrow reveal">{dict.hero.eyebrow}</p>
              <h1 className="display reveal d1">
                {dict.hero.titleLine1}
                <br />
                <span className="line2">{dict.hero.titleHighlight}</span>
                <br />
                {dict.hero.titleLine3}
              </h1>
              <p className="lead reveal d2">
                {tmpl(dict.hero.lead, { brand: <Brand /> })}
              </p>
              <div className="hero-actions reveal d2">
                <AppStoreBadge dict={dict} />
                <a href="#features" className="btn btn-ghost">
                  {dict.hero.ctaSecondary}
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
                    {tmpl(dict.hero.proof, {
                      rating: <strong>{RATING}</strong>,
                      count: <strong>{REVIEW_COUNT}</strong>,
                    })}
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
                  alt={dict.alts.heroHome}
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
                <div className="lbl">{dict.stats.appStoreRating}</div>
              </div>
              <div className="stat">
                <div className="num">2M+</div>
                <div className="lbl">{dict.stats.mealsLogged}</div>
              </div>
              <div className="stat">
                <div className="num">5s</div>
                <div className="lbl">{dict.stats.avgLogTime}</div>
              </div>
              <div className="stat">
                <div className="num">600k+</div>
                <div className="lbl">{dict.stats.foodsInDatabase}</div>
              </div>
            </div>
          </div>
        </section>

        {/* ================= SCREENSHOT GALLERY ================= */}
        <section className="sec gallery" id="features">
          <div className="wrap sec-head">
            <p className="eyebrow reveal">{dict.gallery.eyebrow}</p>
            <h2 className="display reveal d1">
              {dict.gallery.titleLine1}
              <br />
              <span className="accent-text">{dict.gallery.titleHighlight}</span>
            </h2>
            <p className="lead reveal d2">{dict.gallery.lead}</p>
          </div>
          <div className="gallery-rail reveal d1">
            <div className="shot">
              <Image
                src="/screenshots/screen-macros.png"
                alt={dict.alts.macros}
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-input.png"
                alt={dict.alts.input}
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-coach.png"
                alt={dict.alts.coach}
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-progress.png"
                alt={dict.alts.progress}
                width={1242}
                height={2688}
                style={{ height: "auto" }}
              />
            </div>
            <div className="shot">
              <Image
                src="/screenshots/screen-widgets.png"
                alt={dict.alts.widgets}
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
            {dict.gallery.hint}
          </p>
        </section>

        {/* ================= FEATURE ROWS ================= */}
        <section className="sec">
          <div className="wrap">
            <div className="frow">
              <div className="frow-copy">
                <p className="eyebrow reveal">{dict.featureInput.eyebrow}</p>
                <h3 className="reveal d1">{dict.featureInput.title}</h3>
                <p className="lead reveal d2">{dict.featureInput.lead}</p>
                <ul className="flist reveal d2">
                  {dict.featureInput.items.map((item, i) => (
                    <li key={i}>
                      <Check />
                      <div>
                        <b>{item.title}</b>
                        <p>{item.body}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="frow-media reveal d1">
                <div className="blob" />
                <Image
                  src="/screenshots/screen-input.png"
                  alt={dict.alts.input}
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
                  alt={dict.alts.macros}
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
                <p className="eyebrow reveal">{dict.featureMacros.eyebrow}</p>
                <h3 className="reveal d1">
                  {dict.featureMacros.titleLine1}
                  <br />
                  {dict.featureMacros.titleLine2}
                </h3>
                <p className="lead reveal d2">{dict.featureMacros.lead}</p>
                <ul className="flist reveal d2">
                  {dict.featureMacros.items.map((item, i) => (
                    <li key={i}>
                      <Check />
                      <div>
                        <b>{item.title}</b>
                        <p>{item.body}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* ================= HOW IT WORKS ================= */}
        <section className="sec steps" id="how">
          <div className="wrap">
            <div className="sec-head">
              <p className="eyebrow reveal">{dict.steps.eyebrow}</p>
              <h2 className="display reveal d1">{dict.steps.title}</h2>
              <p className="lead reveal d2">{dict.steps.lead}</p>
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
                <h4>{dict.steps.items[0].title}</h4>
                <p>{dict.steps.items[0].body}</p>
              </div>
              <div className="step reveal d2">
                <span className="step-num">2</span>
                <span className="si">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6L12 3Z" />
                    <path d="M18 14l.7 2 2 .8-2 .7L18 20l-.7-2-2-.7 2-.8.7-1.5Z" />
                  </svg>
                </span>
                <h4>{dict.steps.items[1].title}</h4>
                <p>{dict.steps.items[1].body}</p>
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
                <h4>{dict.steps.items[2].title}</h4>
                <p>{dict.steps.items[2].body}</p>
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
                    {dict.coach.eyebrow}
                  </p>
                  <h2 className="reveal d1">
                    {dict.coach.titleLine1}
                    <br />
                    {dict.coach.titleLine2} <span className="g">{dict.coach.titleHighlight}</span>
                  </h2>
                  <p className="lead reveal d2">{dict.coach.lead}</p>
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
                      {dict.coach.chips[0]}
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
                      {dict.coach.chips[1]}
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
                      {dict.coach.chips[2]}
                    </span>
                  </div>
                </div>
                <div className="coach-media reveal d2">
                  <Image
                    src="/screenshots/screen-coach.png"
                    alt={dict.alts.coach}
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
              <p className="eyebrow reveal">{dict.testimonials.eyebrow}</p>
              <h2 className="display reveal d1">{dict.testimonials.title}</h2>
            </div>
            <div className="quotes-grid">
              {dict.testimonials.quotes.map((quote, i) => (
                <div className={`quote reveal d${i + 1}`} key={i}>
                  <div className="stars">★★★★★</div>
                  <p>{quote.text}</p>
                  <div className="who">
                    <span
                      className="av"
                      style={{
                        backgroundImage: `url('https://i.pravatar.cc/88?img=${[47, 15, 31][i]}')`,
                      }}
                    />
                    <div>
                      <b>{quote.name}</b>
                      <span>{quote.caption}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ================= FAQ ================= */}
        <section className="sec steps" id="faq">
          <div className="wrap">
            <div className="sec-head">
              <p className="eyebrow reveal">{dict.faq.eyebrow}</p>
              <h2 className="display reveal d1">{dict.faq.title}</h2>
            </div>
            <div className="faq-list">
              {dict.faq.items.map((item, i) => (
                <details className="faq-item reveal" key={i} open={i === 0}>
                  <summary>
                    {item.q}
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
                  <div className="a">{item.a}</div>
                </details>
              ))}
            </div>
          </div>
        </section>

        {/* ================= FINAL CTA ================= */}
        <section className="sec cta-band" id="download">
          <div className="cta-inner reveal">
            <h2>
              {dict.cta.titleLine1}
              <br />
              {dict.cta.titleLine2}
            </h2>
            <p>{tmpl(dict.cta.body, { brand: <Brand /> })}</p>
            <div className="cta-actions">
              <AppStoreBadge dict={dict} />
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
              <p className="footer-about">{dict.footer.about}</p>
            </div>
            <div>
              <h5>{dict.footer.colProduct}</h5>
              <ul>
                <li>
                  <a href="#features">{dict.nav.features}</a>
                </li>
                <li>
                  <a href="#how">{dict.nav.how}</a>
                </li>
                <li>
                  <a href="#coach">{dict.nav.coach}</a>
                </li>
                <li>
                  <a href="#download">{dict.footer.download}</a>
                </li>
              </ul>
            </div>
            <div>
              <h5>{dict.footer.colCompany}</h5>
              <ul>
                <li>
                  <Link href="/blogs">{dict.nav.blog}</Link>
                </li>
                <li>
                  <a href="mailto:info@voidpen.com">{dict.footer.contact}</a>
                </li>
              </ul>
            </div>
            <div>
              <h5>{dict.footer.colSupport}</h5>
              <ul>
                <li>
                  <Link href="/support">{dict.footer.helpCenter}</Link>
                </li>
                <li>
                  <a href="mailto:info@voidpen.com">info@voidpen.com</a>
                </li>
                <li>
                  <Link href="/privacy">{dict.footer.privacy}</Link>
                </li>
                <li>
                  <Link href="/terms">{dict.footer.terms}</Link>
                </li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <span>{tmpl(dict.footer.rights, { brand: <Brand /> })}</span>
            {/* Social icons removed until real profiles exist — dead "#" links
                hurt crawl quality. Re-add with real URLs when ready. */}
          </div>
        </div>
      </footer>

      <LandingEnhancements />
    </div>
  );
}
