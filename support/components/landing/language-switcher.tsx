"use client";

import { useRouter } from "next/navigation";
import type { ChangeEvent } from "react";
import { LOCALES, localePath } from "@/lib/i18n/config";

/**
 * Compact language picker for the landing nav (and mobile menu).
 *
 * Selecting a language writes a `NEXT_LOCALE` cookie so the root-level
 * `proxy.ts` honours the explicit choice over the browser's Accept-Language,
 * then routes to the locale path (`/` for English, `/{code}` otherwise).
 */
export function LanguageSwitcher({
  current,
  label,
}: {
  current: string;
  label: string;
}) {
  const router = useRouter();

  function onChange(e: ChangeEvent<HTMLSelectElement>) {
    const code = e.target.value;
    document.cookie = `NEXT_LOCALE=${code}; path=/; max-age=31536000; samesite=lax`;
    router.push(localePath(code));
  }

  return (
    <label className="lang-switch" aria-label={label} title={label}>
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        aria-hidden="true"
      >
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18M12 3c2.5 2.5 2.5 15 0 18M12 3c-2.5 2.5-2.5 15 0 18" />
      </svg>
      <select value={current} onChange={onChange} aria-label={label}>
        {LOCALES.map((l) => (
          <option key={l.code} value={l.code}>
            {l.label}
          </option>
        ))}
      </select>
    </label>
  );
}
