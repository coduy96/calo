/*
 * Locale registry for the voidpen.com landing page.
 *
 * The landing is the only localized surface — blog and legal pages stay
 * English. English is served at the canonical root (`/`); every other
 * language lives at a short sub-path (`/de`, `/vi`, `/zh`, …). A `proxy.ts`
 * at the repo root redirects `/` to the visitor's language.
 *
 *   code     — URL segment AND dictionary filename (en, de, pt, zh, …)
 *   hrefLang — BCP-47 tag for <link hreflang> + <html lang> on the wrapper
 *   dir      — text direction (ar is the only RTL language)
 *   label    — native language name shown in the switcher
 */
export type Dir = "ltr" | "rtl";

export interface LocaleConfig {
  code: string;
  hrefLang: string;
  dir: Dir;
  label: string;
}

export const DEFAULT_LOCALE = "en";

export const LOCALES: LocaleConfig[] = [
  { code: "en", hrefLang: "en", dir: "ltr", label: "English" },
  { code: "de", hrefLang: "de", dir: "ltr", label: "Deutsch" },
  { code: "es", hrefLang: "es", dir: "ltr", label: "Español" },
  { code: "fr", hrefLang: "fr", dir: "ltr", label: "Français" },
  { code: "it", hrefLang: "it", dir: "ltr", label: "Italiano" },
  { code: "nl", hrefLang: "nl", dir: "ltr", label: "Nederlands" },
  { code: "pt", hrefLang: "pt-BR", dir: "ltr", label: "Português" },
  { code: "ro", hrefLang: "ro", dir: "ltr", label: "Română" },
  { code: "ru", hrefLang: "ru", dir: "ltr", label: "Русский" },
  { code: "ar", hrefLang: "ar", dir: "rtl", label: "العربية" },
  { code: "hi", hrefLang: "hi", dir: "ltr", label: "हिन्दी" },
  { code: "ja", hrefLang: "ja", dir: "ltr", label: "日本語" },
  { code: "ko", hrefLang: "ko", dir: "ltr", label: "한국어" },
  { code: "vi", hrefLang: "vi", dir: "ltr", label: "Tiếng Việt" },
  { code: "zh", hrefLang: "zh-Hans", dir: "ltr", label: "中文" },
];

/** Locale codes other than the default — these are the `[lang]` segments. */
export const NON_DEFAULT_LOCALES = LOCALES.filter(
  (l) => l.code !== DEFAULT_LOCALE,
);

export const LOCALE_CODES = LOCALES.map((l) => l.code);

const BY_CODE = new Map(LOCALES.map((l) => [l.code, l]));

export function isLocale(code: string | undefined): boolean {
  return code !== undefined && BY_CODE.has(code);
}

export function getLocaleConfig(code: string): LocaleConfig {
  return BY_CODE.get(code) ?? LOCALES[0];
}

/**
 * The URL path for a locale: `/` for English, `/{code}` for everything else.
 * Used by the language switcher and the hreflang alternates.
 */
export function localePath(code: string): string {
  return code === DEFAULT_LOCALE ? "/" : `/${code}`;
}

export const SITE_URL = "https://voidpen.com";

/**
 * `alternates.languages` map for SEO hreflang tags. Keys are BCP-47 tags,
 * values are absolute URLs. Includes `x-default` pointing at the English root.
 */
export function hrefLangAlternates(): Record<string, string> {
  const languages: Record<string, string> = {};
  for (const l of LOCALES) {
    languages[l.hrefLang] =
      l.code === DEFAULT_LOCALE ? SITE_URL : `${SITE_URL}/${l.code}`;
  }
  languages["x-default"] = SITE_URL;
  return languages;
}
