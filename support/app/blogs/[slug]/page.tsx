import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { compileMDX } from "next-mdx-remote/rsc";
import remarkGfm from "remark-gfm";
import rehypeSlug from "rehype-slug";
import rehypeAutolinkHeadings from "rehype-autolink-headings";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";
import { DownloadCTA } from "@/components/blog/download-cta";
import { PostCard } from "@/components/blog/post-card";
import { mdxComponents } from "@/components/blog/mdx-components";
import {
  CATEGORY_LABELS,
  formatDate,
  getAllSlugs,
  getPostBySlug,
  getRelatedPosts,
} from "@/lib/blog";

const siteUrl = "https://voidpen.com";

export function generateStaticParams() {
  return getAllSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) return {};
  const url = `${siteUrl}/blogs/${slug}`;
  return {
    title: post.title,
    description: post.description,
    keywords: post.keywords,
    alternates: { canonical: url },
    openGraph: {
      type: "article",
      url,
      title: post.title,
      description: post.description,
      publishedTime: post.date,
      modifiedTime: post.updated ?? post.date,
      authors: [post.author],
    },
    twitter: {
      card: "summary_large_image",
      title: post.title,
      description: post.description,
    },
  };
}

export default async function PostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) notFound();

  const { content } = await compileMDX({
    source: post.content,
    components: mdxComponents,
    options: {
      mdxOptions: {
        remarkPlugins: [remarkGfm],
        rehypePlugins: [
          rehypeSlug,
          [rehypeAutolinkHeadings, { behavior: "wrap" }],
        ],
      },
    },
  });

  const related = getRelatedPosts(slug, 2);
  const url = `${siteUrl}/blogs/${slug}`;

  const articleLd = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.description,
    image: `${siteUrl}${post.heroImage}`,
    datePublished: post.date,
    dateModified: post.updated ?? post.date,
    author: { "@type": "Organization", name: post.author },
    publisher: {
      "@type": "Organization",
      name: "Voidpen",
      logo: {
        "@type": "ImageObject",
        url: `${siteUrl}/voidpen-logo.png`,
      },
    },
    mainEntityOfPage: { "@type": "WebPage", "@id": url },
  };

  const breadcrumbLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Home", item: siteUrl },
      { "@type": "ListItem", position: 2, name: "Blog", item: `${siteUrl}/blogs` },
      { "@type": "ListItem", position: 3, name: post.title, item: url },
    ],
  };

  return (
    <>
      <Header />
      <main className="w-full flex-1">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(articleLd) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbLd) }}
        />
        <article className="mx-auto max-w-3xl px-6 py-12 sm:py-16">
          <nav
            aria-label="Breadcrumb"
            className="flex items-center gap-2 text-sm text-ink-soft"
          >
            <Link href="/" className="transition hover:text-accent">
              Home
            </Link>
            <span aria-hidden>/</span>
            <Link href="/blogs" className="transition hover:text-accent">
              Blog
            </Link>
          </nav>

          <span className="mt-8 inline-block text-xs font-bold uppercase tracking-[0.08em] text-accent">
            {CATEGORY_LABELS[post.category]}
          </span>
          <h1 className="mt-3 font-display text-4xl font-black uppercase leading-[1.0] tracking-tight text-ink sm:text-5xl">
            {post.title}
          </h1>
          <div className="mt-4 flex flex-wrap items-center gap-2 text-sm text-ink-soft">
            <span>{post.author}</span>
            <span aria-hidden>·</span>
            <time dateTime={post.date}>{formatDate(post.date)}</time>
            <span aria-hidden>·</span>
            <span>{post.readingTime} min read</span>
          </div>

          <div className="relative mt-8 aspect-[16/9] w-full overflow-hidden rounded-3xl border border-line">
            <Image
              src={post.heroImage}
              alt={post.heroAlt}
              fill
              priority
              sizes="(max-width: 768px) 100vw, 768px"
              className="object-cover"
            />
          </div>

          <div className="prose prose-voidpen mt-10 max-w-none">{content}</div>

          <div className="mt-12">
            <DownloadCTA />
          </div>
        </article>

        {related.length > 0 && (
          <section className="mx-auto max-w-6xl px-6 pb-20">
            <h2 className="font-display text-2xl font-black uppercase tracking-tight text-ink">
              Keep reading
            </h2>
            <div className="mt-6 grid gap-8 sm:grid-cols-2">
              {related.map((p) => (
                <PostCard key={p.slug} post={p} />
              ))}
            </div>
          </section>
        )}
      </main>
      <Footer />
    </>
  );
}
