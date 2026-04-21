"use client";
import { useState, useTransition } from "react";
import Image from "next/image";
import { BsChatFill } from "react-icons/bs";
import { createComment } from "@/app/lib/api/comments";
import type { Comment } from "@/app/lib/api/comments";

interface CommentsSectionProps {
  podcastId: string;
  initialComments: Comment[];
}

export default function CommentsSection({ podcastId, initialComments }: CommentsSectionProps) {
  const [comments, setComments] = useState<Comment[]>(initialComments);
  const [newComment, setNewComment] = useState("");
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    setError(null);
    startTransition(async () => {
      try {
        const comment = await createComment(podcastId, newComment.trim());
        setComments([comment, ...comments]);
        setNewComment("");
      } catch (err: any) {
        console.error("Failed to post comment:", err);
        setError(err.message || "Failed to post comment. Please try again.");
      }
    });
  };

  return (
    <div>
      <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-5 flex items-center gap-2">
        <BsChatFill /> Comments ({comments.length})
      </p>

      {/* Comment form */}
      <form onSubmit={handleSubmit} className="flex gap-3 mb-6">
        <div className="relative size-8 rounded-full overflow-hidden border border-app-border shrink-0 bg-app-raised flex items-center justify-center">
          <span className="text-xs text-app-subtle">You</span>
        </div>
        <div className="flex-1">
          <textarea
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            rows={2}
            placeholder="Add a comment..."
            disabled={isPending}
            className="w-full px-3 py-2 text-sm rounded-lg border border-app-border bg-app-surface text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-accent resize-none transition-colors disabled:opacity-50"
            maxLength={1000}
          />
          {error && (
            <p className="mt-1 text-xs text-red-500">{error}</p>
          )}
          <button 
            type="submit"
            disabled={isPending || !newComment.trim()}
            className="mt-2 px-4 py-1.5 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isPending ? "Posting..." : "Post"}
          </button>
        </div>
      </form>

      {/* Comment list */}
      <ul className="flex flex-col gap-4">
        {comments.map((comment) => (
          <li key={comment.id} className="flex gap-3">
            <div className="relative size-8 rounded-full overflow-hidden border border-app-border shrink-0">
              {comment.users?.avatar_url ? (
                <Image
                  src={comment.users.avatar_url}
                  alt={comment.users.username || "User"}
                  fill
                  unoptimized
                  className="object-cover"
                />
              ) : (
                <div className="size-full bg-app-raised flex items-center justify-center">
                  <span className="text-xs text-app-subtle">
                    {comment.users?.username?.[0]?.toUpperCase() || "?"}
                  </span>
                </div>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xs font-semibold text-app-text">
                  {comment.users?.username || "Anonymous"}
                </span>
                <span className="text-xs text-app-subtle">
                  {new Date(comment.created_at).toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "short",
                    day: "numeric",
                  })}
                </span>
              </div>
              <p className="text-sm text-app-muted leading-relaxed">
                {comment.body}
              </p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
