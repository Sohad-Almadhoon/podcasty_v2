"use client";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { BsPause, BsPlayFill, BsVolumeMute } from "react-icons/bs";
import { BiFastForward, BiRewind, BiSolidVolume } from "react-icons/bi";
import { X } from "lucide-react";
import { useAudio } from "@/app/providers/AudioProvider";
import { formatTime } from "@/app/lib/utils";
import { cn } from "@/app/lib/utils";
import { updatePlayCount } from "@/app/lib/api/podcasts";
import { Progress } from "../ui/progress";
import Image from "next/image";

const PLAYBACK_RATES = [0.75, 1, 1.25, 1.5, 1.75, 2] as const;

const PodcastPlayer = () => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [duration, setDuration] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [playbackRate, setPlaybackRate] = useState(1);
  const { audio, setAudio, seekRequest, clearSeekRequest } = useAudio();

  const handleClose = () => {
    audioRef.current?.pause();
    setAudio(undefined);
    setIsPlaying(false);
  };
  const togglePlayPause = () => {
    if (audioRef.current?.paused) {
      audioRef.current?.play();
      setIsPlaying(true);
    } else {
      audioRef.current?.pause();
      setIsPlaying(false);
    }
  };

  const toggleMute = () => {
    if (audioRef.current) {
      audioRef.current.muted = !isMuted;
      setIsMuted((prev) => !prev);
    }
  };

  const forward = () => {
    if (
      audioRef.current &&
      audioRef.current.currentTime &&
      audioRef.current.duration &&
      audioRef.current.currentTime + 5 < audioRef.current.duration
    ) {
      audioRef.current.currentTime += 5;
    }
  };

  const rewind = () => {
    if (audioRef.current && audioRef.current.currentTime - 5 > 0) {
      audioRef.current.currentTime -= 5;
    } else if (audioRef.current) {
      audioRef.current.currentTime = 0;
    }
  };

  const cyclePlaybackRate = () => {
    const idx = PLAYBACK_RATES.indexOf(playbackRate as typeof PLAYBACK_RATES[number]);
    const next = PLAYBACK_RATES[(idx + 1) % PLAYBACK_RATES.length];
    setPlaybackRate(next);
    if (audioRef.current) {
      audioRef.current.playbackRate = next;
    }
  };

  // Apply playbackRate whenever a new track loads (browsers reset it on src change)
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.playbackRate = playbackRate;
    }
  }, [audio?.audioUrl, playbackRate]);

  // Respond to seek requests from external components (e.g. chapter clicks)
  useEffect(() => {
    if (seekRequest == null || !audioRef.current) return;
    const target = Math.max(0, seekRequest);
    audioRef.current.currentTime = target;
    audioRef.current.play().catch(() => {});
    setIsPlaying(true);
    clearSeekRequest();
  }, [seekRequest, clearSeekRequest]);

  useEffect(() => {
    const updateCurrentTime = () => {
      if (audioRef.current) {
        setCurrentTime(audioRef.current.currentTime);
      }
    };

    const audioElement = audioRef.current;
    if (audioElement) {
      audioElement.addEventListener("timeupdate", updateCurrentTime);

      return () => {
        audioElement.removeEventListener("timeupdate", updateCurrentTime);
      };
    }
  }, []);

  useEffect(() => {
    const audioElement = audioRef.current;
    if (audio?.audioUrl) {
      if (audioElement) {
        audioElement.play().then(() => {
          setIsPlaying(true);
          // Track play count
          updatePlayCount(audio.podcastId).catch(err => {
            console.error('Failed to track play count:', err);
          });
        });
      }
    } else {
      audioElement?.pause();
      setIsPlaying(false);
    }
  }, [audio]);
  const handleLoadedMetadata = () => {
    if (audioRef.current) {
      setDuration(audioRef.current.duration);
    }
  };

  const handleAudioEnded = () => {
    setIsPlaying(false);
  };

  return (
    <div
      className={cn(
        "sticky bottom-0 left-0 flex flex-col bg-app-surface border-t border-app-border",
        {
          hidden: !audio?.audioUrl || audio?.audioUrl === "",
        }
      )}>
      <Progress
        value={(currentTime / duration) * 100}
        className="w-full"
        max={duration ? duration : 100}
      />
      <section className="flex h-[90px] w-full items-center justify-between px-4 max-md:justify-center max-md:gap-5 md:px-12">
        <audio
          ref={audioRef}
          src={audio?.audioUrl}
          className="hidden"
          onLoadedMetadata={handleLoadedMetadata}
          onEnded={handleAudioEnded}
        />
        <div className="flex items-center gap-4 max-md:hidden">
          <Link href={`/podcasts/${audio?.podcastId}`}>
            <div className="relative size-14 overflow-hidden shadow-lg rounded-lg border border-app-border">
              <Image
                src={
                  audio?.imageUrl && audio.imageUrl.trim() !== ""
                    ? audio.imageUrl
                    : "/images/1.jpeg"
                }
                alt="Podcast Cover"
                fill
                unoptimized
                className="object-cover"
              />
            </div>
          </Link>
          <div className="flex w-[160px] flex-col">
            <h2 className="text-sm truncate font-semibold text-app-text">
              {audio?.title}
            </h2>
            <p className="text-xs text-app-subtle">{audio?.author}</p>
          </div>
        </div>
        <div className="flex items-center cursor-pointer gap-3 md:gap-6">
          <div className="flex items-center gap-1.5 text-app-muted hover:text-app-text transition-colors">
            <BiRewind className="text-2xl cursor-pointer" onClick={rewind} />
            <span className="text-xs font-bold text-app-subtle">-5</span>
          </div>
          {isPlaying ? (
            <BsPause onClick={togglePlayPause} className="text-3xl text-app-text cursor-pointer hover:text-app-accent transition-colors" />
          ) : (
            <BsPlayFill onClick={togglePlayPause} className="text-3xl text-app-text cursor-pointer hover:text-app-accent transition-colors" />
          )}
          <div className="flex items-center gap-1.5 text-app-muted hover:text-app-text transition-colors">
            <span className="text-xs font-bold text-app-subtle">+5</span>
            <BiFastForward onClick={forward} className="text-2xl cursor-pointer" />
          </div>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm font-normal text-app-subtle max-md:hidden">
            {formatTime(duration)}
          </span>
          <button
            onClick={cyclePlaybackRate}
            className="px-2 py-1 rounded-md text-xs font-bold tabular-nums text-app-muted hover:text-app-text hover:bg-app-raised transition-colors min-w-[42px]"
            aria-label={`Playback speed ${playbackRate}x`}
            title="Playback speed"
          >
            {playbackRate}x
          </button>
          <div className="flex items-center gap-2">
            {isMuted ? (
              <BsVolumeMute onClick={toggleMute} className="text-2xl text-app-muted hover:text-app-text cursor-pointer transition-colors" />
            ) : (
              <BiSolidVolume onClick={toggleMute} className="text-2xl text-app-muted hover:text-app-text cursor-pointer transition-colors" />
            )}
          </div>
          <button
            onClick={handleClose}
            className="p-1.5 rounded-lg hover:bg-app-raised text-app-muted hover:text-app-text transition-colors"
            aria-label="Close player"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
      </section>
    </div>
  );
};

export default PodcastPlayer;
