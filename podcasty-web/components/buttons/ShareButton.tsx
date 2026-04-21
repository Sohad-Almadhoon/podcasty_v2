"use client";

import { useState } from "react";
import { Check, Copy, Facebook, Link2, Share2, Twitter } from "lucide-react";
import { toast } from "sonner";

interface ShareButtonProps {
  podcastId: string;
  title: string;
}

const ShareButton = ({ podcastId, title }: ShareButtonProps) => {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const url =
    typeof window !== "undefined"
      ? `${window.location.origin}/podcasts/${podcastId}`
      : `/podcasts/${podcastId}`;

  const shareText = `Listen to "${title}" on Podcasty`;

  const twitterUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(
    shareText
  )}&url=${encodeURIComponent(url)}`;

  const facebookUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      toast.success("Link copied to clipboard");
      setTimeout(() => setCopied(false), 1500);
    } catch {
      toast.error("Could not copy link");
    }
  };

  const handleNativeShare = async () => {
    if (typeof navigator !== "undefined" && "share" in navigator) {
      try {
        await navigator.share({ title, text: shareText, url });
        return;
      } catch {
        // User cancelled or unsupported — fall through to popover
      }
    }
    setOpen((v) => !v);
  };

  return (
    <div className="relative">
      <button
        type="button"
        onClick={handleNativeShare}
        title="Share"
        className="flex items-center justify-center gap-1.5 h-9 px-3 rounded-lg border border-app-border bg-app-surface text-app-muted hover:text-app-text hover:border-app-muted transition-colors"
        aria-label="Share podcast"
      >
        <Share2 className="w-4 h-4" />
        <span className="text-xs font-medium hidden sm:inline">Share</span>
      </button>

      {open && (
        <div className="absolute z-20 mt-2 right-0 w-56 rounded-lg border border-app-border bg-app-surface shadow-app-md p-2">
          <a
            href={twitterUrl}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => setOpen(false)}
            className="flex items-center gap-2 px-3 py-2 rounded-md text-sm text-app-text hover:bg-app-raised transition-colors"
          >
            <Twitter className="w-4 h-4" /> Share on Twitter
          </a>
          <a
            href={facebookUrl}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => setOpen(false)}
            className="flex items-center gap-2 px-3 py-2 rounded-md text-sm text-app-text hover:bg-app-raised transition-colors"
          >
            <Facebook className="w-4 h-4" /> Share on Facebook
          </a>
          <button
            type="button"
            onClick={handleCopy}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-md text-sm text-app-text hover:bg-app-raised transition-colors"
          >
            {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
            {copied ? "Copied!" : "Copy link"}
          </button>
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-md text-xs text-app-subtle hover:bg-app-raised transition-colors"
          >
            <Link2 className="w-3.5 h-3.5" /> {url.length > 32 ? url.slice(0, 32) + "…" : url}
          </button>
        </div>
      )}
    </div>
  );
};

export default ShareButton;
