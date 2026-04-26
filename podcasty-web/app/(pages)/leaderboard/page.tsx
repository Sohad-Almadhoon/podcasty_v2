import Link from "next/link";
import Image from "next/image";
import { fetchLeaderboard } from "@/app/lib/api-client";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { BsTrophyFill, BsHeadphones, BsHeartFill, BsMicFill } from "react-icons/bs";

export const dynamic = "force-dynamic";

export default async function LeaderboardPage() {
  const medals = ["🥇", "🥈", "🥉"];
  
  let leaderboard: any[] = [];
  try {
    leaderboard = await fetchLeaderboard({ limit: 20, sort_by: 'plays' });
  } catch (error) {
    if ((error as { digest?: string })?.digest === 'DYNAMIC_SERVER_USAGE') throw error;
    console.error('Error fetching leaderboard:', error);
  }

  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-6 py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Community</p>
        <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
          <BsTrophyFill className="text-yellow-500" /> Leaderboard
        </h1>
        <p className="text-sm text-app-muted mt-1">Top creators ranked by total plays</p>
      </div>

      <div className="px-6 py-8">
        {/* Top 3 podium */}
        {leaderboard.length >= 3 && (
          <div className="grid grid-cols-3 gap-3 mb-10">
            {leaderboard.slice(0, 3).map((entry, i) => (
            <Link
              key={entry.user_id}
              href={`/profile/${entry.user_id}`}
              className={`flex flex-col items-center gap-3 p-3 sm:p-5 rounded-xl border transition-all hover:shadow-app-md min-w-0 ${
                i === 0
                  ? "border-yellow-500/40 bg-yellow-500/5"
                  : "border-app-border bg-app-surface hover:border-app-muted"
              }`}>
              <span className="text-2xl">{medals[i]}</span>
              <div className="relative size-14 rounded-full overflow-hidden border-2 border-app-border">
                <Image src={entry.avatar_url} alt={entry.username} fill unoptimized className="object-cover" />
              </div>
              <div className="text-center min-w-0 w-full">
                <p className="text-sm font-semibold text-app-text truncate">{entry.username}</p>
                <p className="text-xs text-app-subtle mt-0.5">{entry.total_plays.toLocaleString()} plays</p>
              </div>
              <div className="flex gap-1.5 flex-wrap justify-center">
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                  <BsMicFill className="text-[10px]" /> {entry.podcast_count}
                </Badge>
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                  <BsHeartFill className="text-[10px]" /> {entry.total_likes}
                </Badge>
              </div>
            </Link>
            ))}
          </div>
        )}

        <Separator className="bg-app-border mb-6" />

        {/* Full table */}
        <ul className="flex flex-col gap-2">
          {leaderboard.map((entry, i) => (
            <li key={entry.user_id}>
              <Link href={`/profile/${entry.user_id}`}>
                <div className="flex items-center gap-4 px-4 py-3 rounded-xl border border-app-border bg-app-surface hover:border-app-muted hover:bg-app-raised transition-all group">
                  <span className={`text-sm font-mono w-6 text-center shrink-0 ${i < 3 ? "text-yellow-500" : "text-app-subtle"}`}>
                    {i < 3 ? medals[i] : `${i + 1}`}
                  </span>
                  <div className="relative size-9 rounded-full overflow-hidden border border-app-border shrink-0">
                    <Image src={entry.avatar_url} alt={entry.username} fill unoptimized className="object-cover" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-app-text truncate">{entry.username}</p>
                    <p className="text-xs text-app-subtle">{entry.podcast_count} podcast{entry.podcast_count !== 1 ? "s" : ""}</p>
                  </div>
                  <div className="flex items-center gap-3 shrink-0">
                    <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                      <BsHeadphones /> {entry.total_plays.toLocaleString()}
                    </Badge>
                    <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                      <BsHeartFill className="text-[10px]" /> {entry.total_likes.toLocaleString()}
                    </Badge>
                  </div>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
