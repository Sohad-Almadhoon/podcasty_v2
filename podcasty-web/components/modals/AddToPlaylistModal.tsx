"use client";
import { useState, useEffect } from "react";
import { addToPlaylistAction, createPlaylistAction } from "@/app/lib/actions";
import { fetchPlaylists } from "@/app/lib/api-client";
import { toast } from "sonner";
import { X, Plus, Check } from "lucide-react";
import { BsCollectionPlayFill } from "react-icons/bs";

interface AddToPlaylistModalProps {
  isOpen: boolean;
  onClose: () => void;
  podcastId: string;
}

const AddToPlaylistModal = ({ isOpen, onClose, podcastId }: AddToPlaylistModalProps) => {
  const [playlists, setPlaylists] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [addingTo, setAddingTo] = useState<string | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newPlaylistName, setNewPlaylistName] = useState("");
  const [newPlaylistDescription, setNewPlaylistDescription] = useState("");
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadPlaylists();
    }
  }, [isOpen]);

  const loadPlaylists = async () => {
    setLoading(true);
    try {
      const data = await fetchPlaylists();
      setPlaylists(data);
    } catch (error) {
      console.error("Error loading playlists:", error);
      toast.error("Failed to load playlists");
    } finally {
      setLoading(false);
    }
  };

  const handleAddToPlaylist = async (playlistId: string, playlistName: string) => {
    setAddingTo(playlistId);
    try {
      const result = await addToPlaylistAction(playlistId, podcastId);
      if (result.success) {
        toast.success(`Added to "${playlistName}"`);
        onClose();
      } else {
        if (result.error?.includes("already in playlist")) {
          toast.error("This podcast is already in that playlist");
        } else {
          toast.error(result.error || "Failed to add to playlist");
        }
      }
    } catch (error) {
      console.error("Error adding to playlist:", error);
      toast.error("Failed to add to playlist");
    } finally {
      setAddingTo(null);
    }
  };

  const handleCreateAndAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!newPlaylistName.trim()) {
      toast.error("Playlist name is required");
      return;
    }

    setCreating(true);
    try {
      // Create playlist
      const createResult = await createPlaylistAction({
        name: newPlaylistName.trim(),
        description: newPlaylistDescription.trim() || undefined,
      });

      if (createResult.success && createResult.id) {
        // Add podcast to new playlist
        const addResult = await addToPlaylistAction(createResult.id, podcastId);
        
        if (addResult.success) {
          toast.success(`Created "${newPlaylistName}" and added podcast`);
          setNewPlaylistName("");
          setNewPlaylistDescription("");
          setShowCreateForm(false);
          onClose();
        } else {
          toast.error(addResult.error || "Failed to add to new playlist");
        }
      } else {
        toast.error(createResult.error || "Failed to create playlist");
      }
    } catch (error) {
      console.error("Error creating playlist:", error);
      toast.error("Failed to create playlist");
    } finally {
      setCreating(false);
    }
  };

  const handleClose = () => {
    if (!addingTo && !creating) {
      setShowCreateForm(false);
      setNewPlaylistName("");
      setNewPlaylistDescription("");
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={handleClose}
      />
      
      {/* Modal */}
      <div className="relative w-full max-w-md bg-app-surface border border-app-border rounded-xl shadow-app-xl overflow-hidden max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-app-border shrink-0">
          <div className="flex items-center gap-2">
            <BsCollectionPlayFill className="text-app-accent text-lg" />
            <h2 className="text-lg font-bold text-app-text">Add to Playlist</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={addingTo !== null || creating}
            className="text-app-muted hover:text-app-text transition-colors disabled:opacity-50">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="overflow-y-auto flex-1">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-app-accent"></div>
            </div>
          ) : showCreateForm ? (
            // Create new playlist form
            <form onSubmit={handleCreateAndAdd} className="p-6">
              <div className="space-y-4">
                <div>
                  <label htmlFor="create-name" className="block text-sm font-semibold text-app-text mb-1.5">
                    Playlist Name <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    id="create-name"
                    value={newPlaylistName}
                    onChange={(e) => setNewPlaylistName(e.target.value)}
                    placeholder="My Awesome Playlist"
                    disabled={creating}
                    className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                    maxLength={100}
                    autoFocus
                  />
                </div>

                <div>
                  <label htmlFor="create-description" className="block text-sm font-semibold text-app-text mb-1.5">
                    Description <span className="text-app-subtle text-xs font-normal">(Optional)</span>
                  </label>
                  <textarea
                    id="create-description"
                    value={newPlaylistDescription}
                    onChange={(e) => setNewPlaylistDescription(e.target.value)}
                    placeholder="Description..."
                    disabled={creating}
                    rows={2}
                    className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent resize-none disabled:opacity-50"
                    maxLength={500}
                  />
                </div>
              </div>

              <div className="flex items-center gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => {
                    setShowCreateForm(false);
                    setNewPlaylistName("");
                    setNewPlaylistDescription("");
                  }}
                  disabled={creating}
                  className="flex-1 px-4 py-2 rounded-lg border border-app-border text-app-muted text-sm font-semibold hover:border-app-muted hover:text-app-text transition-colors disabled:opacity-50">
                  Back
                </button>
                <button
                  type="submit"
                  disabled={creating || !newPlaylistName.trim()}
                  className="flex-1 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50">
                  {creating ? "Creating..." : "Create & Add"}
                </button>
              </div>
            </form>
          ) : (
            // Playlist list
            <div className="p-4">
              {/* Create New Button */}
              <button
                onClick={() => setShowCreateForm(true)}
                disabled={addingTo !== null}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-lg border-2 border-dashed border-app-border bg-app-raised hover:border-app-accent hover:bg-app-accent/5 transition-colors group disabled:opacity-50 disabled:hover:border-app-border mb-4">
                <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-app-accent/10 text-app-accent group-hover:bg-app-accent group-hover:text-white transition-colors">
                  <Plus className="w-5 h-5" />
                </div>
                <div className="text-left flex-1">
                  <p className="text-sm font-semibold text-app-text">Create New Playlist</p>
                  <p className="text-xs text-app-subtle">Make a new playlist for this podcast</p>
                </div>
              </button>

              {/* Existing playlists */}
              {playlists.length === 0 ? (
                <div className="text-center py-8">
                  <BsCollectionPlayFill className="text-app-border text-4xl mx-auto mb-3" />
                  <p className="text-sm text-app-muted">No playlists yet</p>
                  <p className="text-xs text-app-subtle mt-1">Create one to get started</p>
                </div>
              ) : (
                <div className="space-y-2">
                  <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest px-1 mb-2">
                    Your Playlists
                  </p>
                  {playlists.map((playlist) => (
                    <button
                      key={playlist.id}
                      onClick={() => handleAddToPlaylist(playlist.id, playlist.name)}
                      disabled={addingTo !== null}
                      className="w-full flex items-center gap-3 px-4 py-3 rounded-lg border border-app-border bg-app-surface hover:border-app-muted hover:bg-app-raised transition-colors text-left disabled:opacity-50 group">
                      <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-app-accent/10 text-app-accent shrink-0">
                        <BsCollectionPlayFill className="text-base" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-app-text truncate">{playlist.name}</p>
                        <p className="text-xs text-app-subtle">
                          {playlist.item_count || 0} episode{playlist.item_count !== 1 ? "s" : ""}
                        </p>
                      </div>
                      {addingTo === playlist.id ? (
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-app-accent shrink-0" />
                      ) : (
                        <Check className="w-5 h-5 text-app-subtle opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
                      )}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AddToPlaylistModal;
