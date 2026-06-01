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
