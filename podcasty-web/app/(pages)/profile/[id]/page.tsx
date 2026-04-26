import Link from "next/link";
import { fetchUser, fetchUserPodcasts } from "@/app/lib/api-client";
import PodcastCard from "@/components/shared/PodcastCard";
import DeleteButton from "@/components/buttons/DeleteButton";
import FollowButton from "@/components/buttons/FollowButton";
import EditProfileButton from "@/components/buttons/EditProfileButton";
import { getUser } from "@/app/lib/supabase";
import Image from "next/image";
import LoaderSpinner from "../../loading";
import { paramsType } from "@/app/types";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import UserBadges from "@/components/shared/UserBadges";
import { Mic2 } from "lucide-react";
import { BsHeadphones, BsHeartFill } from "react-icons/bs";
import BackButton from "@/components/buttons/BackButton";

const Profile = async (props: { params: paramsType }) => {
  const { id } = await props.params;
  
  let user: any = null;
  let podcasts: any[] = [];
  
  try {
    [user, podcasts] = await Promise.all([
      fetchUser(id).catch((err) => {
        console.error('Error fetching user:', err);
        return null;
      }),
      fetchUserPodcasts(id).catch((err) => {
        console.error('Error fetching user podcasts:', err);
        return [];
      }),
    ]);
  } catch (error) {
    console.error('Error fetching profile data:', error);
  }

  // Get current user for ownership check
  const userInfo = await getUser();
  const isOwner = userInfo?.id === id;

  // If user not found, show error state
  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Mic2 className="w-12 h-12 text-app-subtle mx-auto mb-4" />
          <h2 className="text-lg font-semibold text-app-text mb-2">User not found</h2>
          <p className="text-sm text-app-subtle">This profile doesn't exist or couldn't be loaded.</p>
          <Link
            href="/"
            className="inline-block mt-4 px-4 py-2 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity">
            Go Home
          </Link>
        </div>
      </div>
    );
  }

  // Calculate stats from podcasts
  const totalPlays = podcasts.reduce((s, p) => s + (p.play_count || 0), 0);
  const totalLikes = podcasts.reduce((s, p) => s + (p.likes?.[0]?.count || 0), 0);

  return (
    <div className="min-h-screen">
      {/* Profile header */}
      <div className="border-b border-app-border px-6 py-8">
        <div className="mb-4">
          <BackButton />
        </div>
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-center gap-5">
            <div className="relative size-16 rounded-full overflow-hidden border border-app-border shrink-0">
              <Image
                src={user.avatar_url || "/images/1.jpeg"}
                alt="profile img"
                unoptimized
                fill
                className="object-cover"
              />
            </div>
            <div>
              <h1 className="text-xl font-bold text-app-text">{user.username}</h1>
              <p className="text-sm text-app-muted mt-0.5">{user.email}</p>
              <div className="flex items-center gap-2 mt-2 flex-wrap">
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs">
                  <Mic2 className="w-3 h-3 mr-1" /> {podcasts.length} podcast{podcasts.length !== 1 ? "s" : ""}
                </Badge>
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                  <BsHeadphones className="text-[10px]" /> {totalPlays.toLocaleString()} plays
                </Badge>
                <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1">
                  <BsHeartFill className="text-[10px]" /> {totalLikes.toLocaleString()} likes
                </Badge>
                {isOwner && (
                  <Badge variant="outline" className="border-app-accent/30 text-app-accent text-xs">You</Badge>
                )}
              </div>
              <UserBadges userId={id} />
            </div>
          </div>
          {isOwner ? (
            <EditProfileButton 
              userId={id} 
              username={user.username} 
              avatarUrl={user.avatar_url || "/images/1.jpeg"} 
            />
          ) : (
            <FollowButton userId={id} currentUserId={userInfo?.id} />
          )}
        </div>
      </div>

      {/* Podcasts */}
      <div className="px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest">
            {isOwner ? "Your Podcasts" : `Podcasts by ${user.username}`}
          </p>
          {isOwner && (
            <Link
              href="/podcasts/create"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity">
              <Mic2 className="w-3.5 h-3.5" /> Create new
            </Link>
          )}
        </div>

        <Separator className="bg-app-border mb-6" />

        {podcasts.length > 0 ? (
          <ul className="flex gap-4 overflow-x-auto snap-x snap-mandatory -mx-6 px-6 pb-4 scrollbar-thin">
            {podcasts.map((podcast) => (
              <li
                key={podcast.id}
                className="relative group shrink-0 w-[260px] sm:w-[280px] snap-start">
                <Link href={`/podcasts/${podcast.id}`}>
                  <PodcastCard podcast={podcast} />
                </Link>
                {podcast.user_id === userInfo?.id && (
                  <DeleteButton podcastId={podcast.id} />
                )}
              </li>
            ))}
          </ul>
        ) : (
          <div className="rounded-xl border border-dashed border-app-border p-10 text-center">
            <Mic2 className="w-8 h-8 text-app-subtle mx-auto mb-3" />
            <p className="text-sm font-medium text-app-text mb-1">No podcasts yet</p>
            <p className="text-xs text-app-subtle mb-4">Create your first podcast to see it here.</p>
            {isOwner && (
              <Link
                href="/podcasts/create"
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity">
                <Mic2 className="w-3.5 h-3.5" /> Create Podcast
              </Link>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Profile;
