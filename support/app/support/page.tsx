import Link from "next/link";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";

export const metadata = {
  title: "Support",
  description:
    "Get help with Voidpen — contact us, manage your subscription, troubleshoot common issues, and find quick answers.",
};

const topics = [
  {
    title: "Manage subscription",
    body: "iPhone → Settings → Apple ID → Subscriptions → Voidpen. From there you can change plan, cancel, or restore a previous purchase.",
  },
  {
    title: "Restore purchases",
    body: "Open Voidpen → Settings → Restore Purchases. Make sure you’re signed in to the same Apple ID that made the original purchase.",
  },
  {
    title: "Photo scan looks wrong",
    body: "Estimates are typically within ±15%. Tap the entry after scanning to edit grams, servings, or swap the food. Your edits are saved.",
  },
  {
    title: "Voice logging not working",
    body: "Check Settings → Voidpen → Microphone is on. Voice features need an internet connection — try again on Wi-Fi if it stalls.",
  },
  {
    title: "Sync with Apple Health",
    body: "Voidpen reads and writes weight, height, and body composition. Toggle in Settings → Voidpen → Health, or open the Health app → Sharing → Apps.",
  },
  {
    title: "Delete my data",
    body: "Use our delete-account page or email coduy96@gmail.com. We permanently remove your data within 30 days.",
  },
];

export default function SupportPage() {
  return (
    <>
      <Header />
      <main className="flex-1 w-full">
        <section className="mx-auto max-w-3xl px-6 py-16 sm:py-24">
          <Link
            href="/"
            className="text-sm text-neutral-500 transition hover:text-[#a78bfa]"
          >
            ← Back to home
          </Link>
          <h1 className="mt-6 text-4xl font-semibold tracking-tight sm:text-5xl">
            Support
          </h1>
          <p className="mt-4 text-lg text-neutral-400">
            Real humans, real fast. Most questions are answered below — if
            you’re still stuck, email us.
          </p>

          <div className="mt-10 rounded-2xl border border-neutral-800 bg-neutral-900/50 p-6">
            <h2 className="text-lg font-semibold text-neutral-100">
              Email support
            </h2>
            <p className="mt-2 text-sm text-neutral-400">
              We reply within one business day, usually faster.
            </p>
            <a
              href="mailto:coduy96@gmail.com?subject=Voidpen%20support"
              className="mt-5 inline-flex items-center justify-center rounded-lg bg-[#a78bfa] px-5 py-2.5 text-sm font-medium text-neutral-950 transition hover:bg-[#b8a3fb]"
            >
              coduy96@gmail.com
            </a>
            <p className="mt-4 text-xs text-neutral-500">
              When you write in, include your iOS version and a screenshot if
              you can. It helps us help you faster.
            </p>
          </div>

          <section className="mt-14">
            <h2 className="text-2xl font-semibold tracking-tight">
              Quick answers
            </h2>
            <div className="mt-6 grid gap-3">
              {topics.map((t) => (
                <div
                  key={t.title}
                  className="rounded-xl border border-neutral-800/80 bg-neutral-900/40 p-5"
                >
                  <h3 className="text-base font-semibold text-neutral-100">
                    {t.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-neutral-400">
                    {t.body}
                  </p>
                </div>
              ))}
            </div>
          </section>

          <section className="mt-14 rounded-2xl border border-neutral-800/80 bg-neutral-900/40 p-6">
            <h2 className="text-lg font-semibold text-neutral-100">
              Other resources
            </h2>
            <ul className="mt-4 space-y-2 text-sm text-neutral-400">
              <li>
                <Link
                  href="/privacy"
                  className="text-[#a78bfa] hover:underline"
                >
                  Privacy Policy
                </Link>
                {" — "}what we collect and how we use it.
              </li>
              <li>
                <Link href="/terms" className="text-[#a78bfa] hover:underline">
                  Terms of Service
                </Link>
                {" — "}subscription terms and governing law.
              </li>
              <li>
                <Link
                  href="/delete-account"
                  className="text-[#a78bfa] hover:underline"
                >
                  Delete account
                </Link>
                {" — "}request permanent deletion of your data.
              </li>
            </ul>
          </section>
        </section>
      </main>
      <Footer />
    </>
  );
}
