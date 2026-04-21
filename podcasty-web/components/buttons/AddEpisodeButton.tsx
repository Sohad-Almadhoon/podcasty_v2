"use client";
import { useState } from "react";
import { Plus } from "lucide-react";
import AddEpisodeToSeriesModal from "@/components/modals/AddEpisodeToSeriesModal";

interface AddEpisodeButtonProps {
  seriesId: string;
  userId: string;
}

const AddEpisodeButton = ({ seriesId, userId }: AddEpisodeButtonProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsModalOpen(true)}
        className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity">
        <Plus className="w-4 h-4" />
        Add Episode
      </button>

      <AddEpisodeToSeriesModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        seriesId={seriesId}
        userId={userId}
      />
    </>
  );
};

export default AddEpisodeButton;
