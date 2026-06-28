import type { Metadata, Viewport } from "next";
import { LandingPage } from "@/components/landing/landing-page";
import { getDictionary } from "@/lib/i18n/dictionaries";
import {
  DEFAULT_LOCALE,
  getLocaleConfig,
  hrefLangAlternates,
  SITE_URL,
} from "@/lib/i18n/config";

/*
 * voidpen.com landing page — English (canonical root).
 *
 * The page markup is shared with every other language via <LandingPage>;
 * copy comes from the per-locale dictionaries in lib/i18n. Other languages
 * are served from app/[lang]/page.tsx, and proxy.ts redirects `/` to the
 * visitor's language. hreflang alternates tie all 15 versions together.
 */
export async function generateMetadata(): Promise<Metadata> {
  const dict = await getDictionary(DEFAULT_LOCALE);
  return {
    title: { absolute: dict.meta.title },
    description: dict.meta.description,
    alternates: {
      canonical: SITE_URL,
      languages: hrefLangAlternates(),
    },
  };
}

export const viewport: Viewport = {
  themeColor: "#F6EFE4",
};

export default async function Home() {
  const dict = await getDictionary(DEFAULT_LOCALE);
  return <LandingPage dict={dict} locale={getLocaleConfig(DEFAULT_LOCALE)} />;
}
