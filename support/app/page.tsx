import Image from "next/image";
import Link from "next/link";
import { AppStoreBadge } from "@/components/app-store-badge";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";

const features = [
  {
    title: "Snap a photo, get calories",
    description:
      "Point your camera at a meal. Voidpen reads it and logs calories and macros in seconds — no barcode, no menu hunting.",
  },
  {
    title: "Talk it through",
    description:
      "Press and speak. “Two eggs and a piece of toast.” Done. Voice logging that actually keeps up with you.",
  },
  {
    title: "Coach in your pocket",
    description:
      "Ask your AI nutritionist anything — “What should I eat for dinner?”, “Am I on track?” Personal, fast, judgment-free.",
  },
  {
    title: "HealthKit, both ways",
    description:
      "Two-way sync for weight, height, and body composition. Your data stays in one place — yours.",
  },
  {
    title: "Built for your day",
    description:
      "Widgets, fast logging, photo memories of past meals. Built to fit a real life, not just a sticker chart.",
  },
  {
    title: "Private by default",
    description:
      "No accounts. No tracking. An anonymous install ID is all we need. Delete anytime.",
  },
];

const highlights = [
  { label: "Languages", value: "16" },
  { label: "Camera tap to log", value: "<2s" },
  { label: "Sign-up needed", value: "None" },
];

const screenshots = [
  { src: "/screenshots/home.png", alt: "Home dashboard", w: "tall" },
  { src: "/screenshots/snap.png", alt: "AI photo scan", w: "tall" },
  { src: "/screenshots/coach.png", alt: "AI coach chat", w: "tall" },
  { src: "/screenshots/progress.png", alt: "Progress and trends", w: "tall" },
] as const;

const faqs = [
  {
    q: "Does Voidpen need an account?",
    a: "No. Voidpen uses an anonymous install ID — no email, no password, nothing to remember. Your data is tied to your install.",
  },
  {
    q: "How accurate is the photo scan?",
    a: "Voidpen uses state-of-the-art vision models. Estimates are typically within ±15% — close enough to spot trends. Always double-check labels if you need exact numbers.",
  },
  {
    q: "Does it work offline?",
    a: "Basic logging works offline. AI features (photo, voice, Coach) need an internet connection because they run in the cloud.",
  },
  {
    q: "How do I cancel my subscription?",
    a: "On iPhone: Settings → Apple ID → Subscriptions → Voidpen → Cancel. Your access continues until the end of the current billing period.",
  },
  {
    q: "How do I delete my data?",
    a: "Visit our delete account page, or email coduy96@gmail.com. We permanently remove your data within 30 days.",
  },
];

