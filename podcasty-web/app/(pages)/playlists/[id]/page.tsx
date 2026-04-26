import { fetchPlaylistItems } from "@/app/lib/api-client";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { BsCollectionPlayFill, BsHeadphones, BsHeartFill } from "react-icons/bs";
import BackButton from "@/components/buttons/BackButton";
import { paramsType } from "@/app/types";
import PlaylistEpisodes from "@/components/shared/PlaylistEpisodes";

export default async function PlaylistDetailPage(props: { params: paramsType }) {
  const { id } = await props.params;
  
  let items: any[] = [];
  try {
    items = await fetchPlaylistItems(id);
  } catch (error) {
    console.error('Error fetching playlist items:', error);
  }

  // Get podcasts from items
  const podcasts = items.map(item => item.podcasts).filter(Boolean);
  
  // Calculate stats
  const totalPlays = podcasts.reduce((sum, p) => sum + (p.play_count || 0), 0);
  const totalLikes = podcasts.reduce((sum, p) => sum + (p.likes?.[0]?.count || 0), 0);
  const totalMinutes = Math.floor(podcasts.reduce((sum, p) => sum + (p.duration_seconds || 0), 0) / 60);

  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-6 py-8">
        <div className="mb-4">
          <BackButton />
        </div>
        
        <div className="flex items-center gap-4">
          <div className="flex items-center justify-center w-16 h-16 rounded-xl bg-app-accent/10 border border-app-accent/20">
            <BsCollectionPlayFill className="text-app-accent text-2xl" />
          </div>
          <div className="flex-1">
            <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-1">Playlist</p>
            <h1 className="text-2xl font-bold text-app-text">Playlist Details</h1>
            <div className="flex items-center gap-3 mt-2 flex-wrap">
              <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                <BsCollectionPlayFill className="text-[10px]" /> {podcasts.length} episode{podcasts.length !== 1 ? "s" : ""}
              </Badge>
              {totalPlays > 0 && (
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                  <BsHeadphones className="text-[10px]" /> {totalPlays.toLocaleString()} plays
                </Badge>
              )}
              {totalLikes > 0 && (
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                  <BsHeartFill className="text-[10px]" /> {totalLikes.toLocaleString()} likes
                </Badge>
              )}
              {totalMinutes > 0 && (
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs">
                  {totalMinutes} min
                </Badge>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="px-6 py-8">
        {podcasts.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <BsCollectionPlayFill className="text-app-border text-5xl mb-4" />
            <p className="text-app-muted text-sm">This playlist is empty</p>
            <p className="text-app-subtle text-xs mt-1">Add podcasts to get started</p>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-app-text">Episodes</h2>
            </div>
            
            <PlaylistEpisodes podcasts={podcasts} />
          </>
        )}
      </div>
    </div>
  );
}
