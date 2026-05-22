import Link from "next/link";

export function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-neutral-900/70 bg-[#0a0a0a]/80 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-[#a78bfa] to-[#7c3aed] text-sm font-bold text-neutral-950">
            V
          </span>
          <span className="text-sm font-semibold tracking-tight">Voidpen</span>
        </Link>
        <nav className="flex items-center gap-1 text-sm text-neutral-400 sm:gap-2">
          <Link
            href="/support"
            className="rounded-md px-3 py-1.5 transition hover:bg-neutral-900 hover:text-neutral-100"
          >
            Support
          </Link>
          <Link
            href="/privacy"
            className="hidden rounded-md px-3 py-1.5 transition hover:bg-neutral-900 hover:text-neutral-100 sm:inline-flex"
          >
            Privacy
          </Link>
          <Link
            href="/terms"
            className="hidden rounded-md px-3 py-1.5 transition hover:bg-neutral-900 hover:text-neutral-100 sm:inline-flex"
          >
            Terms
          </Link>
        </nav>
      </div>
    </header>
  );
}
