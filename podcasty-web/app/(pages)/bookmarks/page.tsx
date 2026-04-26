import Link from "next/link";
import Image from "next/image";
import { fetchBookmarks } from "@/app/lib/api-client";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { BsBookmarkFill, BsHeadphones, BsHeartFill } from "react-icons/bs";
import { CalendarDays, Mic2 } from "lucide-react";

export default async function BookmarksPage() {
  let bookmarks: any[] = [];
  try {
    bookmarks = await fetchBookmarks();
  } catch (error) {
    console.error('Error fetching bookmarks:', error);
  }
  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-4 sm:px-6 py-6 sm:py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Library</p>
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
            <BsBookmarkFill className="text-app-accent" /> Bookmarks
          </h1>
          <Badge variant="outline" className="border-app-border text-app-subtle">
            {bookmarks.length} saved
          </Badge>
        </div>
      </div>

      <div className="px-4 sm:px-6 py-6 sm:py-8">
        {bookmarks.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <BsBookmarkFill className="text-app-border text-5xl mb-4" />
            <p className="text-app-muted text-sm">No bookmarks yet.</p>
            <p className="text-app-subtle text-xs mt-1">Save podcasts to listen later.</p>
            <Link
              href="/podcasts"
              className="mt-5 inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity">
              Browse Podcasts
            </Link>
          </div>
        ) : (
          <ul className="grid grid-cols-1 xl:grid-cols-2 gap-3">
            {bookmarks.map((bookmark) => {
              const p = bookmark.podcasts;
              if (!p) return null; // Skip if podcast data is missing
              const minutes = p.duration_seconds ? Math.floor(p.duration_seconds / 60) : null;
              return (
                <li key={bookmark.id}>
                  <Link href={`/podcasts/${p.id}`}>
                    <div className="flex items-center gap-3 sm:gap-4 px-3 sm:px-4 py-3 sm:py-4 rounded-xl border border-app-border bg-app-surface hover:border-app-muted hover:shadow-app transition-all group">
                      <div className="relative w-14 h-14 sm:w-16 sm:h-16 shrink-0 rounded-lg overflow-hidden border border-app-border">
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
                        <p className="text-xs text-app-subtle truncate mt-0.5">{p.description}</p>
                        <div className="flex items-center flex-wrap gap-x-3 gap-y-1 mt-2">
                          <span className="text-xs text-app-subtle flex items-center gap-1">
                            <Mic2 className="w-3 h-3" />
                            {p.users?.username || "Unknown"}
                          </span>
                          {minutes && (
                            <span className="text-xs text-app-subtle">{minutes} min</span>
                          )}
                          {p.category && (
                            <Badge variant="outline" className="border-app-border text-app-subtle text-xs py-0">
                              {p.category}
                            </Badge>
                          )}
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0 sm:hidden">
                            <BsHeadphones /> {(p.play_count || 0).toLocaleString()}
                          </Badge>
                        </div>
                      </div>
                      <div className="flex flex-col items-end gap-2 shrink-0 max-sm:hidden">
                        <div className="flex gap-2">
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                            <BsHeadphones /> {(p.play_count || 0).toLocaleString()}
                          </Badge>
                          <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
                            <BsHeartFill className="text-[10px]" /> {p.likes?.[0]?.count || 0}
                          </Badge>
                        </div>
                        <span className="text-xs text-app-subtle flex items-center gap-1">
                          <CalendarDays className="w-3 h-3" />
                          Saved {new Date(bookmark.created_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
