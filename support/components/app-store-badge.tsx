type Props = {
  href?: string;
  className?: string;
};

export function AppStoreBadge({ href = "#", className = "" }: Props) {
  return (
    <a
      href={href}
      className={`group inline-flex items-center gap-3 rounded-xl bg-white px-5 py-3 text-neutral-950 shadow-lg shadow-[#a78bfa]/10 transition hover:scale-[1.02] hover:bg-neutral-100 active:scale-[0.99] ${className}`}
    >
      <svg
        width="26"
        height="26"
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden="true"
      >
        <path d="M16.365 1.43c0 1.14-.42 2.21-1.12 3.01-.84.97-2.21 1.72-3.36 1.63-.13-1.13.42-2.31 1.12-3.07.78-.86 2.13-1.49 3.36-1.57Zm3.71 17.04c-.66 1.45-.98 2.1-1.83 3.38-1.19 1.79-2.86 4.02-4.92 4.05-1.84.03-2.31-1.2-4.81-1.18-2.5.02-3.02 1.2-4.86 1.18-2.07-.03-3.65-2.04-4.84-3.83-3.34-5.05-3.69-10.99-1.63-14.15 1.46-2.25 3.78-3.56 5.95-3.56 2.21 0 3.6 1.22 5.43 1.22 1.78 0 2.86-1.22 5.42-1.22 1.94 0 3.99 1.05 5.46 2.87-4.81 2.64-4.03 9.51.42 10.84Z" />
      </svg>
      <div className="flex flex-col leading-tight">
        <span className="text-[10px] font-medium tracking-wide text-neutral-600">
          Download on the
        </span>
        <span className="text-base font-semibold">App Store</span>
      </div>
    </a>
  );
}
