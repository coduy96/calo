import type { Metadata } from "next";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";
import { DownloadCTA } from "@/components/blog/download-cta";
import { PostCard } from "@/components/blog/post-card";
import { getAllPosts } from "@/lib/blog";

const siteUrl = "https://voidpen.com";

export const metadata: Metadata = {
  title: "Blog — AI calorie tracking tips, guides & app comparisons",
  description:
    "Honest guides, app comparisons, and effortless calorie-tracking tips from the Voidpen team. Learn how AI photo food tracking actually works.",
  alternates: { canonical: `${siteUrl}/blogs` },
  openGraph: {
    type: "website",
    url: `${siteUrl}/blogs`,
    title: "The Voidpen Blog",
    description:
      "Guides, comparisons, and tips for effortless AI calorie tracking.",
  },
};

export default function BlogIndexPage() {
  const posts = getAllPosts();
  const featured = posts.find((p) => p.featured) ?? posts[0];
  const rest = posts.filter((p) => p.slug !== featured?.slug);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: "Voidpen Blog",
    url: `${siteUrl}/blogs`,
    description:
      "Guides, comparisons, and tips for effortless AI calorie tracking.",
    blogPost: posts.map((p) => ({
      "@type": "BlogPosting",
      headline: p.title,
      url: `${siteUrl}/blogs/${p.slug}`,
      datePublished: p.date,
      dateModified: p.updated ?? p.date,
    })),
  };

  return (
    <>
      <Header />
      <main className="w-full flex-1">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        <section className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
          <p className="text-sm font-bold uppercase tracking-[0.12em] text-accent">
            The Voidpen Blog
          </p>
          <h1 className="mt-3 max-w-3xl font-display text-4xl font-black uppercase leading-[0.95] tracking-tight text-ink sm:text-6xl">
            Eat smarter, track effortlessly
          </h1>
          <p className="mt-4 max-w-2xl text-lg text-ink-2">
            Honest guides, app comparisons, and the real science of calorie
            tracking — from the team building the easiest way to log food.
          </p>

          {featured && (
            <div className="mt-12">
              <PostCard post={featured} featured />
            </div>
          )}

          {rest.length > 0 && (
            <div className="mt-8 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
              {rest.map((p) => (
                <PostCard key={p.slug} post={p} />
              ))}
            </div>
          )}

          {posts.length === 0 && (
            <p className="mt-12 text-ink-soft">New articles are coming soon.</p>
          )}

          <div className="mt-16">
            <DownloadCTA />
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
