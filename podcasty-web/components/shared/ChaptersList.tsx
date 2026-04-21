"use client";

import { useAudio } from "@/app/providers/AudioProvider";
import { Podcast } from "@/app/types";
import { formatTime } from "@/app/lib/utils";
import { Play } from "lucide-react";

interface ChaptersListProps {
  podcast: Pick<Podcast, "id" | "podcast_name" | "image_url" | "audio_url" | "users" | "chapters">;
}

const ChaptersList = ({ podcast }: ChaptersListProps) => {
  const { audio, setAudio, requestSeek } = useAudio();
  const chapters = podcast.chapters ?? [];

  if (chapters.length === 0) return null;

  const handleChapterClick = (start: number) => {
    const isCurrent = audio?.podcastId === podcast.id;

    if (!isCurrent) {
      setAudio({
        audioUrl: podcast.audio_url,
        podcastId: podcast.id,
        imageUrl: podcast.image_url,
        title: podcast.podcast_name,
        author: podcast.users?.username ?? "",
      });
      // Player will pick up the new audio; queue the seek so it fires after metadata loads.
      // A short timeout works because the audio src change triggers a load + autoplay.
      setTimeout(() => requestSeek(start), 250);
      return;
    }

    requestSeek(start);
  };

  return (
    <div>
      <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-3">
        Chapters
      </p>
      <ol className="rounded-lg border border-app-border divide-y divide-app-border bg-app-surface overflow-hidden">
        {chapters.map((chapter, idx) => (
          <li key={`${chapter.start}-${idx}`}>
            <button
              type="button"
              onClick={() => handleChapterClick(chapter.start)}
              className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-app-raised transition-colors group"
            >
              <span className="flex items-center justify-center size-7 rounded-full border border-app-border text-app-muted group-hover:text-app-accent group-hover:border-app-accent transition-colors">
                <Play className="w-3 h-3 fill-current" />
              </span>
              <span className="flex-1 text-sm text-app-text truncate">{chapter.title}</span>
              <span className="text-xs font-medium tabular-nums text-app-subtle">
                {formatTime(chapter.start)}
              </span>
            </button>
          </li>
        ))}
      </ol>
    </div>
  );
};

export default ChaptersList;
