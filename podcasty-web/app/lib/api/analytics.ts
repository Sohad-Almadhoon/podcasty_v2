"use server";
import { apiRequest } from './client';

export interface PodcastAnalytics {
  podcast_id: string;
  total_plays: number;
  total_likes: number;
  total_comments: number;
  unique_listeners: number;
  plays_over_time: { date: string; count: number }[];
  last_updated: string;
}

export async function fetchPodcastAnalytics(podcastId: string): Promise<PodcastAnalytics> {
  return apiRequest<PodcastAnalytics>(`/api/podcasts/analytics?podcast_id=${podcastId}`);
}
