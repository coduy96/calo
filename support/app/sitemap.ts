import type { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/blog";

const siteUrl = "https://voidpen.com";

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  const posts = getAllPosts().map((p) => ({
    url: `${siteUrl}/blogs/${p.slug}`,
    lastModified: new Date(p.updated ?? p.date),
    priority: 0.7,
  }));
  return [
    { url: `${siteUrl}/`, lastModified, priority: 1 },
    { url: `${siteUrl}/blogs`, lastModified, priority: 0.8 },
    ...posts,
    { url: `${siteUrl}/support`, lastModified, priority: 0.9 },
    { url: `${siteUrl}/privacy`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/terms`, lastModified, priority: 0.6 },
    { url: `${siteUrl}/delete-account`, lastModified, priority: 0.5 },
  ];
}
