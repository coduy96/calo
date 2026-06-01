import Image from "next/image";
import Link from "next/link";

export function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-line/70 bg-cream/80 backdrop-blur">
      <div className="mx-auto flex h-[76px] max-w-6xl items-center justify-between px-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="grid h-10 w-10 place-items-center overflow-hidden rounded-[11px] bg-white shadow-[0_8px_18px_rgba(255,90,31,0.28)]">
            <Image
              src="/voidpen-logo.png"
              alt="voidpen logo"
              width={40}
              height={40}
            />
          </span>
          <span className="font-display text-[1.35rem] font-black lowercase tracking-tight text-ink">
            voidpen
          </span>
        </Link>
        <nav className="flex items-center gap-1 text-sm font-semibold text-ink-2 sm:gap-3">
          <Link
            href="/support"
            className="rounded-md px-3 py-1.5 transition hover:text-accent"
          >
            Support
          </Link>
          <Link
            href="/privacy"
            className="hidden rounded-md px-3 py-1.5 transition hover:text-accent sm:inline-flex"
          >
            Privacy
          </Link>
          <Link
            href="/terms"
            className="hidden rounded-md px-3 py-1.5 transition hover:text-accent sm:inline-flex"
          >
            Terms
          </Link>
        </nav>
      </div>
    </header>
  );
}
