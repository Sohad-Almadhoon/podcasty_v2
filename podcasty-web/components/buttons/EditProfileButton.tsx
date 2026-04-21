"use client";
import { useState } from "react";
import { Settings } from "lucide-react";
import EditProfileModal from "@/components/modals/EditProfileModal";

interface EditProfileButtonProps {
  userId: string;
  username: string;
  avatarUrl: string;
}

const EditProfileButton = ({ userId, username, avatarUrl }: EditProfileButtonProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsModalOpen(true)}
        className="flex items-center gap-0.5 px-3 py-1.5 rounded-lg border border-app-border bg-app-raised text-app-text text-xs font-semibold hover:border-app-muted transition-colors whitespace-nowrap">
        <Settings className="w-3 h-3" />
        Edit Profile
      </button>
      
      <EditProfileModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        userId={userId}
        currentUsername={username}
        currentAvatarUrl={avatarUrl}
      />
    </>
  );
};

export default EditProfileButton;
