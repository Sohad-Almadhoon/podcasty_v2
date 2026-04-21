"use client";
import { useState } from "react";
import { BsCollectionPlayFill } from "react-icons/bs";
import AddToPlaylistModal from "@/components/modals/AddToPlaylistModal";

interface AddToPlaylistButtonProps {
  podcastId: string;
}

const AddToPlaylistButton = ({ podcastId }: AddToPlaylistButtonProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsModalOpen(true)}
        title="Add to playlist"
        className="flex items-center justify-center gap-1.5 h-9 px-3 rounded-lg border border-app-border bg-app-surface text-app-muted hover:text-app-text hover:border-app-muted transition-colors">
        <BsCollectionPlayFill className="text-sm" />
        <span className="text-xs font-medium hidden sm:inline">Playlist</span>
      </button>
      
      <AddToPlaylistModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        podcastId={podcastId}
      />
    </>
  );
};

export default AddToPlaylistButton;
