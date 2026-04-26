import { getUser } from "@/app/lib/supabase";
import { fetchUserPodcasts } from "@/app/lib/api/users";
import { fetchPodcastAnalytics } from "@/app/lib/api/analytics";
import { redirect } from "next/navigation";
import { BarChart3, Headphones, Heart, MessageCircle, Users } from "lucide-react";
import { Separator } from "@/components/ui/separator";
import AnalyticsCharts from "@/components/shared/AnalyticsCharts";

export const dynamic = "force-dynamic";

const isDynamicServerUsage = (e: unknown) =>
  (e as { digest?: string })?.digest === "DYNAMIC_SERVER_USAGE";

export default async function AnalyticsPage() {
  const user = await getUser();
  if (!user) redirect("/login");

  let podcasts: any[] = [];
  try {
    podcasts = await fetchUserPodcasts(user.id);
  } catch (error) {
    if (isDynamicServerUsage(error)) throw error;
    console.error("Error fetching user podcasts:", error);
  }

  // Fetch analytics for each podcast
  const analyticsData: any[] = [];
  const analyticsResults = await Promise.allSettled(
    podcasts.map((p) => fetchPodcastAnalytics(p.id))
  );
  analyticsResults.forEach((result, i) => {
    if (result.status === "fulfilled") {
      const p = podcasts[i];
      analyticsData.push({
        ...result.value,
        podcast_name: p.podcast_name,
        image_url: p.image_url,
      });
    } else if (isDynamicServerUsage(result.reason)) {
      throw result.reason;
    }
  });

  // Aggregate totals
  const totals = {
    podcasts: podcasts.length,
    plays: analyticsData.reduce((s, a) => s + (a.total_plays || 0), 0),
    likes: analyticsData.reduce((s, a) => s + (a.total_likes || 0), 0),
    comments: analyticsData.reduce((s, a) => s + (a.total_comments || 0), 0),
    listeners: analyticsData.reduce((s, a) => s + (a.unique_listeners || 0), 0),
  };

  // Merge all plays_over_time into one aggregated timeline
  const playsMap = new Map<string, number>();
  for (const a of analyticsData) {
    for (const entry of a.plays_over_time ?? []) {
      playsMap.set(entry.date, (playsMap.get(entry.date) || 0) + entry.count);
    }
  }
  const aggregatedPlays = [...playsMap.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, count]) => ({ date, count }));

  const statCards = [
    { label: "Total Plays", value: totals.plays, icon: Headphones, color: "text-blue-500" },
    { label: "Total Likes", value: totals.likes, icon: Heart, color: "text-red-500" },
    { label: "Comments", value: totals.comments, icon: MessageCircle, color: "text-green-500" },
    { label: "Unique Listeners", value: totals.listeners, icon: Users, color: "text-purple-500" },
  ];

  return (
    <div className="min-h-screen pb-16">
      {/* Header */}
      <div className="border-b border-app-border px-4 sm:px-6 py-6 sm:py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Creator</p>
        <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
          <BarChart3 className="w-6 h-6 text-app-accent" /> Analytics Dashboard
        </h1>
        <p className="text-sm text-app-muted mt-1">Track how your podcasts are performing.</p>
      </div>

      <div className="px-4 sm:px-6 py-6 sm:py-8 space-y-8">
        {/* Stat cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {statCards.map((stat) => (
            <div key={stat.label} className="rounded-xl border border-app-border bg-app-surface p-4">
              <div className="flex items-center gap-2 mb-2">
                <stat.icon className={`w-4 h-4 ${stat.color}`} />
                <span className="text-xs text-app-subtle uppercase tracking-wider">{stat.label}</span>
              </div>
              <p className="text-2xl font-bold text-app-text tabular-nums">
                {stat.value.toLocaleString()}
              </p>
            </div>
          ))}
        </div>

        <Separator className="bg-app-border" />

        {/* Plays over time chart */}
        <div>
          <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-4">
            Plays Over Time
          </p>
          {aggregatedPlays.length > 0 ? (
            <AnalyticsCharts data={aggregatedPlays} />
          ) : (
            <div className="rounded-xl border border-dashed border-app-border p-10 text-center">
              <p className="text-sm text-app-subtle">No play data yet. Share your podcasts to start getting listeners.</p>
            </div>
          )}
        </div>

        <Separator className="bg-app-border" />

        {/* Per-podcast breakdown */}
        <div>
          <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-4">
            Per Podcast
          </p>
          {analyticsData.length === 0 ? (
            <p className="text-sm text-app-subtle">Create your first podcast to see analytics.</p>
          ) : (
            <div className="rounded-lg border border-app-border divide-y divide-app-border bg-app-surface overflow-hidden">
              {/* Header row */}
              <div className="grid grid-cols-5 px-4 py-2.5 text-xs font-semibold text-app-subtle uppercase tracking-wider max-sm:hidden">
                <span className="col-span-2">Podcast</span>
                <span className="text-center">Plays</span>
                <span className="text-center">Likes</span>
                <span className="text-center">Comments</span>
              </div>
              {analyticsData
                .sort((a, b) => (b.total_plays || 0) - (a.total_plays || 0))
                .map((a) => (
                  <div key={a.podcast_id} className="grid grid-cols-5 items-center px-4 py-3 hover:bg-app-raised transition-colors max-sm:grid-cols-1 max-sm:gap-2">
                    <span className="col-span-2 text-sm font-medium text-app-text truncate">
                      {a.podcast_name || "Untitled"}
                    </span>
                    <span className="text-center text-sm tabular-nums text-app-muted max-sm:text-left">
                      <span className="sm:hidden text-xs text-app-subtle">Plays: </span>
                      {(a.total_plays || 0).toLocaleString()}
                    </span>
                    <span className="text-center text-sm tabular-nums text-app-muted max-sm:text-left">
                      <span className="sm:hidden text-xs text-app-subtle">Likes: </span>
                      {(a.total_likes || 0).toLocaleString()}
                    </span>
                    <span className="text-center text-sm tabular-nums text-app-muted max-sm:text-left">
                      <span className="sm:hidden text-xs text-app-subtle">Comments: </span>
                      {(a.total_comments || 0).toLocaleString()}
                    </span>
                  </div>
                ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
