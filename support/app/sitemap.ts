import type { MetadataRoute } from "next";

const siteUrl = "https://voidpen.com";

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  return [
    { url: `${siteUrl}/`, lastModified, priority: 1 },
    { url: `${siteUrl}/support`, lastModified, priority: 0.9 },
    { url: `${siteUrl}/privacy`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/terms`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/delete-account`, lastModified, priority: 0.5 },
  ];
}
