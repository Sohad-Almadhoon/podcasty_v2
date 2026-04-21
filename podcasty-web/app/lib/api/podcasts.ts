"use server";
import { apiRequest } from './client';
import type { Chapter, Podcast } from '@/app/types';

// Re-export the canonical types so existing imports from './podcasts' keep
// working. This file used to define its own divergent `Podcast` type — those
// definitions have been removed in favor of the single source of truth in
// `@/app/types`.
export type { Chapter, Podcast };

// ==================== API FUNCTIONS ====================

export async function createPodcast(data: {
  podcast_name: string;
  description: string;
  image_url: string;
  audio_url: string;
  ai_voice?: string;
  category: string;
  chapters?: Chapter[];
}): Promise<Podcast> {
  return apiRequest<Podcast>('/api/podcasts/create', {
    method: 'POST',
    data,
  });
}

export async function deletePodcast(podcastId: string): Promise<{ message: string }> {
  return apiRequest(`/api/podcasts/delete?id=${podcastId}`, {
    method: 'DELETE',
  });
}

export async function updatePlayCount(podcastId: string): Promise<{ message: string }> {
  return apiRequest('/api/podcasts/play', {
    method: 'POST',
    data: { podcast_id: podcastId },
  });
}
