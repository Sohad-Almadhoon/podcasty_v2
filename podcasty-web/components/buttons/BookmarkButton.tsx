"use client";
import { useState, useEffect } from "react";
import { BsBookmarkFill, BsBookmark } from "react-icons/bs";
import { toggleBookmarkAction } from "@/app/lib/actions";
import { checkBookmarkStatus } from "@/app/lib/api/bookmarks";
import { toast } from "sonner";

interface BookmarkButtonProps {
  podcastId: string;
}

const BookmarkButton = ({ podcastId }: BookmarkButtonProps) => {
  const [bookmarked, setBookmarked] = useState(false);
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    // Check initial bookmark status
    checkBookmarkStatus(podcastId)
      .then(data => {
        setBookmarked(data.bookmarked);
      })
      .catch(err => {
        console.error('Failed to check bookmark status:', err);
      })
      .finally(() => {
        setChecking(false);
      });
  }, [podcastId]);

  const handleToggle = async () => {
    setLoading(true);
    try {
      const result = await toggleBookmarkAction(podcastId, bookmarked);
      
      if (result.success && result.bookmarked !== undefined) {
        setBookmarked(result.bookmarked);
        toast.success(result.bookmarked ? 'Podcast saved!' : 'Removed from saved');
      } else {
        toast.error(result.error || 'Failed to update bookmark');
      }
    } catch (error) {
      console.error('Error toggling bookmark:', error);
      toast.error('Failed to update bookmark');
    } finally {
      setLoading(false);
    }
  };

  if (checking) {
    return (
      <button
        disabled
        title="Save"
        className="flex items-center justify-center gap-1.5 h-9 px-3 rounded-lg border border-app-border bg-app-surface text-app-muted opacity-50">
        <BsBookmark className="text-sm" />
        <span className="text-xs font-medium hidden sm:inline">Save</span>
      </button>
    );
  }

  return (
    <button
      onClick={handleToggle}
      disabled={loading}
      title={bookmarked ? "Saved" : "Save"}
      className={`flex items-center justify-center gap-1.5 h-9 px-3 rounded-lg border transition-colors disabled:opacity-50 ${
        bookmarked
          ? 'border-app-accent/40 bg-app-accent/10 text-app-accent hover:bg-app-accent/20'
          : 'border-app-border bg-app-surface text-app-muted hover:text-app-text hover:border-app-muted'
      }`}
    >
      {bookmarked ? <BsBookmarkFill className="text-sm" /> : <BsBookmark className="text-sm" />}
      <span className="text-xs font-medium hidden sm:inline">{bookmarked ? "Saved" : "Save"}</span>
    </button>
  );
};

export default BookmarkButton;
