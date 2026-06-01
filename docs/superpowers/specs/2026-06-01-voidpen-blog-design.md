# Voidpen Blog — Design Spec

**Date:** 2026-06-01
**Goal:** Add an SEO-optimized blog at `voidpen.com/blogs` to attract organic search traffic and convert it into paid Voidpen app customers (App Store downloads → subscriptions).
**Location:** Lives in the existing `support/` Next.js app (the marketing/legal site deployed to Vercel as project "support", served at `voidpen.com`).

---

## 1. Objectives & success criteria

- Rank for high-intent, conversion-driving keywords around AI calorie tracking.
- Every article funnels readers toward downloading the app.
- Technically excellent SEO: structured data, canonical URLs, sitemap, fast static pages, optimized images.
- Visually consistent with the existing warm cream/orange brand theme.
- Easy to extend: publishing a new post = add one `.mdx` file + commit (Vercel auto-deploys).

**Done means:** the blog engine is live with 6 publish-ready, image-rich, SEO-optimized articles, each with hero + supporting images, CTAs, structured data, and sitemap entries.

---

## 2. Architecture

**Approach:** Content-collection of MDX files in the repo (chosen over per-route `.mdx` pages because it gives a clean index page, centralized SEO, and a typed content model).

### File structure
```
support/
  app/blogs/page.tsx                    → blog index (lists all posts)
  app/blogs/[slug]/page.tsx             → individual post (statically generated)
  app/blogs/[slug]/opengraph-image.tsx  → auto-generated branded OG image per post
  content/blog/*.mdx                    → post content files (one per article)
  lib/blog.ts                           → getAllPosts(), getPostBySlug(), frontmatter types, reading-time calc
  components/blog/
    post-card.tsx                       → card used on the index grid
    download-cta.tsx                    → reusable App Store CTA block (MDX-embeddable)
    callout.tsx                         → highlighted note/tip block (MDX-embeddable)
    mdx-components.tsx                   → themed h2/h3/p/a/ul/img + custom component map
  public/blog/<slug>/*                  → downloaded & optimized images per post
  app/blog.css (or Tailwind typography) → themed article prose styles
```

Posts are served at `voidpen.com/blogs/<slug>`. `generateStaticParams` pre-renders every post at build time (fully static, fast, cheap).

### Dependencies (minimal, standard, well-maintained)
- `next-mdx-remote` (RSC variant) — render MDX with embeddable React components (CTAs, callouts)
- `gray-matter` — parse frontmatter
- `remark-gfm` — GitHub-flavored markdown (tables, etc.)
- `rehype-slug` + `rehype-autolink-headings` — heading anchor links (jump links, Google "jump to")
- `@tailwindcss/typography` — base prose styling, themed to cream/ink/orange via Tailwind v4 `@plugin` + overrides

Reading time is computed in `lib/blog.ts` (word count ÷ 200), no extra dependency.

---

## 3. Content model (frontmatter)

Each `content/blog/*.mdx` file begins with:
```yaml
---
title: string              # H1 + <title>
description: string        # 150–160 char meta description
date: 2026-06-01           # ISO publish date
updated: 2026-06-01        # optional, ISO; falls back to date
author: Voidpen Team       # default
category: comparison | ai-photo | educational | pain-point
keywords: [..]             # target keywords
heroImage: /blog/<slug>/hero.jpg
heroAlt: string            # descriptive alt text for hero
featured: true             # optional; one featured post on the index
---
```
The slug is derived from the filename. `lib/blog.ts` validates required fields and exposes a typed `Post` interface so missing fields fail loudly at build.

---

## 4. SEO implementation (the core)

- **Per-post `generateMetadata`:** title, meta description, **canonical** (`/blogs/<slug>`), OpenGraph (`type: article`, `publishedTime`, `modifiedTime`, `authors`, post OG image), Twitter `summary_large_image`, keywords.
- **JSON-LD structured data** (injected via `<script type="application/ld+json">`):
  - Each post → `BlogPosting` (headline, description, image, datePublished, dateModified, author, publisher with logo, mainEntityOfPage)
  - Each post → `BreadcrumbList` (Home → Blog → Post)
  - Index → `Blog` / `CollectionPage`
- **Dynamic sitemap:** extend `app/sitemap.ts` to add `/blogs` and every post URL, with real `lastModified` from frontmatter (`updated`/`date`).
- **Auto-generated OG images:** `opengraph-image.tsx` per post uses Next `ImageResponse` to render the post title on the branded cream/orange background (1200×630) → strong social/search click-through without manual design work.
- **On-page SEO:** semantic HTML (`<article>`, single `<h1>`, logical `<h2>/<h3>`), heading anchors, descriptive `alt` on every image, internal cross-links between related posts, `next/image` optimization (responsive sizes, lazy loading below the fold, `priority` on hero).
- **`robots.ts`** already allows all + points to sitemap — no change needed beyond the sitemap additions.

