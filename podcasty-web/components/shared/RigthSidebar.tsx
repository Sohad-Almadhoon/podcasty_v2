import { BsHeadphones } from "react-icons/bs";
import Link from "next/link";
import { fetchTrendingPodcasts } from "@/app/lib/api/public";
import type { Podcast } from "@/app/types";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";

export default async function RigthSidebar() {
  let mostPlayedPodcasts: Podcast[] = [];

  try {
    mostPlayedPodcasts = await fetchTrendingPodcasts(10);
  } catch (error) {
    console.error("Error fetching trending podcasts:", error);
  }

  return (
    <aside className="border-l border-app-border bg-app-bg lg:flex hidden flex-col w-64 shrink-0">
      <div className="px-4 py-5">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest">Trending</p>
      </div>
      <Separator className="bg-app-border" />
      <ul className="flex flex-col py-2">
        {mostPlayedPodcasts.length > 0 ? (
          mostPlayedPodcasts.map((podcast, i) => (
            <Link
              href={`/podcasts/${podcast.id}`}
              key={podcast.id}
              className="flex items-center gap-3 px-4 py-3 hover:bg-app-raised transition-colors group">
              <span className="text-xs text-app-subtle w-4 shrink-0">{i + 1}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm text-app-text font-medium truncate">
                  {podcast.podcast_name}
                </p>
                <p className="text-xs text-app-muted truncate">
                  {podcast.users?.username || "Unknown"}
                </p>
              </div>
              <Badge variant="outline" className="border-app-border text-app-subtle text-xs shrink-0 gap-1">
                <BsHeadphones /> {podcast.play_count}
              </Badge>
            </Link>
          ))
        ) : (
          <p className="text-app-subtle text-sm px-4 py-3">No podcasts yet</p>
        )}
      </ul>
    </aside>
  );
}
