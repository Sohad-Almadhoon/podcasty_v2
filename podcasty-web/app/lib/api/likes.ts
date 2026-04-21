"use server";
import { apiRequest } from './client';

// ==================== API FUNCTIONS ====================

export async function likePodcast(podcastId: string): Promise<{ message: string; liked: boolean; count: number }> {
  return apiRequest('/api/podcasts/like', {
    method: 'POST',
    data: { podcast_id: podcastId },
  });
}

export async function unlikePodcast(podcastId: string): Promise<{ message: string; liked: boolean; count: number }> {
  return apiRequest('/api/podcasts/unlike', {
    method: 'POST',
    data: { podcast_id: podcastId },
  });
}
