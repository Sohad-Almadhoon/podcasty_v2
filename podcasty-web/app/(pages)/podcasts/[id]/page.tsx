import Link from "next/link";
import type { Metadata } from "next";
import LikeButton from "@/components/buttons/LikeButton";
import PodcastCard from "@/components/shared/PodcastCard";
import PlayPodcastButton from "@/components/buttons/PlayPodcastButton";
import DeletePodcastButton from "@/components/buttons/DeletePodcastButton";
import BookmarkButton from "@/components/buttons/BookmarkButton";
import AddToPlaylistButton from "@/components/buttons/AddToPlaylistButton";
import ShareButton from "@/components/buttons/ShareButton";
import DownloadButton from "@/components/buttons/DownloadButton";
import CommentsSection from "@/components/shared/CommentsSection";
import ChaptersList from "@/components/shared/ChaptersList";
import { fetchPodcastById } from "@/app/lib/api-client";
import { fetchUserPodcasts } from "@/app/lib/api/users";
import { fetchComments } from "@/app/lib/api/comments";
import { getUser } from "@/app/lib/supabase";
import { notFound } from "next/navigation";
import { paramsType } from "@/app/types";
import Image from "next/image";
import LoaderSpinner from "../../loading";
import { BsHeadphones } from "react-icons/bs";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { CalendarDays, Mic2 } from "lucide-react";
import BackButton from "@/components/buttons/BackButton";


export async function generateMetadata(props: { params: paramsType }): Promise<Metadata> {
  try {
    const { id } = await props.params;
    if (!id) return {};
    const podcast = await fetchPodcastById(id);
    if (!podcast) return {};

    const author = podcast.users?.username;
    const title = podcast.podcast_name || "Podcast";
    const description = podcast.description?.slice(0, 200) || `Listen to ${title} on Podcasty`;
    const image = podcast.image_url?.trim() || "/images/1.jpeg";

    return {
      title: `${title} — Podcasty`,
      description,
      openGraph: {
        title,
        description,
        type: "music.song",
        images: [{ url: image, alt: title }],
        ...(author ? { authors: [author] } : {}),
      },
      twitter: {
        card: "summary_large_image",
        title,
        description,
        images: [image],
      },
    };
  } catch {
    return {};
  }
}

const PodcastDetails = async (props: { params: paramsType }) => {
  const { id } = await props.params;
  if (!id) return notFound();

  try {
    // Fetch podcast details from Go backend
    const [podcast, comments, currentUser] = await Promise.all([
      fetchPodcastById(id),
      fetchComments(id).catch(() => []), // Comments fallback
      getUser().catch(() => null), // Current user for ownership check
    ]);

    if (!podcast) return <LoaderSpinner />;

    // Fetch other podcasts by the same author
    const relatedPodcasts = await fetchUserPodcasts(podcast.user_id)
      .then((items) => items.filter((p) => p.id !== podcast.id))
      .catch(() => []);

    const isOwner = currentUser?.id === podcast.user_id;

    return (
      <div className="min-h-screen pb-16">
        {/* Header banner */}
        <div className="border-b border-app-border px-4 sm:px-6 py-6 sm:py-8">
          <div className="mb-4">
            <BackButton />
          </div>
          <div className="flex flex-col lg:flex-row gap-6">
            {/* Cover */}
            <div className="relative w-40 h-40 shrink-0 rounded-xl overflow-hidden border border-app-border shadow-app-md">
              <Image
                src={podcast.image_url?.trim() || "/images/1.jpeg"}
                alt={podcast.podcast_name || "Podcast cover"}
                fill
                unoptimized
                className="object-cover"
              />
            </div>

            {/* Meta */}
            <div className="flex flex-col justify-between gap-3">
              <div>
                <Badge variant="outline" className="border-app-border text-app-muted mb-2 text-xs">
                  Podcast
                </Badge>
                <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-app-text leading-tight break-words">
                  {podcast.podcast_name || "Untitled Podcast"}
                </h1>
                <Link
                  href={`/profile/${podcast.user_id}`}
                  className="flex items-center gap-2 mt-3 group w-fit">
                  <div className="relative size-7 rounded-full overflow-hidden border border-app-border">
                    <Image
                      src={podcast.users.avatar_url?.trim() || "/images/1.jpeg"}
                      alt="Author"
                      fill
                      unoptimized
                    />
                  </div>
                  <span className="text-sm text-app-muted group-hover:text-app-text transition-colors">
                    {podcast.users?.username}
                  </span>
                </Link>
              </div>

              {/* Primary actions */}
              <div className="flex flex-wrap items-center gap-2 sm:gap-3">
                <PlayPodcastButton podcast={podcast} />
                {podcast.users && <LikeButton podcastId={id} userId={podcast.user_id} />}
                <span className="text-xs text-app-subtle flex items-center gap-1.5 px-3 py-2 rounded-lg border border-app-border bg-app-surface">
                  <BsHeadphones className="text-app-muted" /> {(podcast.play_count || 0).toLocaleString()} plays
                </span>
              </div>

              {/* Secondary actions bar */}
              <div className="flex flex-wrap items-center gap-1.5 mt-3 p-1.5 rounded-xl border border-app-border bg-app-surface/50 w-fit max-w-full">
                <BookmarkButton podcastId={id} />
                <AddToPlaylistButton podcastId={id} />
                <ShareButton podcastId={id} title={podcast.podcast_name || "Untitled Podcast"} />
                <DownloadButton podcastId={id} podcastName={podcast.podcast_name || "podcast"} />

                {isOwner && (
                  <>
                    <div className="h-5 w-px bg-app-border mx-0.5" />
                    <DeletePodcastButton podcastId={id} />
                  </>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Body */}
        <div className="px-4 sm:px-6 py-6 sm:py-8 space-y-6 sm:space-y-8">
          {/* Info pills */}
          <div className="flex flex-wrap gap-3">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-app-border bg-app-surface text-xs text-app-muted">
              <Mic2 className="w-3.5 h-3.5" /> Voice: <span className="text-app-text font-medium ml-0.5 capitalize">{podcast.ai_voice || "Unknown"}</span>
            </div>
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-app-border bg-app-surface text-xs text-app-muted">
              <CalendarDays className="w-3.5 h-3.5" />
              {podcast.created_at
                ? new Intl.DateTimeFormat("en-US", { dateStyle: "long" }).format(new Date(podcast.created_at))
                : "Unknown date"}
            </div>
            {podcast.category && (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-app-border bg-app-surface text-xs text-app-muted capitalize">
                {podcast.category}
              </div>
            )}
          </div>

          {/* Description */}
          <div>
            <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-3">About this episode</p>
            <p className="text-sm text-app-muted leading-relaxed max-w-2xl">
              {podcast.description || "No description available."}
            </p>
          </div>

          <Separator className="bg-app-border" />

          {/* Chapters */}
          <ChaptersList podcast={podcast} />

          {/* Transcript removed - implement when backend supports it */}

          {/* Comments */}
          <CommentsSection podcastId={id} initialComments={comments} />

          <Separator className="bg-app-border" />

          {/* More by this user */}
          <div>
            <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-5">More by {podcast.users?.username}</p>
            {relatedPodcasts && relatedPodcasts.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {relatedPodcasts.slice(0, 3).map((p) => (
                  <Link href={`/podcasts/${p.id}`} key={p.id}>
                    <PodcastCard podcast={p} />
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-app-subtle">No other podcasts from this creator yet.</p>
            )}
          </div>
        </div>
      </div>
    );
  } catch (error) {
    console.error("Error fetching podcast details or other podcasts:", error);
    return notFound();
  }
};
export default PodcastDetails;