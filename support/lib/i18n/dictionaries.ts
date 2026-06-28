import "server-only";

import type en from "./dictionaries/en.json";

/**
 * The shape of every landing-page dictionary is derived from the canonical
 * English file, so adding a key in en.json immediately type-checks every
 * consumer (and every translation must keep the same keys to compile).
 */
export type Dictionary = typeof en;

// One dynamic import per locale. These only ever run on the server, so the
// translation JSON never ships to the client bundle.
const dictionaries: Record<string, () => Promise<Dictionary>> = {
  en: () => import("./dictionaries/en.json").then((m) => m.default),
  de: () => import("./dictionaries/de.json").then((m) => m.default),
  es: () => import("./dictionaries/es.json").then((m) => m.default),
  fr: () => import("./dictionaries/fr.json").then((m) => m.default),
  it: () => import("./dictionaries/it.json").then((m) => m.default),
  nl: () => import("./dictionaries/nl.json").then((m) => m.default),
  pt: () => import("./dictionaries/pt.json").then((m) => m.default),
  ro: () => import("./dictionaries/ro.json").then((m) => m.default),
  ru: () => import("./dictionaries/ru.json").then((m) => m.default),
  ar: () => import("./dictionaries/ar.json").then((m) => m.default),
  hi: () => import("./dictionaries/hi.json").then((m) => m.default),
  ja: () => import("./dictionaries/ja.json").then((m) => m.default),
  ko: () => import("./dictionaries/ko.json").then((m) => m.default),
  vi: () => import("./dictionaries/vi.json").then((m) => m.default),
  zh: () => import("./dictionaries/zh.json").then((m) => m.default),
};

export async function getDictionary(code: string): Promise<Dictionary> {
  const load = dictionaries[code] ?? dictionaries.en;
  return load();
}
