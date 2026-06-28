import type { Metadata, Viewport } from "next";
import { notFound } from "next/navigation";
import { LandingPage } from "@/components/landing/landing-page";
import { getDictionary } from "@/lib/i18n/dictionaries";
import {
  DEFAULT_LOCALE,
  NON_DEFAULT_LOCALES,
  getLocaleConfig,
  hrefLangAlternates,
  isLocale,
  localePath,
  SITE_URL,
} from "@/lib/i18n/config";

/*
 * Localized landing page for every non-English language (/de, /vi, /zh, …).
 * English keeps the canonical root (app/page.tsx). Only the 15 screenshot/
 * App-Store locales are generated; anything else 404s.
 */
type Params = { params: Promise<{ lang: string }> };

// Only pre-render the known locales; unknown segments return 404.
export const dynamicParams = false;

export function generateStaticParams() {
  return NON_DEFAULT_LOCALES.map((l) => ({ lang: l.code }));
}

export const viewport: Viewport = {
  themeColor: "#F6EFE4",
};

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { lang } = await params;
  if (!isLocale(lang) || lang === DEFAULT_LOCALE) return {};
  const dict = await getDictionary(lang);
  return {
    title: { absolute: dict.meta.title },
    description: dict.meta.description,
    alternates: {
      canonical: `${SITE_URL}${localePath(lang)}`,
      languages: hrefLangAlternates(),
    },
  };
}

export default async function LocalizedHome({ params }: Params) {
  const { lang } = await params;
  if (!isLocale(lang) || lang === DEFAULT_LOCALE) notFound();
  const dict = await getDictionary(lang);
  return <LandingPage dict={dict} locale={getLocaleConfig(lang)} />;
}
