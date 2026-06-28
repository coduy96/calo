import { NextResponse, type NextRequest } from "next/server";
import { DEFAULT_LOCALE, LOCALE_CODES } from "@/lib/i18n/config";

/*
 * Language redirect for the landing page.
 *
 * Runs ONLY on `/` (and `/en`, which folds back to `/`). It sends a visitor
 * to their language's sub-path based on an explicit `NEXT_LOCALE` cookie, or
 * failing that the browser's Accept-Language. English stays on the canonical
 * root, so no redirect fires for English speakers and there is no loop
 * (the locale sub-paths like `/de` are outside the matcher).
 */

// Accept-Language primary subtag -> URL locale code. Mostly identity; a few
// families fold into one storefront code.
const SUBTAG_TO_CODE: Record<string, string> = {
  en: "en",
  de: "de",
  es: "es",
  fr: "fr",
  it: "it",
  nl: "nl",
  pt: "pt",
  ro: "ro",
  ru: "ru",
  ar: "ar",
  hi: "hi",
  ja: "ja",
  ko: "ko",
  vi: "vi",
  zh: "zh",
};

function detectLocale(acceptLanguage: string | null): string {
  if (!acceptLanguage) return DEFAULT_LOCALE;
  const ranked = acceptLanguage
    .split(",")
    .map((part) => {
      const [tag, q] = part.trim().split(";q=");
      return { tag: tag.toLowerCase(), q: q ? Number.parseFloat(q) : 1 };
    })
    .filter((x) => x.tag)
    .sort((a, b) => b.q - a.q);

  for (const { tag } of ranked) {
    const code = SUBTAG_TO_CODE[tag.split("-")[0]];
    if (code && LOCALE_CODES.includes(code)) return code;
  }
  return DEFAULT_LOCALE;
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // English lives at `/`, so `/en` is not a real route — fold it back.
  if (pathname === "/en") {
    return NextResponse.redirect(new URL("/", request.url));
  }

  const cookie = request.cookies.get("NEXT_LOCALE")?.value;
  const chosen =
    cookie && LOCALE_CODES.includes(cookie)
      ? cookie
      : detectLocale(request.headers.get("accept-language"));

  if (chosen !== DEFAULT_LOCALE) {
    return NextResponse.redirect(new URL(`/${chosen}`, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/en"],
};
