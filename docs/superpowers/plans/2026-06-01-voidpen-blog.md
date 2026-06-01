# Voidpen Blog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an SEO-optimized blog at `voidpen.com/blogs` (inside the `support/` Next.js app) with a reusable MDX engine and 6 publish-ready, conversion-focused articles.

**Architecture:** MDX files in `content/blog/` are read at build time by a typed content library (`lib/blog.ts`), rendered through `next-mdx-remote/rsc` on statically-generated routes (`/blogs`, `/blogs/[slug]`). SEO is handled via per-post `generateMetadata`, JSON-LD structured data, a dynamic sitemap, and auto-generated branded OG images. Images are royalty-free (Unsplash/Pexels) self-hosted in `public/blog/`, plus existing app screenshots.

**Tech Stack:** Next.js 16.2.6 (App Router, async params), React 19, Tailwind v4, TypeScript, `next-mdx-remote`, `gray-matter`, `remark-gfm`, `rehype-slug`, `rehype-autolink-headings`, `@tailwindcss/typography`, `vitest`.

**CRITICAL — read before coding:** `support/AGENTS.md` warns this Next.js (16) has breaking changes vs. training data. Dynamic route `params` is a **Promise** and must be `await`ed. Reference docs live in `support/node_modules/next/dist/docs/01-app/`. All commands below run from the `support/` directory unless noted.

---

## File map

| File | Responsibility |
|------|----------------|
| `support/lib/blog.ts` | Content library: types, `getAllPosts`, `getPostBySlug`, `getAllSlugs`, `getRelatedPosts`, `readingTime`, `formatDate`, `CATEGORY_LABELS` |
| `support/lib/blog.test.ts` | Vitest unit tests for the library |
| `support/lib/__fixtures__/blog/post-{a,b}.mdx` | Deterministic test fixtures |
| `support/vitest.config.ts` | Vitest config |
| `support/components/blog/download-cta.tsx` | Reusable App Store CTA block |
| `support/components/blog/callout.tsx` | Highlighted tip/note box |
| `support/components/blog/post-card.tsx` | Card for the index grid |
| `support/components/blog/mdx-components.tsx` | MDX component map (`DownloadCTA`, `Callout`, `Figure`, `AppShot`, custom links) |
| `support/app/blogs/page.tsx` | Blog index + `Blog` JSON-LD |
| `support/app/blogs/[slug]/page.tsx` | Post page + `BlogPosting`/`BreadcrumbList` JSON-LD |
| `support/app/blogs/[slug]/opengraph-image.tsx` | Per-post branded OG image |
| `support/assets/fonts/ArchivoBlack-Regular.ttf` | Font for OG image rendering |
| `support/app/globals.css` | Add typography plugin + `.prose-voidpen` brand theming |
| `support/app/sitemap.ts` | Add `/blogs` + every post |
| `support/components/header.tsx` | Add "Blog" nav link |
| `support/components/footer.tsx` | Add "Blog" footer link |
| `support/content/blog/*.mdx` | The 6 articles |
| `support/public/blog/<slug>/*` | Downloaded hero/body images |

---

## Task 1: Install dependencies & test harness

**Files:**
- Modify: `support/package.json`
- Create: `support/vitest.config.ts`

- [ ] **Step 1: Install runtime dependencies**

Run (from `support/`):
```bash
npm install next-mdx-remote@^5.0.0 gray-matter@^4.0.3 remark-gfm@^4.0.1 rehype-slug@^6.0.0 rehype-autolink-headings@^7.1.0
```
Expected: installs without error. If a React-19 peer-dependency error blocks `next-mdx-remote`, retry with `npm install next-mdx-remote@^5.0.0 --legacy-peer-deps`.

- [ ] **Step 2: Install dev dependencies**

Run:
```bash
npm install -D @tailwindcss/typography@^0.5.16 vitest@^3.0.0
```
Expected: installs without error.

- [ ] **Step 3: Add the test script**

In `support/package.json`, add `"test": "vitest run"` to the `scripts` object (after `"start"`).

- [ ] **Step 4: Create the vitest config**

Create `support/vitest.config.ts`:
```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["lib/**/*.test.ts"],
  },
});
```

- [ ] **Step 5: Verify the dev build still compiles**

Run: `npm run build`
Expected: PASS — "✓ Compiled successfully", existing 11 static pages generated. (No blog routes yet.)

- [ ] **Step 6: Commit**

```bash
git add package.json package-lock.json vitest.config.ts
git commit -m "chore: add MDX, markdown, and test dependencies for blog"
```

---

## Task 2: Content library (`lib/blog.ts`) — TDD

**Files:**
- Create: `support/lib/__fixtures__/blog/post-a.mdx`, `support/lib/__fixtures__/blog/post-b.mdx`
- Create: `support/lib/blog.test.ts`
- Create: `support/lib/blog.ts`

- [ ] **Step 1: Create the test fixtures**

Create `support/lib/__fixtures__/blog/post-a.mdx`:
```mdx
---
title: Post A
description: Test post A description.
date: 2026-01-01
category: comparison
keywords: [a]
heroImage: /blog/post-a/hero.jpg
heroAlt: A
author: Voidpen Team
---
Body of A
```

