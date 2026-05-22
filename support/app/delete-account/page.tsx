import Link from "next/link";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";

export const metadata = {
  title: "Delete account",
  description:
    "Request permanent deletion of your Voidpen account and associated data. Processed within 30 days.",
};

export default function DeleteAccountPage() {
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
            Delete account
          </h1>
          <p className="mt-4 text-lg text-neutral-400">
            We honour deletion requests within 30 days. You don’t need a login
            — your data is tied to an anonymous install ID on your device.
          </p>

          <section className="mt-10 space-y-4 rounded-2xl border border-neutral-800 bg-neutral-900/50 p-6">
            <h2 className="text-xl font-semibold">How to request deletion</h2>
            <ol className="list-decimal space-y-3 pl-5 text-neutral-300">
              <li>
                Open Voidpen on your iPhone.
              </li>
              <li>
                Go to <strong>Settings → About</strong> and copy your{" "}
                <strong>Install ID</strong>.
              </li>
              <li>
                Email us at{" "}
                <a
                  href="mailto:coduy96@gmail.com?subject=Delete%20my%20Voidpen%20data"
                  className="text-[#a78bfa] hover:underline"
                >
                  coduy96@gmail.com
                </a>{" "}
                with the subject <em>“Delete my Voidpen data”</em> and paste
                your Install ID in the body.
              </li>
            </ol>
            <p className="text-sm text-neutral-500">
              If you can’t find your Install ID, just email us — we can match
              by device or subscription receipt.
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">What gets deleted</h2>
            <ul className="list-disc space-y-2 pl-5 text-neutral-300">
              <li>All food and meal entries you’ve logged.</li>
              <li>Weight, height, and body composition history.</li>
              <li>Chat history with the AI Coach.</li>
              <li>Your anonymous install record.</li>
            </ul>
            <p className="text-sm text-neutral-500">
              Note: subscription records held by Apple and RevenueCat for
              billing/compliance are not deletable by us. Cancel your
              subscription separately at{" "}
              <strong>
                Settings → Apple ID → Subscriptions → Voidpen → Cancel
              </strong>
              .
            </p>
          </section>

          <section className="mt-10 space-y-4">
            <h2 className="text-xl font-semibold">After deletion</h2>
            <p className="text-neutral-300">
              We’ll email you a confirmation when your data is removed.
              Deletion is permanent — we can’t restore it later. If you reopen
              the app afterwards, you’ll start with a clean slate.
            </p>
          </section>
        </section>
      </main>
      <Footer />
    </>
  );
}
