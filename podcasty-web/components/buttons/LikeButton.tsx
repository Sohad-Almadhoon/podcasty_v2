"use client";
import { useState } from "react";
import { BsHeart, BsHeartFill } from "react-icons/bs";
import { toggleLikeAction } from "@/app/lib/actions";

const LikeButton = ({
  podcastId,
  initialLiked = false,
  initialCount = 0,
}: {
  podcastId: string;
  userId?: string; // kept for compatibility but not used
  initialLiked?: boolean;
  initialCount?: number;
}) => {
  const [liked, setLiked] = useState(initialLiked);
  const [count, setCount] = useState(initialCount);
  const [loading, setLoading] = useState(false);

  const handleToggleLike = async () => {
    if (loading) return;
    
    setLoading(true);
    // Optimistic update
    const newLiked = !liked;
    const newCount = newLiked ? count + 1 : count - 1;
    setLiked(newLiked);
    setCount(newCount);

    try {
      const result = await toggleLikeAction(podcastId, liked);
      
      if (result.success && result.liked !== undefined && result.count !== undefined) {
        // Update with server response
        setLiked(result.liked);
        setCount(result.count);
      } else {
        // Revert on error
        setLiked(liked);
        setCount(count);
      }
    } catch (error) {
      console.error('Error toggling like:', error);
      // Revert on error
      setLiked(liked);
      setCount(count);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      type="button"
      onClick={handleToggleLike}
      disabled={loading}
      title={liked ? "Unlike" : "Like"}
      className={`inline-flex items-center gap-1.5 h-10 px-4 rounded-lg border text-sm font-medium transition-colors disabled:opacity-50 ${
        liked
          ? "border-red-500/40 bg-red-500/10 text-red-400 hover:bg-red-500/20"
          : "border-app-border bg-app-surface text-app-muted hover:text-app-text hover:bg-app-raised"
      }`}>
      {liked ? <BsHeartFill className="text-red-400" /> : <BsHeart />}
      <span className="text-xs tabular-nums">{count}</span>
    </button>
  );
};

export default LikeButton;
