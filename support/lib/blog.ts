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
