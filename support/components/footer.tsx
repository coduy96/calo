import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-neutral-900">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-6 py-10 text-sm text-neutral-500 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-md bg-gradient-to-br from-[#a78bfa] to-[#7c3aed] text-xs font-bold text-neutral-950">
            V
          </span>
          <p>© 2026 Voidpen · Co Trinh Hien Duy</p>
        </div>
        <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
          <Link href="/" className="transition hover:text-neutral-200">
            Home
          </Link>
          <Link href="/support" className="transition hover:text-neutral-200">
            Support
          </Link>
          <Link href="/privacy" className="transition hover:text-neutral-200">
            Privacy
          </Link>
          <Link href="/terms" className="transition hover:text-neutral-200">
            Terms
          </Link>
          <Link
            href="/delete-account"
            className="transition hover:text-neutral-200"
          >
            Delete account
          </Link>
          <a
            href="mailto:coduy96@gmail.com"
            className="transition hover:text-neutral-200"
          >
            Contact
          </a>
        </div>
      </div>
    </footer>
  );
}
