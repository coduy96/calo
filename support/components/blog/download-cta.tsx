import { AppStoreBadge } from "@/components/app-store-badge";

const APP_STORE_URL = "https://apps.apple.com/app/id6770921845";

export function DownloadCTA({
  headline = "Track calories the effortless way",
  body = "Snap a photo, talk to your Coach, hit your goals. Voidpen does the math so you don't have to.",
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
