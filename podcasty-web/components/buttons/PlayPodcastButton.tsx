"use client";
import { useAudio } from "@/app/providers/AudioProvider";
import { Podcast } from "@/app/types";
import React from "react";
import { Play } from "lucide-react";

const PlayPodcastButton = ({ podcast }: { podcast: Podcast }) => {
  const { setAudio } = useAudio();

  const handlePlay = () => {
    setAudio({
      audioUrl: podcast.audio_url,
      podcastId: podcast.id,
      imageUrl: podcast.image_url!,
      title: podcast.podcast_name,
      author: podcast.users?.username ?? "",
    });
  };

  return (
    <button
      onClick={handlePlay}
      className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity shadow-app">
      <Play className="w-4 h-4 fill-white" /> Play Podcast
    </button>
  );
};

export default PlayPodcastButton;
