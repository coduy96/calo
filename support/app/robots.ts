import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/" },
    sitemap: "https://voidpen.com/sitemap.xml",
    host: "https://voidpen.com",
  };
}