export default function Home() {
  return (
    <>
      <Header />
      <main className="flex-1 w-full">
        {/* Hero */}
        <section className="relative overflow-hidden">
          <div
            aria-hidden
            className="pointer-events-none absolute inset-x-0 -top-40 h-[480px] bg-[radial-gradient(ellipse_at_top,rgba(167,139,250,0.18),transparent_60%)]"
          />
          <div className="mx-auto max-w-6xl px-6 pt-20 pb-12 sm:pt-28">
            <div className="grid items-center gap-12 lg:grid-cols-[1.05fr_0.95fr]">
              <div>
                <div className="inline-flex items-center gap-2 rounded-full border border-neutral-800 bg-neutral-900/60 px-3 py-1 text-xs text-neutral-400">
                  <span className="h-1.5 w-1.5 rounded-full bg-[#a78bfa]" />
                  Now on the App Store
                </div>
                <h1 className="mt-6 text-5xl font-semibold leading-[1.05] tracking-tight sm:text-6xl">
                  Track less.
                  <br />
                  <span className="bg-gradient-to-r from-[#c4b5fd] via-[#a78bfa] to-[#7c3aed] bg-clip-text text-transparent">
                    Live more.
                  </span>
                </h1>
                <p className="mt-6 max-w-xl text-lg text-neutral-400 sm:text-xl">
                  Snap a photo, talk to your Coach, hit your goals. Voidpen is
                  the calorie tracker that disappears into your day.
                </p>
                <div className="mt-8 flex flex-wrap items-center gap-3">
                  <AppStoreBadge />
                  <Link
                    href="/support"
                    className="inline-flex items-center justify-center rounded-xl border border-neutral-800 bg-neutral-900/60 px-5 py-3 text-sm font-medium text-neutral-200 transition hover:bg-neutral-900"
                  >
                    Get help
                  </Link>
                </div>
                <dl className="mt-10 grid max-w-md grid-cols-3 gap-6 border-t border-neutral-900 pt-6">
                  {highlights.map((h) => (
                    <div key={h.label}>
                      <dt className="text-xs uppercase tracking-wide text-neutral-500">
                        {h.label}
                      </dt>
                      <dd className="mt-1 text-2xl font-semibold tracking-tight text-neutral-100">
                        {h.value}
                      </dd>
                    </div>
                  ))}
                </dl>
              </div>
              <div className="relative mx-auto w-full max-w-sm">
                <div
                  aria-hidden
                  className="absolute -inset-6 rounded-[44px] bg-gradient-to-tr from-[#a78bfa]/25 via-transparent to-transparent blur-2xl"
                />
                <div className="relative overflow-hidden rounded-[36px] border border-neutral-800 bg-neutral-900 shadow-2xl shadow-black/40">
                  <Image
                    src="/screenshots/home.png"
                    alt="Voidpen home screen"
                    width={1320}
                    height={2868}
                    priority
                    className="h-auto w-full"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="mx-auto max-w-6xl px-6 py-20">
          <div className="max-w-2xl">
            <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
              The least-friction calorie tracker on iOS.
            </h2>
            <p className="mt-4 text-neutral-400">
              No barcodes. No 12-screen onboarding. No subscription paywall
              before you can even open the app. Voidpen earns its place.
            </p>
          </div>
          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((f) => (
              <div
                key={f.title}
                className="group relative rounded-2xl border border-neutral-800/80 bg-neutral-900/40 p-6 transition hover:border-neutral-700 hover:bg-neutral-900/70"
              >
                <h3 className="text-base font-semibold text-neutral-100">
                  {f.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-neutral-400">
                  {f.description}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Screenshots */}
        <section className="mx-auto max-w-6xl px-6 pb-20">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
            See it in action.
          </h2>
          <div className="mt-10 grid grid-cols-2 gap-4 sm:grid-cols-4">
            {screenshots.map((s) => (
              <div
                key={s.src}
                className="overflow-hidden rounded-2xl border border-neutral-800/80 bg-neutral-900"
              >
                <Image
                  src={s.src}
                  alt={s.alt}
                  width={1320}
                  height={2868}
                  className="h-auto w-full"
                />
              </div>
            ))}
          </div>
        </section>

        {/* CTA */}
        <section className="mx-auto max-w-6xl px-6 pb-20">
          <div className="relative overflow-hidden rounded-3xl border border-neutral-800 bg-gradient-to-br from-neutral-900 to-neutral-950 p-10 sm:p-14">
            <div
              aria-hidden
              className="pointer-events-none absolute -right-20 -top-20 h-72 w-72 rounded-full bg-[#a78bfa]/20 blur-3xl"
            />
            <div className="relative max-w-2xl">
              <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
                Stop fighting your food log.
              </h2>
              <p className="mt-4 text-neutral-400">
                Free to try. No account. Cancel anytime.
              </p>
              <div className="mt-8">
                <AppStoreBadge />
              </div>
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section className="mx-auto max-w-3xl px-6 pb-24">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
            Common questions
          </h2>
          <div className="mt-10 divide-y divide-neutral-800 rounded-2xl border border-neutral-800/80 bg-neutral-900/40">
            {faqs.map((item) => (
              <details key={item.q} className="group p-6">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 text-base font-medium text-neutral-100">
                  {item.q}
                  <span className="text-neutral-500 transition group-open:rotate-45">
                    +
                  </span>
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-neutral-400">
                  {item.a}
                </p>
              </details>
            ))}
          </div>
          <p className="mt-8 text-sm text-neutral-500">
            Still stuck?{" "}
            <a
              href="mailto:coduy96@gmail.com"
              className="text-[#a78bfa] hover:underline"
            >
              Email coduy96@gmail.com
            </a>{" "}
            and a real human will reply.
          </p>
        </section>
      </main>
      <Footer />
    </>
  );
}
