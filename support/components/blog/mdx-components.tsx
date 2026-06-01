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
