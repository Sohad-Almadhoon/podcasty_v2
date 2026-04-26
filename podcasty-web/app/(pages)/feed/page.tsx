"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { fetchFeed } from "@/app/lib/api-client";
import { fetchFollows } from "@/app/lib/api/users";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { BsPeopleFill, BsHeadphones, BsHeartFill } from "react-icons/bs";
import { Mic2, UserPlus } from "lucide-react";

export default function FeedPage() {
  const [feedPodcasts, setFeedPodcasts] = useState<any[]>([]);
  const [follows, setFollows] = useState<any[]>([]);
  const router = useRouter();

  useEffect(() => {
    Promise.all([
      fetchFeed({ limit: 20 }),
      fetchFollows().catch(() => []),
    ])
      .then(([feed, followData]) => {
        setFeedPodcasts(feed);
        setFollows(followData);
      })
      .catch((error) => {
        console.error('Error fetching feed:', error);
      });
  }, []);
  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-4 sm:px-6 py-6 sm:py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Social</p>
        <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
          <BsPeopleFill className="text-app-accent" /> Following
        </h1>
        <p className="text-sm text-app-muted mt-1">
          Latest episodes from creators you follow
        </p>
      </div>

      <div className="px-4 sm:px-6 py-6 sm:py-8 flex flex-col lg:flex-row gap-8">
        {/* Feed */}
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-4">Recent Episodes</p>
          {feedPodcasts.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center rounded-xl border border-dashed border-app-border">
              <BsPeopleFill className="text-app-border text-5xl mb-4" />
              <p className="text-app-muted text-sm">Nothing in your feed yet.</p>
              <p className="text-app-subtle text-xs mt-1">Follow some creators to see their latest episodes here.</p>
            </div>
          ) : (
            <ul className="flex flex-col gap-3">
              {feedPodcasts.map((p) => {
                const author = p.users;
                const minutes = p.duration_seconds ? Math.floor(p.duration_seconds / 60) : null;
                return (
                  <li key={p.id}>
                    <div 
                      onClick={() => router.push(`/podcasts/${p.id}`)}
                      className="flex items-center gap-4 px-4 py-4 rounded-xl border border-app-border bg-app-surface hover:border-app-muted hover:shadow-app transition-all group cursor-pointer">
                      <div className="relative w-16 h-16 shrink-0 rounded-lg overflow-hidden border border-app-border">
                          <Image
                            src={p.image_url || "/images/1.jpeg"}
                            alt={p.podcast_name}
                            fill
                            unoptimized
                            className="object-cover group-hover:scale-105 transition-transform duration-300"
                          />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-app-text truncate">{p.podcast_name}</p>
                          <p className="text-xs text-app-subtle line-clamp-1 mt-0.5">{p.description}</p>
                          <div className="flex items-center gap-3 mt-2">
                            <Link
                              href={`/profile/${p.user_id}`}
                              onClick={(e) => e.stopPropagation()}
                              className="flex items-center gap-1.5 group/author">
                              <div className="relative size-4 rounded-full overflow-hidden border border-app-border">
                                <Image src={author.avatar_url} alt={author.username} fill unoptimized />
                              </div>
                              <span className="text-xs text-app-subtle group-hover/author:text-app-text transition-colors">
                                {author.username}
                              </span>
                            </Link>
                            {p.category && (
                              <Badge variant="outline" className="border-app-border text-app-subtle text-xs py-0">
                                {p.category}
                              </Badge>
                            )}
                            {minutes && (
                              <span className="text-xs text-app-subtle">{minutes} min</span>
                            )}
                          </div>
                        </div>
                        <div className="flex gap-2 shrink-0">
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                            <BsHeadphones /> {p.play_count.toLocaleString()}
                          </Badge>
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                            <BsHeartFill className="text-[10px]" /> {p.likes?.[0]?.count || 0}
                          </Badge>
                        </div>
                      </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>

        {/* Following sidebar */}
        <div className="w-full lg:w-60 shrink-0">
          <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-4">
            Following ({follows.length})
          </p>
          {follows.length > 0 ? (
            <ul className="flex flex-col gap-2">
              {follows.map((follow) => {
                const user = follow.users;
                if (!user) return null;
                return (
                  <li key={follow.id}>
                    <Link href={`/profile/${follow.following_id}`}>
                      <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg border border-app-border bg-app-surface hover:bg-app-raised hover:border-app-muted transition-all">
                        <div className="relative size-8 rounded-full overflow-hidden border border-app-border shrink-0">
                          <Image src={user.avatar_url} alt={user.username} fill unoptimized className="object-cover" />
                        </div>
                        <span className="text-sm text-app-text truncate flex-1">{user.username}</span>
                      </div>
                    </Link>
                  </li>
                );
              })}
            </ul>
          ) : (
            <div className="rounded-lg border border-dashed border-app-border p-4 text-center">
              <p className="text-xs text-app-subtle">Not following anyone yet</p>
            </div>
          )}

          <Separator className="bg-app-border my-4" />

          <Link
            href="/podcasts"
            className="flex items-center gap-2 px-3 py-2.5 rounded-lg border border-dashed border-app-border text-app-subtle hover:text-app-text hover:border-app-muted transition-colors text-sm">
            <UserPlus className="w-4 h-4" /> Find creators to follow
          </Link>
        </div>
      </div>
    </div>
  );
}
