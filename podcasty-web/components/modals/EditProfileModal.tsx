"use client";
import { useState } from "react";
import { updateUser } from "@/app/lib/api/users";
import { toast } from "sonner";
import { X, User, Image as ImageIcon } from "lucide-react";
import { useRouter } from "next/navigation";

interface EditProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  currentUsername: string;
  currentAvatarUrl: string;
}

const EditProfileModal = ({ 
  isOpen, 
  onClose, 
  userId, 
  currentUsername, 
  currentAvatarUrl 
}: EditProfileModalProps) => {
  const [username, setUsername] = useState(currentUsername);
  const [avatarUrl, setAvatarUrl] = useState(currentAvatarUrl);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!username.trim()) {
      toast.error("Username is required");
      return;
    }

    // Check if anything changed
    if (username === currentUsername && avatarUrl === currentAvatarUrl) {
      toast.info("No changes to save");
      return;
    }

    setLoading(true);
    try {
      const updateData: { username?: string; avatar_url?: string } = {};
      
      if (username !== currentUsername) {
        updateData.username = username.trim();
      }
      if (avatarUrl !== currentAvatarUrl) {
        updateData.avatar_url = avatarUrl.trim();
      }

      await updateUser(userId, updateData);
      
      toast.success("Profile updated successfully!");
      router.refresh();
      onClose();
    } catch (error: any) {
      console.error("Error updating profile:", error);
      toast.error(error.message || "Failed to update profile");
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setUsername(currentUsername);
      setAvatarUrl(currentAvatarUrl);
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
            <User className="text-app-accent w-5 h-5" />
            <h2 className="text-lg font-bold text-app-text">Edit Profile</h2>
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
            {/* Username Input */}
            <div>
              <label htmlFor="username" className="block text-sm font-semibold text-app-text mb-1.5">
                Username <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-app-muted" />
                <input
                  type="text"
                  id="username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Enter your username"
                  disabled={loading}
                  className="w-full pl-10 pr-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                  maxLength={50}
                />
              </div>
            </div>

            {/* Avatar URL Input */}
            <div>
              <label htmlFor="avatar" className="block text-sm font-semibold text-app-text mb-1.5">
                Avatar URL
              </label>
              <div className="relative">
                <ImageIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-app-muted" />
                <input
                  type="url"
                  id="avatar"
                  value={avatarUrl}
                  onChange={(e) => setAvatarUrl(e.target.value)}
                  placeholder="https://example.com/avatar.jpg"
                  disabled={loading}
                  className="w-full pl-10 pr-3 py-2 rounded-lg border border-app-border bg-app-raised text-app-text placeholder:text-app-subtle text-sm focus:outline-none focus:ring-2 focus:ring-app-accent disabled:opacity-50"
                />
              </div>
              <p className="text-xs text-app-subtle mt-1.5">
                Enter the URL of your profile picture or use services like{" "}
                <a 
                  href="https://api.dicebear.com/7.x/avataaars/svg?seed=your-name" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-app-accent hover:underline">
                  DiceBear
                </a>
              </p>
            </div>

            {/* Avatar Preview */}
            {avatarUrl && (
              <div className="flex items-center gap-3 p-3 rounded-lg bg-app-raised border border-app-border">
                <div className="relative size-12 rounded-full overflow-hidden border border-app-border shrink-0">
                  <img
                    src={avatarUrl}
                    alt="Avatar preview"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = "/images/1.jpeg";
                    }}
                  />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-app-text">{username || "Username"}</p>
                  <p className="text-xs text-app-subtle">Preview</p>
                </div>
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex gap-3 mt-6">
            <button
              type="button"
              onClick={handleClose}
              disabled={loading}
              className="flex-1 px-4 py-2 rounded-lg border border-app-border bg-transparent text-app-text text-sm font-semibold hover:bg-app-raised transition-colors disabled:opacity-50">
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !username.trim()}
              className="flex-1 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed">
              {loading ? "Saving..." : "Save Changes"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditProfileModal;