Create `support/lib/__fixtures__/blog/post-b.mdx`:
```mdx
---
title: Post B
description: Test post B description.
date: 2026-02-01
category: comparison
keywords: [b]
heroImage: /blog/post-b/hero.jpg
heroAlt: B
author: Voidpen Team
---
Body of B
```

- [ ] **Step 2: Write the failing tests**

Create `support/lib/blog.test.ts`:
```ts
import { describe, it, expect } from "vitest";
import path from "node:path";
import {
  getAllPosts,
  getPostBySlug,
  getAllSlugs,
  readingTime,
  getRelatedPosts,
  formatDate,
} from "./blog";

const FIXTURES = path.join(__dirname, "__fixtures__", "blog");

describe("readingTime", () => {
  it("rounds words/200 to at least 1 minute", () => {
    expect(readingTime("word ".repeat(400))).toBe(2);
    expect(readingTime("short")).toBe(1);
  });
});

describe("getAllSlugs", () => {
  it("lists mdx files without extension", () => {
    expect(getAllSlugs(FIXTURES).sort()).toEqual(["post-a", "post-b"]);
  });
});

describe("getAllPosts", () => {
  it("returns posts newest-first by date with reading time", () => {
    const posts = getAllPosts(FIXTURES);
    expect(posts.map((p) => p.slug)).toEqual(["post-b", "post-a"]);
    expect(posts[0].readingTime).toBeGreaterThanOrEqual(1);
  });
});

describe("getPostBySlug", () => {
  it("returns null for an unknown slug", () => {
    expect(getPostBySlug("nope", FIXTURES)).toBeNull();
  });
  it("parses frontmatter and body", () => {
    const post = getPostBySlug("post-a", FIXTURES);
    expect(post?.title).toBe("Post A");
    expect(post?.content).toContain("Body of A");
  });
});

describe("getRelatedPosts", () => {
  it("excludes the current post and prefers same category", () => {
    const related = getRelatedPosts("post-a", 1, FIXTURES);
    expect(related).toHaveLength(1);
    expect(related[0].slug).toBe("post-b");
  });
});

describe("formatDate", () => {
  it("formats an ISO date as a long US date in UTC", () => {
    expect(formatDate("2026-06-01")).toBe("June 1, 2026");
  });
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `npm test`
Expected: FAIL — cannot resolve `./blog` (module not found).

- [ ] **Step 4: Implement the library**

Create `support/lib/blog.ts`:
```ts
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";

export type BlogCategory =
  | "comparison"
  | "ai-photo"
  | "educational"
  | "pain-point";

export interface PostFrontmatter {
  title: string;
  description: string;
  date: string;
  updated?: string;
  author: string;
  category: BlogCategory;
  keywords: string[];
  heroImage: string;
  heroAlt: string;
  featured?: boolean;
}

export interface Post extends PostFrontmatter {
  slug: string;
  content: string;
  readingTime: number;
}

const BLOG_DIR = path.join(process.cwd(), "content", "blog");

export const CATEGORY_LABELS: Record<BlogCategory, string> = {
  comparison: "Comparisons",
  "ai-photo": "AI & Photo",
  educational: "Guides",
  "pain-point": "Effortless Tracking",
};

export function readingTime(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 200));
}

export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  });
}

function parseFile(filePath: string, slug: string): Post {
  const raw = fs.readFileSync(filePath, "utf8");
  const { data, content } = matter(raw);
  const fm = data as PostFrontmatter;
  const required = [
    "title",
    "description",
    "date",
    "category",
    "heroImage",
    "heroAlt",
  ] as const;
  for (const key of required) {
    if (!fm[key]) {
      throw new Error(`Post "${slug}" is missing required frontmatter: ${key}`);
    }
  }
  return {
    ...fm,
    author: fm.author ?? "Voidpen Team",
    keywords: fm.keywords ?? [],
    slug,
    content,
    readingTime: readingTime(content),
  };
}

export function getAllSlugs(dir: string = BLOG_DIR): string[] {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".mdx"))
    .map((f) => f.replace(/\.mdx$/, ""));
}

