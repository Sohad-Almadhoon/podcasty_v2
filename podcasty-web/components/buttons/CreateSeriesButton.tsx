"use client";
import { useState } from "react";
import { Plus } from "lucide-react";
import CreateSeriesModal from "@/components/modals/CreateSeriesModal";

const CreateSeriesButton = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsModalOpen(true)}
        className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity">
        <Plus className="w-4 h-4" />
        Create Series
      </button>

      <CreateSeriesModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
      />
    </>
  );
};

export default CreateSeriesButton;
