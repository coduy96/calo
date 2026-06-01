import Image from "next/image";
import Link from "next/link";

const social = {
  x: "M17.5 3h3l-6.6 7.5L21.8 21h-6l-4.3-5.6L6.4 21H3.3l7-8L2.5 3h6.1l3.9 5.1L17.5 3Zm-1.1 16h1.7L7.8 4.8H6L16.4 19Z",
  ig: "",
};

export function Footer() {
  return (
    <footer className="border-t border-line bg-cream">
      <div className="mx-auto max-w-6xl px-6 py-12">
        <div className="flex flex-col gap-10 sm:flex-row sm:items-start sm:justify-between">
          <div className="max-w-xs">
            <Link href="/" className="flex items-center gap-2.5">
              <span className="grid h-9 w-9 place-items-center overflow-hidden rounded-[10px] bg-white shadow-[0_8px_18px_rgba(255,90,31,0.28)]">
                <Image
                  src="/voidpen-logo.png"
                  alt="voidpen logo"
                  width={36}
                  height={36}
                />
              </span>
              <span className="font-display text-lg font-black lowercase tracking-tight text-ink">
                voidpen
              </span>
            </Link>
            <p className="mt-4 text-sm leading-relaxed text-ink-soft">
              AI nutrition tracking that keeps up with how you actually eat.
              Snap, speak, scan or type.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-x-12 gap-y-8 sm:grid-cols-3">
            <div>
              <h5 className="text-xs font-extrabold uppercase tracking-[0.08em] text-ink">
                Product
              </h5>
              <ul className="mt-4 flex flex-col gap-2.5 text-sm font-medium text-ink-soft">
                <li>
                  <Link href="/" className="transition hover:text-accent">
                    Home
                  </Link>
                </li>
                <li>
                  <Link href="/blogs" className="transition hover:text-accent">
                    Blog
                  </Link>
                </li>
                <li>
                  <Link href="/support" className="transition hover:text-accent">
                    Support
                  </Link>
                </li>
              </ul>
            </div>
            <div>
              <h5 className="text-xs font-extrabold uppercase tracking-[0.08em] text-ink">
                Legal
              </h5>
              <ul className="mt-4 flex flex-col gap-2.5 text-sm font-medium text-ink-soft">
                <li>
                  <Link href="/privacy" className="transition hover:text-accent">
                    Privacy
                  </Link>
                </li>
                <li>
                  <Link href="/terms" className="transition hover:text-accent">
                    Terms
                  </Link>
                </li>
                <li>
                  <Link
                    href="/delete-account"
                    className="transition hover:text-accent"
                  >
                    Delete account
                  </Link>
                </li>
              </ul>
            </div>
            <div>
              <h5 className="text-xs font-extrabold uppercase tracking-[0.08em] text-ink">
                Contact
              </h5>
              <ul className="mt-4 flex flex-col gap-2.5 text-sm font-medium text-ink-soft">
                <li>
                  <a
                    href="mailto:info@voidpen.com"
                    className="transition hover:text-accent"
                  >
                    info@voidpen.com
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mt-10 flex flex-col gap-4 border-t border-line pt-6 text-sm text-ink-soft sm:flex-row sm:items-center sm:justify-between">
          <span>
            © 2026 <span className="font-display lowercase">voidpen</span>. All
            rights reserved.
          </span>
          <div className="flex gap-3">
            <a
              href="#"
              aria-label="X"
              className="grid h-9 w-9 place-items-center rounded-full bg-white text-ink-2 shadow-soft transition hover:-translate-y-0.5 hover:text-accent"
            >
              <svg viewBox="0 0 24 24" fill="currentColor" className="h-[18px] w-[18px]">
                <path d={social.x} />
              </svg>
            </a>
            <a
              href="#"
              aria-label="Instagram"
              className="grid h-9 w-9 place-items-center rounded-full bg-white text-ink-2 shadow-soft transition hover:-translate-y-0.5 hover:text-accent"
            >
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="h-[18px] w-[18px]"
              >
                <rect x="3" y="3" width="18" height="18" rx="5" />
                <circle cx="12" cy="12" r="4" />
                <circle cx="17.5" cy="6.5" r="1.2" fill="currentColor" stroke="none" />
              </svg>
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
