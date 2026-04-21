"use client";
import { useState } from "react";
import { createSeriesAction } from "@/app/lib/actions";
import { toast } from "sonner";
import { X, Layers } from "lucide-react";

interface CreateSeriesModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const CreateSeriesModal = ({ isOpen, onClose }: CreateSeriesModalProps) => {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!title.trim()) {
      toast.error("Series title is required");
      return;
    }

    setLoading(true);
    try {
      const result = await createSeriesAction({
        title: title.trim(),
        description: description.trim() || undefined,
      });

      if (result.success) {
        toast.success("Series created successfully!");
        setTitle("");
        setDescription("");
        onClose();
      } else {
        toast.error(result.error || "Failed to create series");
      }
    } catch (error) {
      console.error("Error creating series:", error);
      toast.error("Failed to create series");
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setTitle("");
      setDescription("");
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={handleClose}
      />

      <div className="relative w-full max-w-md bg-app-surface border border-app-border rounded-xl shadow-app-xl overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-app-border">
          <div className="flex items-center gap-2">
            <Layers className="text-app-accent w-5 h-5" />
            <h2 className="text-lg font-bold text-app-text">Create Series</h2>
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
            <div>
              <label htmlFor="title" className="block text-sm font-semibold text-app-text mb-1.5">
                Series Title <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="My Podcast Series"
                disabled={loading}
                className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                maxLength={100}
              />
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-semibold text-app-text mb-1.5">
                Description <span className="text-app-subtle text-xs font-normal">(Optional)</span>
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="What is this series about..."
                disabled={loading}
                rows={3}
                className="w-full px-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent resize-none disabled:opacity-50"
                maxLength={500}
              />
            </div>
          </div>

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
              disabled={loading || !title.trim()}
              className="flex-1 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50">
              {loading ? "Creating..." : "Create Series"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateSeriesModal;
