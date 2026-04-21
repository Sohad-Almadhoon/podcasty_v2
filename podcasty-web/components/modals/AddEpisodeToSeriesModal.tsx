"use client";
import { useEffect, useState } from "react";
import { addEpisodeToSeriesAction } from "@/app/lib/actions";
import { fetchUserPodcasts } from "@/app/lib/api/users";
import { toast } from "sonner";
import { X, Mic2, Search } from "lucide-react";
import Image from "next/image";

interface AddEpisodeToSeriesModalProps {
  isOpen: boolean;
  onClose: () => void;
  seriesId: string;
  userId: string;
}

const AddEpisodeToSeriesModal = ({ isOpen, onClose, seriesId, userId }: AddEpisodeToSeriesModalProps) => {
  const [podcasts, setPodcasts] = useState<any[]>([]);
  const [filteredPodcasts, setFilteredPodcasts] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [selectedPodcastId, setSelectedPodcastId] = useState("");
  const [seasonNumber, setSeasonNumber] = useState(1);
  const [episodeNumber, setEpisodeNumber] = useState(1);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setFetching(true);
      fetchUserPodcasts(userId)
        .then((data) => {
          setPodcasts(data);
          setFilteredPodcasts(data);
        })
        .catch(() => toast.error("Failed to load your podcasts"))
        .finally(() => setFetching(false));
    }
  }, [isOpen, userId]);

  useEffect(() => {
    if (!search.trim()) {
      setFilteredPodcasts(podcasts);
    } else {
      const q = search.toLowerCase();
      setFilteredPodcasts(podcasts.filter((p) => p.podcast_name?.toLowerCase().includes(q)));
    }
  }, [search, podcasts]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedPodcastId) {
      toast.error("Please select a podcast");
      return;
    }

    setLoading(true);
    try {
      const result = await addEpisodeToSeriesAction({
        series_id: seriesId,
        podcast_id: selectedPodcastId,
        season_number: seasonNumber,
        episode_number: episodeNumber,
      });

      if (result.success) {
        toast.success("Episode added to series!");
        handleClose();
      } else {
        toast.error(result.error || "Failed to add episode");
      }
    } catch (error) {
      console.error("Error adding episode:", error);
      toast.error("Failed to add episode");
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setSelectedPodcastId("");
      setSearch("");
      setSeasonNumber(1);
      setEpisodeNumber(1);
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={handleClose} />

      <div className="relative w-full max-w-lg bg-app-surface border border-app-border rounded-xl shadow-app-xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-app-border">
          <div className="flex items-center gap-2">
            <Mic2 className="text-app-accent w-5 h-5" />
            <h2 className="text-lg font-bold text-app-text">Add Episode</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-app-muted hover:text-app-text transition-colors disabled:opacity-50">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6">
          <div className="space-y-4">
            {/* Search */}
            <div>
              <label className="block text-sm font-semibold text-app-text mb-1.5">
                Select Podcast <span className="text-red-500">*</span>
              </label>
              <div className="relative mb-2">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-app-subtle" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search your podcasts..."
                  className="w-full pl-9 pr-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent"
                />
              </div>

              {/* Podcast list */}
              <div className="max-h-48 overflow-y-auto rounded-lg border border-app-border divide-y divide-app-border">
                {fetching ? (
                  <p className="text-xs text-app-subtle text-center py-6">Loading podcasts...</p>
                ) : filteredPodcasts.length === 0 ? (
                  <p className="text-xs text-app-subtle text-center py-6">No podcasts found</p>
                ) : (
                  filteredPodcasts.map((p) => (
                    <button
                      type="button"
                      key={p.id}
                      onClick={() => setSelectedPodcastId(p.id)}
                      className={`w-full flex items-center gap-3 px-3 py-2.5 text-left hover:bg-app-raised transition-colors ${
                        selectedPodcastId === p.id ? "bg-app-raised ring-1 ring-app-accent" : ""
                      }`}>
                      <div className="relative size-9 rounded-lg overflow-hidden border border-app-border shrink-0">
                        <Image
                          src={p.image_url?.trim() || "/images/1.jpeg"}
                          alt={p.podcast_name}
                          fill
                          unoptimized
                          className="object-cover"
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-app-text truncate">{p.podcast_name}</p>
                        <p className="text-xs text-app-subtle truncate">{p.description}</p>
                      </div>
                    </button>
                  ))
                )}
              </div>
            </div>

            {/* Season & Episode numbers */}
            <div className="flex gap-3">
              <div className="flex-1">
                <label htmlFor="season" className="block text-sm font-semibold text-app-text mb-1.5">
                  Season
                </label>
                <input
                  type="number"
                  id="season"
                  min={1}
                  value={seasonNumber}
                  onChange={(e) => setSeasonNumber(Number(e.target.value))}
                  disabled={loading}
                  className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                />
              </div>
              <div className="flex-1">
                <label htmlFor="episode" className="block text-sm font-semibold text-app-text mb-1.5">
                  Episode
                </label>
                <input
                  type="number"
                  id="episode"
                  min={1}
                  value={episodeNumber}
                  onChange={(e) => setEpisodeNumber(Number(e.target.value))}
                  disabled={loading}
                  className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                />
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 mt-6">
            <button
              type="button"
              onClick={handleClose}
              disabled={loading}
              className="flex-1 px-4 py-2 rounded-lg border border-app-border text-app-muted text-sm font-semibold hover:border-app-muted hover:text-app-text transition-colors disabled:opacity-50">
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !selectedPodcastId}
              className="flex-1 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50">
              {loading ? "Adding..." : "Add Episode"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddEpisodeToSeriesModal;
