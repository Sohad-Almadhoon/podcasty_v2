import Link from "next/link";
import Image from "next/image";
import { fetchAllSeries } from "@/app/lib/api/series";
import { Badge } from "@/components/ui/badge";
import { Layers, Mic2 } from "lucide-react";
import CreateSeriesButton from "@/components/buttons/CreateSeriesButton";

export const dynamic = "force-dynamic";

export default async function SeriesPage() {
  let allSeries: any[] = [];
  try {
    allSeries = await fetchAllSeries();
  } catch (error) {
    console.error("Error fetching series:", error);
  }

  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-4 sm:px-6 py-6 sm:py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Library</p>
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
            <Layers className="w-6 h-6 text-app-accent" /> Series
          </h1>
          <CreateSeriesButton />
        </div>
      </div>

      <div className="px-4 sm:px-6 py-6 sm:py-8">
        {allSeries.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Layers className="text-app-border w-12 h-12 mb-4" />
            <p className="text-app-muted text-sm">No series yet.</p>
            <p className="text-app-subtle text-xs mt-1">Creators can group their podcasts into series.</p>
          </div>
        ) : (
          <div className="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-4">
            {allSeries.map((series: any) => {
              const episodeCount =
                Array.isArray(series.series_episodes) && series.series_episodes.length > 0
                  ? series.series_episodes[0]?.count ?? series.series_episodes.length
                  : 0;
              return (
                <Link href={`/series/${series.id}`} key={series.id}>
                  <div className="group rounded-xl border border-app-border bg-app-surface hover:border-app-muted hover:shadow-app transition-all overflow-hidden">
                    <div className="relative h-36 bg-app-raised">
                      {series.cover_url ? (
                        <Image
                          src={series.cover_url}
                          alt={series.title}
                          fill
                          unoptimized
                          className="object-cover group-hover:scale-105 transition-transform duration-500"
                        />
                      ) : (
                        <div className="flex items-center justify-center h-full">
                          <Layers className="w-10 h-10 text-app-border" />
                        </div>
                      )}
                    </div>
                    <div className="p-4">
                      <p className="font-semibold text-app-text text-sm truncate">{series.title}</p>
                      {series.description && (
                        <p className="text-xs text-app-subtle line-clamp-2 mt-1">{series.description}</p>
                      )}
                      <div className="flex items-center gap-2 mt-3">
                        <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                          <Mic2 className="w-3 h-3" /> {episodeCount} episode{episodeCount !== 1 ? "s" : ""}
                        </Badge>
                        {series.users?.username && (
                          <span className="text-xs text-app-subtle">by {series.users.username}</span>
                        )}
                      </div>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