---

## 5. Design & layout (reuses existing theme + components)

**Brand tokens** (already defined in `globals.css`): cream `#f6efe4`, ink `#1b1611`, accent `#ff5a1f`, Archivo display + Hanken body. Blog uses these throughout.

**Index page (`/blogs`):**
- Reuses `Header` + `Footer`.
- Hero header: "The Voidpen Blog" + tagline.
- Featured post card (the `featured: true` post), large.
- Responsive grid of `PostCard`s (hero thumbnail, category tag, title, excerpt, date, reading time), newest first.

**Post page (`/blogs/[slug]`):**
- Breadcrumb (Home → Blog → title).
- Category tag → H1 → meta row (author · date · reading time).
- Hero image (`next/image`, `priority`).
- Themed prose body (Tailwind typography overridden to brand colors; links in accent orange, headings in Archivo).
- Inline `<DownloadCTA />` mid-article + full `<DownloadCTA />` block at the end.
- "Related posts" section (2–3 cross-linked posts) → keeps readers on-site, boosts SEO.

**Navigation:** add a "Blog" link to `Header` nav and `Footer`.

---

## 6. Conversion (driving paid customers)

- `components/blog/download-cta.tsx`: branded block with headline, the App Store badge, and the live URL `https://apps.apple.com/app/id6770921845`. Embeddable in any MDX article.
- Rendered at least twice per article (mid + end) and on the index page footer.
- Contextual inline links from article copy back to the homepage feature sections.
- Articles are written to lead naturally to "the easiest way to do this is to let an app handle it" → Voidpen.

---

## 7. Images

**Style:** warm, bright, natural food photography that matches the cream/orange palette.
**Sourcing:** royalty-free, commercial-use — Unsplash & Pexels (free for commercial use, no attribution required). Downloaded into `public/blog/<slug>/`, resized/compressed for web, served via `next/image`. **No** unlicensed/Google-scraped images.
**Mix:** stock food/fitness photography for editorial hero + body images, plus real Voidpen app screenshots (`public/screenshots/hero-home.png`, `screen-macros.png`, `screen-input.png`, `screen-coach.png`, `screen-progress.png`, `screen-widgets.png`) inline where they reinforce the product and drive downloads.
**Per article:** 1 hero image + 1–2 supporting images + 1 auto-generated branded OG image. Every image gets descriptive `alt` text (accessibility + image SEO).

---

## 8. Initial article batch (6 posts)

All ~1,200–1,800 words, genuinely useful, fairly position Voidpen, cross-link to each other.

| # | Slug | Title | Pillar | Primary keyword |
|---|------|-------|--------|-----------------|
| 1 | best-ai-calorie-counter-apps | Best AI Calorie Counter Apps in 2026 (Tested & Ranked) | comparison | "best AI calorie counter app" |
| 2 | myfitnesspal-alternatives | 5 Best MyFitnessPal Alternatives for Effortless Tracking (2026) | comparison | "myfitnesspal alternatives" |
| 3 | can-ai-count-calories-from-photo | Can AI Actually Count Calories From a Photo? | ai-photo | "ai calorie counting accuracy" |
| 4 | count-calories-from-photo | How to Count Calories by Taking a Photo of Your Food | ai-photo | "count calories from photo" |
| 5 | how-many-calories-to-lose-weight | How Many Calories Should You Eat to Lose Weight? | educational | "calories to lose weight" |
| 6 | why-calorie-tracking-feels-tedious | Why Calorie Tracking Feels Tedious — and the Effortless Fix | pain-point | "easiest way to track calories" |

Comparison articles name competitors (MyFitnessPal, Cal AI, Lose It, etc.) factually and fairly — standard SEO practice. Article 1 is the `featured` post.

---

## 9. Out of scope (YAGNI)

- No CMS, comments, search, pagination, tags taxonomy, or RSS in v1 (can add later if traffic warrants).
- No newsletter signup (no email infra today).
- No author bios beyond "Voidpen Team".

---

## 10. Risks & notes

- `model_prices`/cost concerns are unrelated; this is a static marketing feature with no runtime API cost.
- Competitor facts (pricing, features) must be checked at write time and dated ("as of 2026") to avoid going stale or being inaccurate.
- Image file weight: compress hero images to keep LCP fast (target < 200KB each after optimization).
- Tailwind v4 typography plugin is loaded via `@plugin "@tailwindcss/typography"` in the CSS; verify it builds cleanly before relying on it (fallback: hand-rolled `blog.css` prose styles matching the existing `landing.css` pattern).
