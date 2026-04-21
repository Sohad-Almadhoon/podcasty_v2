"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { fetchPlaylists } from "@/app/lib/api-client";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { BsCollectionPlayFill, BsHeadphones, BsPlayFill } from "react-icons/bs";
import { Plus } from "lucide-react";
import CreatePlaylistModal from "@/components/modals/CreatePlaylistModal";

export default function PlaylistsPage() {
  const [playlists, setPlaylists] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    loadPlaylists();
  }, []);

  const loadPlaylists = async () => {
    setLoading(true);
    try {
      const data = await fetchPlaylists();
      setPlaylists(data);
    } catch (error) {
      console.error('Error fetching playlists:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleModalClose = () => {
    setIsModalOpen(false);
    loadPlaylists(); // Refresh playlists after creating
  };
  return (
    <div className="min-h-screen">
      <CreatePlaylistModal isOpen={isModalOpen} onClose={handleModalClose} />
      
      <div className="border-b border-app-border px-6 py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Library</p>
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-app-text flex items-center gap-2">
            <BsCollectionPlayFill className="text-app-accent" /> Playlists
          </h1>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity">
            <Plus className="w-3.5 h-3.5" /> New Playlist
          </button>
        </div>
      </div>

      <div className="px-6 py-8">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-app-accent"></div>
          </div>
        ) : playlists.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <BsCollectionPlayFill className="text-app-border text-5xl mb-4" />
            <p className="text-app-muted text-sm">No playlists yet.</p>
            <p className="text-app-subtle text-xs mt-1">Create a playlist to organise your episodes.</p>
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {playlists.map((playlist: any) => {
              const itemCount = playlist.item_count || 0;
              return (
                <Link
                  key={playlist.id}
                  href={`/playlists/${playlist.id}`}
                  className="rounded-xl border border-app-border bg-app-surface hover:border-app-muted hover:shadow-app-md transition-all group overflow-hidden">
                  {/* Cover stack */}
                  <div className="relative h-36 bg-app-raised overflow-hidden">
                    <div className="flex items-center justify-center h-full">
                      <BsCollectionPlayFill className="text-app-border text-4xl" />
                    </div>
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                    <div className="absolute bottom-3 left-3">
                      <Badge variant="outline" className="border-white/20 text-white text-xs bg-black/30">
                        {itemCount} episode{itemCount !== 1 ? "s" : ""}
                      </Badge>
                    </div>
                    {itemCount > 0 && (
                      <button className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-11 h-11 rounded-full bg-app-accent/90 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-app-md">
                        <BsPlayFill className="text-white text-xl ml-0.5" />
                      </button>
                    )}
                  </div>

                  {/* Info */}
                  <div className="p-4">
                    <p className="text-sm font-semibold text-app-text truncate">{playlist.name}</p>
                    <p className="text-xs text-app-subtle mt-0.5">
                      Created {new Date(playlist.created_at).toLocaleDateString()}
                    </p>
                    {playlist.description && (
                      <p className="text-xs text-app-muted mt-2 line-clamp-2">{playlist.description}</p>
                    )}
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
