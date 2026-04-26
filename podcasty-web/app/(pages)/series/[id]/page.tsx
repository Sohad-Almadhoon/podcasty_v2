import Link from "next/link";
import Image from "next/image";
import { fetchSeries } from "@/app/lib/api/series";
import { getUser } from "@/app/lib/supabase";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Layers, Mic2, Play } from "lucide-react";
import { BsHeadphones, BsHeartFill } from "react-icons/bs";
import AddEpisodeButton from "@/components/buttons/AddEpisodeButton";
import BackButton from "@/components/buttons/BackButton";

export default async function SeriesDetailPage(props: { params: Promise<{ id: string }> }) {
  const { id } = await props.params;
  if (!id) return notFound();

  let series: any;
  try {
    series = await fetchSeries(id);
  } catch {
    return notFound();
  }
  if (!series) return notFound();

  const user = await getUser();
  const isOwner = user?.id === series.user_id;

  const episodes = series.series_episodes ?? [];

  // Group episodes by season
  const seasons = new Map<number, any[]>();
  for (const ep of episodes) {
    const s = ep.season_number || 1;
    if (!seasons.has(s)) seasons.set(s, []);
    seasons.get(s)!.push(ep);
  }
  // Sort seasons and episodes within each
  const sortedSeasons = [...seasons.entries()].sort(([a], [b]) => a - b);
  for (const [, eps] of sortedSeasons) {
    eps.sort((a: any, b: any) => a.episode_number - b.episode_number);
  }

  return (
    <div className="min-h-screen pb-16">
      {/* Header */}
      <div className="border-b border-app-border px-6 py-8">
        <div className="mb-4">
          <BackButton />
        </div>
        <div className="flex flex-col sm:flex-row gap-6">
          {/* Cover */}
          <div className="relative w-36 h-36 shrink-0 rounded-xl overflow-hidden border border-app-border bg-app-raised shadow-app-md">
            {series.cover_url ? (
              <Image src={series.cover_url} alt={series.title} fill unoptimized className="object-cover" />
            ) : (
              <div className="flex items-center justify-center h-full">
                <Layers className="w-10 h-10 text-app-border" />
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex flex-col justify-between gap-2">
            <div>
              <Badge variant="outline" className="border-app-border text-app-muted mb-2 text-xs">Series</Badge>
              <h1 className="text-2xl font-bold text-app-text">{series.title}</h1>
              {series.users?.username && (
                <Link href={`/profile/${series.user_id}`} className="text-sm text-app-muted hover:text-app-text transition-colors mt-1 inline-block">
                  by {series.users.username}
                </Link>
              )}
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                <Mic2 className="w-3 h-3" /> {episodes.length} episode{episodes.length !== 1 ? "s" : ""}
              </Badge>
              <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                <Layers className="w-3 h-3" /> {sortedSeasons.length} season{sortedSeasons.length !== 1 ? "s" : ""}
              </Badge>
              {isOwner && <AddEpisodeButton seriesId={id} userId={user.id} />}
            </div>
          </div>
        </div>
      </div>

      {/* Description */}
      {series.description && (
        <div className="px-6 pt-6">
          <p className="text-sm text-app-muted leading-relaxed max-w-2xl">{series.description}</p>
        </div>
      )}

      {/* Episodes by season */}
      <div className="px-6 py-8 space-y-8">
        {sortedSeasons.length === 0 ? (
          <div className="rounded-xl border border-dashed border-app-border p-10 text-center">
            <Mic2 className="w-8 h-8 text-app-subtle mx-auto mb-3" />
            <p className="text-sm font-medium text-app-text mb-1">No episodes yet</p>
            <p className="text-xs text-app-subtle">The creator hasn&apos;t added episodes to this series.</p>
          </div>
        ) : (
          sortedSeasons.map(([seasonNum, eps]) => (
            <div key={seasonNum}>
              <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-4">
                Season {seasonNum}
              </p>
              <div className="rounded-lg border border-app-border divide-y divide-app-border bg-app-surface overflow-hidden">
                {eps.map((ep: any) => {
                  const p = ep.podcasts;
                  if (!p) return null;
                  return (
                    <Link href={`/podcasts/${p.id}`} key={ep.id}>
                      <div className="flex items-center gap-4 px-4 py-3 hover:bg-app-raised transition-colors group">
                        {/* Episode number */}
                        <span className="text-xs text-app-subtle w-6 text-center tabular-nums shrink-0">
                          {ep.episode_number}
                        </span>
                        {/* Play icon on hover */}
                        <div className="flex items-center justify-center size-9 rounded-full border border-app-border text-app-muted group-hover:text-app-accent group-hover:border-app-accent transition-colors shrink-0">
                          <Play className="w-3.5 h-3.5 fill-current" />
                        </div>
                        {/* Cover */}
                        <div className="relative size-10 rounded-lg overflow-hidden border border-app-border shrink-0">
                          <Image
                            src={p.image_url?.trim() || "/images/1.jpeg"}
                            alt={p.podcast_name}
                            fill
                            unoptimized
                            className="object-cover"
                          />
                        </div>
                        {/* Info */}
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-app-text truncate">{p.podcast_name}</p>
                          <p className="text-xs text-app-subtle truncate">{p.description}</p>
                        </div>
                        {/* Stats */}
                        <div className="flex gap-2 shrink-0 max-sm:hidden">
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                            <BsHeadphones /> {p.play_count || 0}
                          </Badge>
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                            <BsHeartFill className="text-[10px]" /> {p.likes?.[0]?.count || 0}
                          </Badge>
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
