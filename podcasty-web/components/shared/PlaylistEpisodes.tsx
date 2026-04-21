"use client";
import { Podcast } from "@/app/types";
import { useAudio } from "@/app/providers/AudioProvider";
import PodcastCard from "./PodcastCard";

interface PlaylistEpisodesProps {
  podcasts: Podcast[];
}

const PlaylistEpisodes = ({ podcasts }: PlaylistEpisodesProps) => {
  const { setAudio } = useAudio();

  const handlePlay = (podcast: Podcast) => {
    setAudio({
      audioUrl: podcast.audio_url,
      podcastId: podcast.id,
      imageUrl: podcast.image_url || "",
      title: podcast.podcast_name,
      author: podcast.users?.username || "Unknown",
    });
  };

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {podcasts.map((podcast) => (
        <button
          key={podcast.id}
          type="button"
          onClick={() => handlePlay(podcast)}
          className="text-left cursor-pointer focus:outline-none focus:ring-2 focus:ring-app-accent rounded-xl"
        >
          <PodcastCard podcast={podcast} />
        </button>
      ))}
    </div>
  );
};

export default PlaylistEpisodes;
