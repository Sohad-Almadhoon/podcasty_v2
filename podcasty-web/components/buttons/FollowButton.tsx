"use client";
import { useState, useEffect } from "react";
import { BsPersonPlusFill, BsPersonCheckFill } from "react-icons/bs";
import { toggleFollowAction } from "@/app/lib/actions";
import { checkFollowStatus } from "@/app/lib/api/users";
import { toast } from "sonner";

interface FollowButtonProps {
  userId: string;
  currentUserId?: string;
}

const FollowButton = ({ userId, currentUserId }: FollowButtonProps) => {
  const isSelf = !!currentUserId && currentUserId === userId;
  const [following, setFollowing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(!isSelf);

  useEffect(() => {
    if (isSelf) return;
    // Check initial follow status
    checkFollowStatus(userId)
      .then(data => {
        setFollowing(data.following);
      })
      .catch(err => {
        console.error('Failed to check follow status:', err);
      })
      .finally(() => {
        setChecking(false);
      });
  }, [userId, isSelf]);

  // Don't render if viewing own profile
  if (isSelf) {
    return null;
  }

  const handleToggle = async () => {
    setLoading(true);
    try {
      const result = await toggleFollowAction(userId, following);
      
      if (result.success && result.following !== undefined) {
        setFollowing(result.following);
        toast.success(result.following ? 'Following user!' : 'Unfollowed user');
      } else {
        toast.error(result.error || 'Failed to update follow status');
      }
    } catch (error) {
      console.error('Error toggling follow:', error);
      toast.error('Failed to update follow status');
    } finally {
      setLoading(false);
    }
  };

  if (checking) {
    return (
      <button 
        disabled
        className="flex items-center gap-2 px-4 py-2 rounded-lg border border-app-border text-app-muted text-xs font-semibold opacity-50">
        <BsPersonPlusFill /> Loading...
      </button>
    );
  }

  return (
    <button
      onClick={handleToggle}
      disabled={loading}
      className={`flex items-center gap-2 px-4 py-2 rounded-lg border text-xs font-semibold transition-colors disabled:opacity-50 ${
        following
          ? 'border-app-border bg-app-surface text-app-muted hover:border-red-500/40 hover:text-red-500 hover:bg-red-500/5'
          : 'border-app-accent text-app-accent hover:bg-app-accent hover:text-white'
      }`}
    >
      {following ? <BsPersonCheckFill /> : <BsPersonPlusFill />}
      {loading ? 'Loading...' : (following ? 'Following' : 'Follow')}
    </button>
  );
};

export default FollowButton;
