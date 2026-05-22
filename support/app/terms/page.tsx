import Link from "next/link";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";

export const metadata = {
  title: "Terms of Service",
  description:
    "Terms of service for Voidpen: Calorie Tracker, including subscription terms and governing law.",
};

export default function TermsPage() {
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
            Terms of Service
          </h1>
          <p className="mt-3 text-sm text-neutral-500">
            Last updated: May 2026
          </p>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Use of the app</h2>
            <p className="text-neutral-300">
              Voidpen is provided on an &ldquo;AS IS&rdquo; and &ldquo;AS
              AVAILABLE&rdquo; basis, without warranties of any kind, either
              express or implied. Voidpen is a tool for tracking calories and
              is not a substitute for professional medical, dietary, or
              fitness advice. Always consult a qualified professional before
              making significant changes to your diet or activity level.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Subscriptions</h2>
            <p className="text-neutral-300">
              Voidpen offers auto-renewing subscriptions in terms of 1 week, 1
              month, and 1 year. Payment is charged to your Apple ID account
              at confirmation of purchase. Subscriptions automatically renew
              unless auto-renew is turned off at least 24 hours before the end
              of the current period. Your account is charged for renewal
              within 24 hours prior to the end of the current period.
            </p>
            <p className="text-neutral-300">
              You can manage and cancel your subscription by going to your
              Account Settings on the App Store after purchase:{" "}
              <strong>
                Settings → Apple ID → Subscriptions → Voidpen → Cancel
              </strong>
              . Your access continues until the end of the current period.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Refunds</h2>
            <p className="text-neutral-300">
              All purchases are processed by Apple. Refund requests must be
              made through Apple at{" "}
              <a
                href="https://reportaproblem.apple.com"
                className="text-[#a78bfa] hover:underline"
                target="_blank"
                rel="noreferrer"
              >
                reportaproblem.apple.com
              </a>
              .
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Acceptable use</h2>
            <p className="text-neutral-300">
              You agree not to misuse the service — including attempting to
              reverse engineer, abuse the AI features, or use the service for
              unlawful activity. We may suspend access if these terms are
              breached.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Governing law</h2>
            <p className="text-neutral-300">
              These terms are governed by the laws of Vietnam.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Changes</h2>
            <p className="text-neutral-300">
              We may update these terms occasionally. Material changes will be
              announced in the app or on this page.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">Contact</h2>
            <p className="text-neutral-300">
              Questions about these terms? Email{" "}
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
