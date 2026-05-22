import Link from "next/link";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";

export const metadata = {
  title: "Privacy Policy",
  description:
    "Privacy policy for Voidpen: Calorie Tracker — what we collect, how we use it, third parties, retention, and contact.",
};

export default function PrivacyPage() {
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
          <h1 className="mt-6 text-4xl font-semibold tracking-tight">
            Privacy Policy
          </h1>
          <p className="mt-3 text-sm text-neutral-500">
            Last updated: May 2026
          </p>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">What data we collect</h2>
            <ul className="list-disc space-y-2 pl-5 text-neutral-300">
              <li>
                An anonymous install identifier used to associate your data
                with your device. We don’t ask for your name, email, or login.
              </li>
              <li>
                Food entries, meal logs, and weight or body composition
                measurements you record in the app.
              </li>
              <li>
                Photos and voice recordings you submit for AI processing.
                These are processed in transit and are not retained on our
                servers after the response is returned.
              </li>
              <li>
                Subscription receipt data needed to verify your entitlement
                (handled by Apple and RevenueCat).
              </li>
            </ul>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">How we use it</h2>
            <ul className="list-disc space-y-2 pl-5 text-neutral-300">
              <li>
                To provide AI features such as photo scanning, voice
                transcription, and the Coach chat experience.
              </li>
              <li>
                To sync weight, height, and body composition to and from Apple
                HealthKit on your device, with your permission.
              </li>
              <li>
                To manage your subscription entitlement through RevenueCat.
              </li>
            </ul>
            <p className="text-neutral-300">
              We do not sell your data, run ads, or share data with third
              parties for advertising or analytics.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Third parties</h2>
            <ul className="list-disc space-y-2 pl-5 text-neutral-300">
              <li>
                <strong>Supabase</strong> — backend hosting and storage of
                your account data.
              </li>
              <li>
                <strong>RevenueCat</strong> — subscription management and
                entitlement checks.
              </li>
              <li>
                <strong>OpenAI / Anthropic</strong> — AI inference for photo,
                voice, and Coach features.
              </li>
              <li>
                <strong>Apple</strong> — App Store billing, HealthKit
                (on-device, with your permission).
              </li>
            </ul>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Children</h2>
            <p className="text-neutral-300">
              Voidpen is not directed at children under 13 and we do not
              knowingly collect data from them.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Data retention & deletion</h2>
            <p className="text-neutral-300">
              Your data is retained until you request deletion. Use our{" "}
              <Link
                href="/delete-account"
                className="text-[#a78bfa] hover:underline"
              >
                delete account page
              </Link>{" "}
              or email coduy96@gmail.com. We permanently remove your data
              within 30 days.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Your rights</h2>
            <p className="text-neutral-300">
              You can request access to, correction of, or deletion of your
              data at any time by emailing us at coduy96@gmail.com.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Contact</h2>
            <p className="text-neutral-300">
              Questions about privacy? Email{" "}
              <a
                href="mailto:coduy96@gmail.com"
                className="text-[#a78bfa] hover:underline"
              >
                coduy96@gmail.com
              </a>
              .
            </p>
          </section>
        </section>
      </main>
      <Footer />
    </>
  );
}