export function getPostBySlug(slug: string, dir: string = BLOG_DIR): Post | null {
  const filePath = path.join(dir, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return null;
  return parseFile(filePath, slug);
}

export function getAllPosts(dir: string = BLOG_DIR): Post[] {
  return getAllSlugs(dir)
    .map((slug) => parseFile(path.join(dir, `${slug}.mdx`), slug))
    .sort((a, b) => (a.date < b.date ? 1 : -1));
}

export function getRelatedPosts(
  slug: string,
  limit: number = 2,
  dir: string = BLOG_DIR,
): Post[] {
  const all = getAllPosts(dir);
  const current = all.find((p) => p.slug === slug);
  if (!current) return all.slice(0, limit);
  const sameCat = all.filter(
    (p) => p.slug !== slug && p.category === current.category,
  );
  const others = all.filter(
    (p) => p.slug !== slug && p.category !== current.category,
  );
  return [...sameCat, ...others].slice(0, limit);
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `npm test`
Expected: PASS — all 6 test cases green.

- [ ] **Step 6: Commit**

```bash
git add lib/blog.ts lib/blog.test.ts lib/__fixtures__
git commit -m "feat: add typed blog content library with tests"
```

---

## Task 3: Themed article prose styles

**Files:**
- Modify: `support/app/globals.css`

- [ ] **Step 1: Add the typography plugin and brand prose theme**

In `support/app/globals.css`, immediately AFTER the existing first line `@import "tailwindcss";`, add:
```css
@plugin "@tailwindcss/typography";
```

Then append to the END of `support/app/globals.css`:
```css
/* Blog article prose — Voidpen brand theme over @tailwindcss/typography */
.prose-voidpen {
  --tw-prose-body: var(--color-ink-2);
  --tw-prose-headings: var(--color-ink);
  --tw-prose-links: var(--color-accent);
  --tw-prose-bold: var(--color-ink);
  --tw-prose-counters: var(--color-ink-soft);
  --tw-prose-bullets: var(--color-accent-2);
  --tw-prose-quotes: var(--color-ink);
  --tw-prose-quote-borders: var(--color-accent);
  --tw-prose-hr: var(--color-line);
  --tw-prose-captions: var(--color-ink-soft);
  --tw-prose-th-borders: var(--color-line);
  --tw-prose-td-borders: var(--color-line);
}
.prose-voidpen :is(h1, h2, h3, h4) {
  font-family: var(--font-display);
  letter-spacing: -0.01em;
}
.prose-voidpen :is(h2, h3) {
  scroll-margin-top: 5rem;
}
.prose-voidpen a {
  font-weight: 600;
  text-underline-offset: 2px;
}
```

- [ ] **Step 2: Verify the build compiles with the plugin loaded**

Run: `npm run build`
Expected: PASS. If the build errors on `@plugin "@tailwindcss/typography"`, the fallback is to remove that line and instead hand-style `.prose-voidpen` headings/paragraphs/lists/links directly (mirror the patterns in `app/landing.css`). Prefer the plugin; only fall back if it fails.

- [ ] **Step 3: Commit**

```bash
git add app/globals.css
git commit -m "feat: add brand-themed article prose styles"
```

---

## Task 4: Conversion + content components

**Files:**
- Create: `support/components/blog/download-cta.tsx`
- Create: `support/components/blog/callout.tsx`
- Create: `support/components/blog/post-card.tsx`
- Create: `support/components/blog/mdx-components.tsx`

- [ ] **Step 1: Create the download CTA (reuses existing `AppStoreBadge`)**

Create `support/components/blog/download-cta.tsx`:
```tsx
import { AppStoreBadge } from "@/components/app-store-badge";

const APP_STORE_URL = "https://apps.apple.com/app/id6770921845";

export function DownloadCTA({
  headline = "Track calories the effortless way",
  body = "Snap a photo, talk to your Coach, hit your goals. Voidpen does the math so you don’t have to.",
}: {
  headline?: string;
  body?: string;
}) {
  return (
    <aside className="not-prose my-10 overflow-hidden rounded-3xl border border-line bg-gradient-to-br from-cream-2 to-cream-3 p-7 shadow-card sm:p-9">
      <h3 className="font-display text-2xl font-black uppercase tracking-tight text-ink sm:text-3xl">
        {headline}
      </h3>
      <p className="mt-3 max-w-xl text-ink-2">{body}</p>
      <div className="mt-6">
        <AppStoreBadge href={APP_STORE_URL} />
      </div>
    </aside>
  );
}
```

- [ ] **Step 2: Create the callout**

Create `support/components/blog/callout.tsx`:
```tsx
import type { ReactNode } from "react";

export function Callout({
  title,
  emoji = "💡",
  children,
}: {
  title?: string;
  emoji?: string;
  children: ReactNode;
}) {
  return (
    <div className="not-prose my-6 rounded-2xl border border-line bg-cream-2 p-5">
      <div className="flex gap-3">
        <span aria-hidden className="text-xl leading-none">
          {emoji}
        </span>
        <div className="text-ink-2 [&>p]:mt-2 [&>p:first-child]:mt-0">
          {title && <p className="font-display font-bold text-ink">{title}</p>}
          {children}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Create the post card**

Create `support/components/blog/post-card.tsx`:
```tsx
import Image from "next/image";
import Link from "next/link";
import { CATEGORY_LABELS, formatDate, type Post } from "@/lib/blog";

export function PostCard({
  post,
  featured = false,
}: {
  post: Post;
  featured?: boolean;
}) {
  return (
    <Link
      href={`/blogs/${post.slug}`}
      className={`group flex flex-col overflow-hidden rounded-3xl border border-line bg-card shadow-soft transition hover:-translate-y-1 hover:shadow-card ${
        featured ? "sm:flex-row" : ""
      }`}
    >
      <div
        className={`relative aspect-[16/9] w-full overflow-hidden ${
          featured ? "sm:aspect-auto sm:w-1/2" : ""
        }`}
      >
        <Image
          src={post.heroImage}
          alt={post.heroAlt}
          fill
          sizes={
            featured
              ? "(max-width: 640px) 100vw, 50vw"
              : "(max-width: 640px) 100vw, 33vw"
          }
          className="object-cover transition duration-500 group-hover:scale-[1.03]"
        />
      </div>
      <div className={`flex flex-1 flex-col p-6 ${featured ? "sm:p-8" : ""}`}>
        <span className="text-xs font-bold uppercase tracking-[0.08em] text-accent">
          {CATEGORY_LABELS[post.category]}
        </span>
        <h3
          className={`mt-2 font-display font-black uppercase leading-tight tracking-tight text-ink ${
            featured ? "text-2xl sm:text-3xl" : "text-xl"
          }`}
        >
          {post.title}
        </h3>
        <p className="mt-2 line-clamp-3 text-sm text-ink-2">
          {post.description}
        </p>
        <div className="mt-4 flex items-center gap-2 text-xs text-ink-soft">
          <time dateTime={post.date}>{formatDate(post.date)}</time>
          <span aria-hidden>·</span>
          <span>{post.readingTime} min read</span>
        </div>
      </div>
    </Link>
  );
}
```

- [ ] **Step 4: Create the MDX component map**

Create `support/components/blog/mdx-components.tsx`:
```tsx
import Image from "next/image";
import Link from "next/link";
import type { AnchorHTMLAttributes } from "react";
import { Callout } from "@/components/blog/callout";
import { DownloadCTA } from "@/components/blog/download-cta";

function Figure({
  src,
  alt,
  caption,
  width = 1200,
  height = 800,
}: {
  src: string;
  alt: string;
  caption?: string;
  width?: number;
  height?: number;
}) {
  return (
    <figure className="not-prose my-8">
      <Image
        src={src}
        alt={alt}
        width={width}
        height={height}
        sizes="(max-width: 768px) 100vw, 768px"
        className="h-auto w-full rounded-2xl border border-line object-cover"
      />
      {caption && (
        <figcaption className="mt-2 text-center text-sm text-ink-soft">
          {caption}
        </figcaption>
      )}
    </figure>
  );
}

function AppShot({ src, alt }: { src: string; alt: string }) {
  return (
    <figure className="not-prose my-8 flex justify-center">
      <Image
        src={src}
        alt={alt}
        width={260}
        height={565}
        className="rounded-[1.6rem] border border-line shadow-card"
      />
    </figure>
  );
}

function A({
  href = "",
  children,
  ...rest
}: AnchorHTMLAttributes<HTMLAnchorElement>) {
  const isInternal = href.startsWith("/") || href.startsWith("#");
  if (isInternal) {
    return (
      <Link href={href} {...rest}>
        {children}
      </Link>
    );
  }
  return (
    <a href={href} target="_blank" rel="noopener noreferrer" {...rest}>
      {children}
    </a>
  );
}

export const mdxComponents = { DownloadCTA, Callout, Figure, AppShot, a: A };
```

- [ ] **Step 5: Verify the build compiles**

Run: `npm run build`
Expected: PASS (components compile; not yet imported by a route).

- [ ] **Step 6: Commit**

```bash
git add components/blog
git commit -m "feat: add blog CTA, callout, post card, and MDX components"
```

---

## Task 5: Blog index page

**Files:**
- Create: `support/app/blogs/page.tsx`

- [ ] **Step 1: Create the index page**

Create `support/app/blogs/page.tsx`:
```tsx
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
```

- [ ] **Step 2: Verify the index renders (empty state is fine)**

Run: `npm run build`
Expected: PASS — `/blogs` appears in the route list. With no posts yet, the page shows "New articles are coming soon."

- [ ] **Step 3: Commit**

```bash
git add app/blogs/page.tsx
git commit -m "feat: add blog index page with structured data"
```

---

## Task 6: Blog post page

**Files:**
- Create: `support/app/blogs/[slug]/page.tsx`

- [ ] **Step 1: Create the post page**

Create `support/app/blogs/[slug]/page.tsx`:
```tsx
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
```

- [ ] **Step 2: Verify the build compiles**

Run: `npm run build`
Expected: PASS. With no posts yet, `generateStaticParams` returns `[]`, so no post pages are generated — but the route compiles without type errors.

- [ ] **Step 3: Commit**

```bash
git add app/blogs/\[slug\]/page.tsx
git commit -m "feat: add blog post page with MDX rendering and structured data"
```

---

## Task 7: Per-post branded OG image

**Files:**
- Create: `support/assets/fonts/ArchivoBlack-Regular.ttf`
- Create: `support/app/blogs/[slug]/opengraph-image.tsx`

- [ ] **Step 1: Download the display font for OG rendering**

Run (from `support/`):
```bash
mkdir -p assets/fonts && curl -fsSL -o assets/fonts/ArchivoBlack-Regular.ttf \
  "https://github.com/google/fonts/raw/main/ofl/archivoblack/ArchivoBlack-Regular.ttf" \
  && file assets/fonts/ArchivoBlack-Regular.ttf
```
Expected: `file` reports "TrueType Font data" (a valid .ttf, not an HTML error page). If the URL 404s, fall back to: `https://raw.githubusercontent.com/google/fonts/main/ofl/archivoblack/ArchivoBlack-Regular.ttf`.

- [ ] **Step 2: Create the OG image route**

Create `support/app/blogs/[slug]/opengraph-image.tsx`:
```tsx
import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { CATEGORY_LABELS, getPostBySlug } from "@/lib/blog";

export const alt = "The Voidpen Blog";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OgImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  const title = post?.title ?? "The Voidpen Blog";
  const eyebrow = post ? CATEGORY_LABELS[post.category] : "Blog";

  const archivo = await readFile(
    join(process.cwd(), "assets/fonts/ArchivoBlack-Regular.ttf"),
  );

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "#f6efe4",
          padding: 80,
          fontFamily: "Archivo",
        }}
      >
        <div
          style={{
            display: "flex",
            color: "#ff5a1f",
            fontSize: 30,
            textTransform: "uppercase",
            letterSpacing: 2,
          }}
        >
          voidpen · {eyebrow}
        </div>
        <div
          style={{
            display: "flex",
            color: "#1b1611",
            fontSize: 66,
            lineHeight: 1.05,
            textTransform: "uppercase",
          }}
        >
          {title}
        </div>
        <div style={{ display: "flex", color: "#837a6e", fontSize: 28 }}>
          voidpen.com/blogs
        </div>
      </div>
    ),
    {
      ...size,
      fonts: [{ name: "Archivo", data: archivo, style: "normal", weight: 400 }],
    },
  );
}
```

- [ ] **Step 3: Verify the build compiles**

Run: `npm run build`
Expected: PASS (the route compiles; OG images generate per post once posts exist).

- [ ] **Step 4: Commit**

```bash
git add assets/fonts/ArchivoBlack-Regular.ttf app/blogs/\[slug\]/opengraph-image.tsx
git commit -m "feat: add auto-generated branded OG images for blog posts"
```

---

## Task 8: SEO plumbing & navigation

**Files:**
- Modify: `support/app/sitemap.ts`
- Modify: `support/components/header.tsx`
- Modify: `support/components/footer.tsx`

- [ ] **Step 1: Add blog routes to the sitemap**

Replace the entire contents of `support/app/sitemap.ts` with:
```ts
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
```

- [ ] **Step 2: Add a "Blog" link to the header nav**

In `support/components/header.tsx`, inside the `<nav ...>` element, add this as the FIRST child (before the existing Support `<Link>`):
```tsx
<Link
  href="/blogs"
  className="rounded-md px-3 py-1.5 transition hover:text-accent"
>
  Blog
</Link>
```

- [ ] **Step 3: Add a "Blog" link to the footer Product list**

In `support/components/footer.tsx`, in the `Product` `<ul>` (the one containing the Home and Support links), add this `<li>` immediately after the Home `<li>` and before the Support `<li>`:
```tsx
<li>
  <Link href="/blogs" className="transition hover:text-accent">
    Blog
  </Link>
</li>
```

- [ ] **Step 4: Verify the build compiles**

Run: `npm run build`
Expected: PASS. The header/footer now show a Blog link; sitemap includes `/blogs`.

- [ ] **Step 5: Commit**

```bash
git add app/sitemap.ts components/header.tsx components/footer.tsx
git commit -m "feat: add blog to sitemap, header nav, and footer"
```

---

## Task 9: Source & optimize images

Royalty-free hero images, self-hosted. **License:** Unsplash License (free for commercial use, no attribution required). Download exact-sized, cropped URLs so dimensions are deterministic — no local processing needed.

**Method for each image:** find a matching photo on https://unsplash.com (search the terms below), copy its photo ID from the URL (`unsplash.com/photos/<slug>-<ID>` → use the `<ID>` segment, e.g. `photo-1490645935967-10de6ba17061`), then download:
```bash
curl -fsSL -o <dest> "https://images.unsplash.com/<PHOTO_ID>?w=1600&h=900&fit=crop&crop=entropy&q=80&auto=format"
```
After each download, verify it is a real image: `file <dest>` must report JPEG/PNG data (NOT HTML). Heroes are `1600x900`; if a body image is needed use `w=1200&h=800`.

**Files (one hero per article):**
- Create: `support/public/blog/best-ai-calorie-counter-apps/hero.jpg` — search: *"healthy colorful bowl overhead warm light"*
- Create: `support/public/blog/myfitnesspal-alternatives/hero.jpg` — search: *"meal prep containers fresh vegetables warm"*
- Create: `support/public/blog/can-ai-count-calories-from-photo/hero.jpg` — search: *"person taking photo of food with phone"*
- Create: `support/public/blog/count-calories-from-photo/hero.jpg` — search: *"smartphone photographing breakfast plate overhead"*
- Create: `support/public/blog/how-many-calories-to-lose-weight/hero.jpg` — search: *"balanced healthy plate grilled chicken vegetables"*
- Create: `support/public/blog/why-calorie-tracking-feels-tedious/hero.jpg` — search: *"relaxed person eating at cafe with phone warm"*

- [ ] **Step 1: Download all six hero images** using the method above, into the exact paths listed.

- [ ] **Step 2: Verify every hero is a valid image**

Run (from `support/`):
```bash
for d in public/blog/*/hero.jpg; do echo "$d:"; file "$d"; done
```
Expected: each line reports "JPEG image data". If any is HTML/zero bytes, re-download with a different photo ID.

- [ ] **Step 3: Commit**

```bash
git add public/blog
git commit -m "assets: add royalty-free hero images for blog posts"
```

---

## Task 10: Write the six articles

Each article: write `support/content/blog/<slug>.mdx` with the exact frontmatter shown, then ~1,200–1,800 words of genuinely useful prose following the section outline. Rules for every article:
- Voice: clear, warm, factual; no hype, no fake statistics. Mark competitor facts "as of 2026."
- Place the **primary keyword** in the title, first paragraph, and at least one `## H2`.
- Use `##`/`###` headings (they auto-get anchor links).
- Include **one `<DownloadCTA />`** roughly mid-article and rely on the page's end-of-article CTA for the second.
- Include **at least one `<AppShot ... />`** using an existing screenshot, and may add `<Figure ... />` for a downloaded hero/body image.
- Cross-link to **2 other articles** via internal `/blogs/<slug>` markdown links.
- Existing screenshots available for `<AppShot>`: `/screenshots/hero-home.png`, `/screenshots/screen-macros.png`, `/screenshots/screen-input.png`, `/screenshots/screen-coach.png`, `/screenshots/screen-progress.png`, `/screenshots/screen-widgets.png`.
- After writing each file, run `npm run build`, confirm the post route generates, then commit exactly: `git add content/blog/<slug>.mdx && git commit -m "content: add <slug> article"`.

Voidpen facts to use (accurate): iOS-only AI calorie tracker; logs food by **photo scan**, **voice**, **barcode/text**; estimates typically within ±15% and editable; has an AI **Coach**; syncs weight/body data with **Apple Health**; subscription via the App Store.

- [ ] **Step 1: Article 1 — Best AI Calorie Counter Apps (featured)**

Create `support/content/blog/best-ai-calorie-counter-apps.mdx` with frontmatter:
```yaml
---
title: "Best AI Calorie Counter Apps in 2026 (Tested & Ranked)"
description: "We tested the top AI calorie counter apps of 2026 on accuracy, speed, and ease. Here's how photo-based trackers compare — and which one to pick."
date: 2026-06-01
author: Voidpen Team
category: comparison
keywords: ["best AI calorie counter app", "AI calorie tracker", "photo calorie counter", "calorie tracking app 2026"]
heroImage: /blog/best-ai-calorie-counter-apps/hero.jpg
heroAlt: "Overhead view of a colorful healthy bowl in warm natural light"
featured: true
---
```
Outline (write full prose under each):
- Intro: why AI calorie counters exploded in 2025–26; primary keyword in first sentence.
- `## What makes an AI calorie counter actually good` — accuracy, speed, logging methods, correction UX.
- `## How we tested` — brief credible methodology (real meals, edited estimates).
- `## The best AI calorie counter apps in 2026` with `###` per app: **Voidpen** (lead, strongest — photo + voice + Coach + Health sync), then fair takes on **Cal AI**, **MyFitnessPal** (AI photo add-on), **Lose It! (Snap It)**, **Cronometer** (accuracy/micros). One-line pros/cons each.
- `<AppShot src="/screenshots/screen-input.png" alt="Logging a meal in Voidpen by photo, voice, or text" />`
- `## Accuracy: can a photo really count calories?` — link to `/blogs/can-ai-count-calories-from-photo`.
- `<DownloadCTA />`
- `## Which should you choose?` — recommendation by use case.
- Closing line; internal link to `/blogs/why-calorie-tracking-feels-tedious`.

Run: `npm run build` → Expected: PASS, `/blogs/best-ai-calorie-counter-apps` generated.
Commit: `git add public content app && git commit -m "content: add 'Best AI Calorie Counter Apps 2026' article"`

- [ ] **Step 2: Article 2 — 5 Best MyFitnessPal Alternatives**

Create `support/content/blog/myfitnesspal-alternatives.mdx` with frontmatter:
```yaml
---
title: "5 Best MyFitnessPal Alternatives for Effortless Tracking (2026)"
description: "Tired of barcode scanning and a paywalled database? Here are 5 of the best MyFitnessPal alternatives in 2026 for faster, easier calorie tracking."
date: 2026-05-28
author: Voidpen Team
category: comparison
keywords: ["myfitnesspal alternatives", "apps like myfitnesspal", "best calorie tracking app", "myfitnesspal vs"]
heroImage: /blog/myfitnesspal-alternatives/hero.jpg
heroAlt: "Fresh meal-prep containers with vegetables in warm light"
---
```
Outline:
- Intro: common MFP frustrations (tedious search, paywalled features as of 2026); primary keyword early.
- `## Why people look for a MyFitnessPal alternative` — friction, ads, manual entry.
- `## The 5 best MyFitnessPal alternatives` with `###` each: **Voidpen** (lead — photo/voice logging removes manual search), **Cronometer**, **Lose It!**, **Cal AI**, **MacroFactor**. Fair pros/cons.
- `<AppShot src="/screenshots/screen-macros.png" alt="Voidpen's macro breakdown for a logged day" />`
- `<DownloadCTA headline="Skip the database search" body="Voidpen logs a meal from a photo in seconds — no scrolling through search results." />`
- `## How to switch without losing momentum` — practical tips.
- Internal links to `/blogs/best-ai-calorie-counter-apps` and `/blogs/why-calorie-tracking-feels-tedious`.

Run: `npm run build` → Expected: PASS. Commit per the rule above.

- [ ] **Step 3: Article 3 — Can AI Count Calories From a Photo?**

Create `support/content/blog/can-ai-count-calories-from-photo.mdx` with frontmatter:
```yaml
---
title: "Can AI Actually Count Calories From a Photo?"
description: "How accurate is AI calorie counting from a photo? We break down how it works, where it shines, where it struggles, and how to get reliable numbers."
date: 2026-05-24
author: Voidpen Team
category: ai-photo
keywords: ["ai calorie counting accuracy", "can ai count calories", "photo calorie counter accuracy", "how does ai calorie tracking work"]
heroImage: /blog/can-ai-count-calories-from-photo/hero.jpg
heroAlt: "A person photographing a plate of food with a smartphone"
---
```
Outline:
- Intro: the honest question, primary keyword early.
- `## How AI calorie counting from a photo works` — recognition → portion estimate → nutrition DB.
- `## How accurate is it, really?` — typical ±10–20% range; on par with human eyeballing; where it's strong (standard plated meals) vs. weak (mixed dishes, hidden oils).
- `<Figure src="/blog/can-ai-count-calories-from-photo/hero.jpg" alt="Snapping a photo of a meal for AI analysis" />` (or an `<AppShot src="/screenshots/screen-coach.png" alt="Voidpen Coach explaining a meal estimate" />`)
- `## How to get the most accurate results` — angle, edit portions, the ±15% editable point.
- `<DownloadCTA />`
- `## The bottom line` — accuracy is "good enough to drive behavior change," which beats abandoning tracking.
- Internal links to `/blogs/count-calories-from-photo` and `/blogs/best-ai-calorie-counter-apps`.

Run: `npm run build` → Expected: PASS. Commit accordingly.

- [ ] **Step 4: Article 4 — How to Count Calories by Taking a Photo**

Create `support/content/blog/count-calories-from-photo.mdx` with frontmatter:
```yaml
---
title: "How to Count Calories by Taking a Photo of Your Food"
description: "A step-by-step guide to counting calories from a photo: how to snap, what AI sees, how to fix estimates, and tips for fast, accurate food logging."
date: 2026-05-20
author: Voidpen Team
category: ai-photo
keywords: ["count calories from photo", "how to track calories with a photo", "photo food log", "snap a photo calorie tracking"]
heroImage: /blog/count-calories-from-photo/hero.jpg
heroAlt: "Smartphone photographing a breakfast plate from above"
---
```
Outline:
- Intro: the promise — logging in seconds; primary keyword early.
- `## Step 1: Take a clear photo` — lighting, angle, whole plate.
- `## Step 2: Let the AI identify the food` — what happens behind the scenes.
- `## Step 3: Check and adjust the estimate` — edit grams/servings (±15% editable).
- `<AppShot src="/screenshots/screen-input.png" alt="Photographing and logging a meal in Voidpen" />`
- `## Step 4: Log other meals just as fast` — voice and text options.
- `<DownloadCTA />`
- `## Tips for more accurate photo logging` — bullet list.
- Internal links to `/blogs/can-ai-count-calories-from-photo` and `/blogs/why-calorie-tracking-feels-tedious`.

Run: `npm run build` → Expected: PASS. Commit accordingly.

- [ ] **Step 5: Article 5 — How Many Calories to Lose Weight**

Create `support/content/blog/how-many-calories-to-lose-weight.mdx` with frontmatter:
```yaml
---
title: "How Many Calories Should You Eat to Lose Weight?"
description: "Learn how many calories to eat to lose weight: how to estimate your TDEE, set a safe deficit, and actually hit your numbers without burning out."
date: 2026-05-16
author: Voidpen Team
category: educational
keywords: ["calories to lose weight", "how many calories to lose weight", "calorie deficit", "tdee"]
heroImage: /blog/how-many-calories-to-lose-weight/hero.jpg
heroAlt: "A balanced plate of grilled chicken and vegetables in warm light"
---
```
Outline:
- Intro: primary keyword early; promise a clear answer.
- `## Step 1: Estimate your maintenance calories (TDEE)` — BMR + activity, simple framing; give a worked example.
- `## Step 2: Set a sensible deficit` — 300–500/day ≈ ~0.5–1 lb/week; why extreme deficits backfire.
- `## Step 3: Hit your target consistently` — the real bottleneck is logging adherence, not math.
- `<Callout title="The hard part isn't the number">Most people know roughly how much to eat. Staying consistent with logging is what actually moves the scale.</Callout>`
- `<AppShot src="/screenshots/screen-progress.png" alt="Voidpen weight and calorie progress over time" />`
- `<DownloadCTA />`
- `## Common mistakes` — under-logging, weekend resets, cutting too hard.
- Internal links to `/blogs/why-calorie-tracking-feels-tedious` and `/blogs/best-ai-calorie-counter-apps`.

Run: `npm run build` → Expected: PASS. Commit accordingly.

- [ ] **Step 6: Article 6 — Why Calorie Tracking Feels Tedious**

Create `support/content/blog/why-calorie-tracking-feels-tedious.mdx` with frontmatter:
```yaml
---
title: "Why Calorie Tracking Feels Tedious — and the Effortless Fix"
description: "Calorie tracking burns most people out within weeks. Here's why it feels so tedious — and how photo and voice logging make it effortless enough to stick."
date: 2026-05-12
author: Voidpen Team
category: pain-point
keywords: ["easiest way to track calories", "calorie tracking is tedious", "effortless calorie tracking", "how to track calories without weighing food"]
heroImage: /blog/why-calorie-tracking-feels-tedious/hero.jpg
heroAlt: "A relaxed person eating at a cafe with a phone, warm light"
---
```
Outline:
- Intro: name the pain; primary keyword early.
- `## Why traditional calorie tracking burns you out` — manual search, weighing, decision fatigue, all-or-nothing.
- `## The friction is the real problem` — adherence > precision.
- `## The effortless fix: log the way you actually eat` — photo, voice, quick text.
- `<AppShot src="/screenshots/screen-coach.png" alt="Voidpen Coach answering a question in chat" />`
- `<DownloadCTA headline="Make tracking effortless enough to keep" />`
- `## How to track calories without weighing food` — practical approaches (visual portions, AI estimates, editable numbers).
- Internal links to `/blogs/count-calories-from-photo` and `/blogs/how-many-calories-to-lose-weight`.

Run: `npm run build` → Expected: PASS. Commit accordingly.

---

## Task 11: Final verification & visual review

**Files:** none (verification only)

- [ ] **Step 1: Full build + test pass**

Run (from `support/`): `npm run build && npm test`
Expected: build generates `/blogs` + 6 post routes + 6 OG images; all vitest tests pass.

- [ ] **Step 2: Verify SEO output in the build**

Run: `npm run build 2>&1 | grep -i "blogs"`
Expected: see `/blogs` and each `/blogs/<slug>` listed as generated static routes.

- [ ] **Step 3: Visual check in the browser**

Run: `npm run dev` (background). Then load and eyeball:
- `http://localhost:3000/blogs` — featured card + grid render, images load, Blog link in header/footer.
- One post, e.g. `http://localhost:3000/blogs/best-ai-calorie-counter-apps` — hero image, prose theming (orange links, Archivo headings), heading anchors, mid + end CTAs, related posts.
- `http://localhost:3000/blogs/best-ai-calorie-counter-apps/opengraph-image` — branded OG image renders with the title.
- View page source on a post; confirm two `<script type="application/ld+json">` blocks (BlogPosting + BreadcrumbList) and a `<link rel="canonical">`.

Use the Chrome MCP tools (`mcp__claude-in-chrome__*`) to screenshot the index and one post for a visual pass. Stop the dev server when done.

- [ ] **Step 4: Final commit (if any cleanup)**

```bash
git add -A
git commit -m "chore: blog final verification pass"
```

---

## Deployment note

Publishing is automatic: the `support` Vercel project deploys on push to the production branch. After merging, validate live: `https://voidpen.com/blogs`, `https://voidpen.com/sitemap.xml` (should list the posts), and test one post URL in Google's Rich Results Test for `BlogPosting`/`BreadcrumbList`. Deploy only when the user asks.

---

## Self-review notes (coverage vs. spec)

- Spec §2 architecture/file structure → Tasks 2,4,5,6 (+ `lib/blog.ts`, components, routes). ✓
- Spec §3 content model (frontmatter) → Task 2 `PostFrontmatter` + validation; used in every article (Task 10). ✓
- Spec §4 SEO (metadata, JSON-LD, sitemap, OG images, anchors, internal links) → Tasks 5,6,7,8 + Task 10 linking rules. ✓
- Spec §5 design/layout (index, post, nav) → Tasks 4,5,6,8. ✓
- Spec §6 conversion (DownloadCTA mid+end) → Task 4 + Task 10 rules. ✓
- Spec §7 images (warm royalty-free + app screenshots, alt text) → Task 9 + Task 10 `<AppShot>`/`<Figure>` + `heroAlt`. ✓
- Spec §8 six articles (slugs/titles/keywords match the spec table) → Task 10 steps 1–6. ✓
- Spec §9 out-of-scope respected (no CMS/comments/search/RSS). ✓
- Dependencies (next-mdx-remote, gray-matter, remark/rehype, typography, vitest) → Task 1. ✓
