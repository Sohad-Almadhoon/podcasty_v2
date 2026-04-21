import { Podcast } from "@/app/types";
import Image from "next/image";
import React, { FC } from "react";
import { BsHeartFill, BsHeadphones } from "react-icons/bs";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface PodcastCardProps {
  podcast: Podcast;
}

const PodcastCard: FC<PodcastCardProps> = ({ podcast }) => {
  return (
    <Card className="group bg-app-surface border-app-border hover:border-app-muted transition-all duration-300 overflow-hidden rounded-xl shadow-app hover:shadow-app-md">
      <div className="relative h-48 overflow-hidden">
        <Image
          src={
            podcast.image_url && podcast.image_url.trim() !== ""
              ? podcast.image_url
              : "/images/1.svg"
          }
          alt={podcast.podcast_name || "Podcast cover"}
          fill
          unoptimized
          className="object-cover transition-transform duration-500 group-hover:scale-105"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />
        {podcast.category && (
          <div className="absolute top-2 right-2">
            <Badge className="bg-app-accent/90 text-white border-0 text-xs backdrop-blur-sm">
              {podcast.category}
            </Badge>
          </div>
        )}
      </div>
      <CardContent className="p-4">
        <p className="font-semibold text-app-text text-sm leading-tight mb-1.5 truncate">
          {podcast.podcast_name}
        </p>
        <p className="text-xs text-app-subtle leading-relaxed line-clamp-2 mb-3">
          {podcast.description}
        </p>
        <div className="flex items-center justify-between">
          <span className="text-xs text-app-subtle">
            {podcast.created_at
              ? new Date(podcast.created_at).toLocaleDateString()
              : podcast.users?.username}
          </span>
          <div className="flex gap-2">
            <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
              <BsHeadphones /> {podcast.play_count || 0}
            </Badge>
            <Badge variant="outline" className="border-app-border text-app-subtle text-xs gap-1 py-0">
              <BsHeartFill className="text-[10px]" /> {podcast.likes?.[0]?.count || 0}
            </Badge>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default PodcastCard;
