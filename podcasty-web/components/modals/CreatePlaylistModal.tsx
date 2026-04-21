"use client";
import { useState } from "react";
import { createPlaylistAction } from "@/app/lib/actions";
import { toast } from "sonner";
import { X } from "lucide-react";
import { BsCollectionPlayFill } from "react-icons/bs";

interface CreatePlaylistModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const CreatePlaylistModal = ({ isOpen, onClose }: CreatePlaylistModalProps) => {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name.trim()) {
      toast.error("Playlist name is required");
      return;
    }

    setLoading(true);
    try {
      const result = await createPlaylistAction({
        name: name.trim(),
        description: description.trim() || undefined,
      });

      if (result.success) {
        toast.success("Playlist created successfully!");
        setName("");
        setDescription("");
        onClose();
      } else {
        toast.error(result.error || "Failed to create playlist");
      }
    } catch (error) {
      console.error("Error creating playlist:", error);
      toast.error("Failed to create playlist");
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setName("");
      setDescription("");
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={handleClose}
      />
      
      {/* Modal */}
      <div className="relative w-full max-w-md bg-app-surface border border-app-border rounded-xl shadow-app-xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-app-border">
          <div className="flex items-center gap-2">
            <BsCollectionPlayFill className="text-app-accent text-lg" />
            <h2 className="text-lg font-bold text-app-text">Create Playlist</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-app-muted hover:text-app-text transition-colors disabled:opacity-50">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6">
          <div className="space-y-4">
            {/* Name Input */}
            <div>
              <label htmlFor="name" className="block text-sm font-semibold text-app-text mb-1.5">
                Playlist Name <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Weekend Favorites"
                disabled={loading}
                className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                maxLength={100}
              />
            </div>

            {/* Description Input */}
            <div>
              <label htmlFor="description" className="block text-sm font-semibold text-app-text mb-1.5">
                Description <span className="text-app-subtle text-xs font-normal">(Optional)</span>
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Podcasts to enjoy on weekends..."
                disabled={loading}
                rows={3}
                className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent resize-none disabled:opacity-50"
                maxLength={500}
              />
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
              disabled={loading || !name.trim()}
              className="flex-1 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50">
              {loading ? "Creating..." : "Create Playlist"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreatePlaylistModal;
