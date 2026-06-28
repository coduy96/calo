import type { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/blog";
import { hrefLangAlternates } from "@/lib/i18n/config";

const siteUrl = "https://voidpen.com";

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  const posts = getAllPosts().map((p) => ({
    url: `${siteUrl}/blogs/${p.slug}`,
    lastModified: new Date(p.updated ?? p.date),
    priority: 0.7,
  }));
  return [
    {
      // The landing page exists in 15 languages; declare them all as
      // hreflang alternates of the canonical root so search engines cluster
      // them. (/de, /fr, … are reachable from these alternates.)
      url: `${siteUrl}/`,
      lastModified,
      priority: 1,
      alternates: { languages: hrefLangAlternates() },
    },
    { url: `${siteUrl}/blogs`, lastModified, priority: 0.8 },
    ...posts,
    { url: `${siteUrl}/support`, lastModified, priority: 0.9 },
    { url: `${siteUrl}/privacy`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/terms`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/delete-account`, lastModified, priority: 0.5 },
  ];
}
