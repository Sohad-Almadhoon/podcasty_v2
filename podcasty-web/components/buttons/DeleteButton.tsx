"use client";
import { useState } from "react";
import { AiFillDelete } from "react-icons/ai";
import { deletePodcastAction } from "@/app/lib/actions";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface DeleteButtonProps {
  podcastId: string;
}

const DeleteButton = ({ podcastId }: DeleteButtonProps) => {
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const router = useRouter();

  const handleDelete = async () => {
    setLoading(true);
    try {
      const result = await deletePodcastAction(podcastId);

      if (result.success) {
        toast.success("Podcast deleted successfully");
        setOpen(false);
        router.refresh();
      } else {
        toast.error(result.error || "Failed to delete podcast");
      }
    } catch (error) {
      console.error("Error deleting podcast:", error);
      toast.error("Failed to delete podcast");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AlertDialog open={open} onOpenChange={setOpen}>
      <AlertDialogTrigger asChild>
        <button
          type="button"
          onClick={(e) => e.stopPropagation()}
          disabled={loading}
          className="absolute top-2 right-2 z-10 flex items-center justify-center w-7 h-7 rounded-lg bg-app-surface border border-app-border text-app-muted hover:border-red-500/40 hover:text-red-400 hover:bg-red-500/10 transition-colors shadow-app opacity-0 group-hover:opacity-100 disabled:opacity-50"
        >
          <AiFillDelete className="text-xs" />
        </button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
          <AlertDialogDescription>
            This action cannot be undone. This will permanently delete this
            podcast and remove its data from our servers.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={loading}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={(e) => {
              e.preventDefault();
              handleDelete();
            }}
            disabled={loading}
            className="bg-red-500 hover:bg-red-600 text-white"
          >
            {loading ? "Deleting..." : "Delete Podcast"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default DeleteButton;
