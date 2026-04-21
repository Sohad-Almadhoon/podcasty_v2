"use client";
import { usePathname } from "next/navigation";
import React, { createContext, useState, useContext, useEffect, useCallback } from "react";
import { AudioContextType, AudioProps } from "../types";

const AudioContext = createContext<AudioContextType | undefined>(undefined);

const AudioProvider = ({ children }: { children: React.ReactNode }) => {
  const [audio, setAudio] = useState<AudioProps | undefined>();
  const [seekRequest, setSeekRequest] = useState<number | null>(null);
  const pathname = usePathname();

  useEffect(() => {
    if (pathname === "/podcasts/create" || pathname === "/login") setAudio(undefined);
  }, [pathname]);

  const requestSeek = useCallback((seconds: number) => {
    setSeekRequest(seconds);
  }, []);

  const clearSeekRequest = useCallback(() => {
    setSeekRequest(null);
  }, []);

  return (
    <AudioContext.Provider value={{ audio, setAudio, seekRequest, requestSeek, clearSeekRequest }}>
      {children}
    </AudioContext.Provider>
  );
};

export const useAudio = () => {
  const context = useContext(AudioContext);

  if (context === undefined) {
    throw new Error("useAudio must be used within a AudioProvider");
  }

  return context;
};

export default AudioProvider;
