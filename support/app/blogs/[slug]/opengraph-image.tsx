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
