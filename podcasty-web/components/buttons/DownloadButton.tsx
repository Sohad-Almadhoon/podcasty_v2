"use client";

import { Download } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

interface DownloadButtonProps {
  podcastId: string;
  podcastName: string;
}

const DownloadButton = ({ podcastId, podcastName }: DownloadButtonProps) => {
  const [downloading, setDownloading] = useState(false);

  const handleDownload = async () => {
    setDownloading(true);
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";
      const url = `${apiUrl}/api/podcasts/download?id=${podcastId}`;

      const res = await fetch(url);
      if (!res.ok) throw new Error("Download failed");

      const blob = await res.blob();
      const blobUrl = URL.createObjectURL(blob);

      const a = document.createElement("a");
      a.href = blobUrl;
      a.download = `${podcastName || "podcast"}.mp3`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(blobUrl);

      toast.success("Download started");
    } catch {
      toast.error("Download failed", {
        description: "Could not download this podcast. Try again later.",
      });
    } finally {
      setDownloading(false);
    }
  };

  return (
    <button
      type="button"
      onClick={handleDownload}
      disabled={downloading}
      title={downloading ? "Downloading..." : "Download"}
      className="flex items-center justify-center gap-1.5 h-9 px-3 rounded-lg border border-app-border bg-app-surface text-app-muted hover:text-app-text hover:border-app-muted transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      aria-label="Download podcast"
    >
      <Download className={`w-4 h-4 ${downloading ? "animate-bounce" : ""}`} />
      <span className="text-xs font-medium hidden sm:inline">{downloading ? "Downloading..." : "Download"}</span>
    </button>
  );
};

export default DownloadButton;
