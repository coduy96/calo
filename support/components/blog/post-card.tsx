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
