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
