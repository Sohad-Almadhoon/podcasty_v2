/**
 * Client-side API helpers (public, no authentication)
 * Use these in client components for public endpoints
 */
import { publicApiRequest } from './client';
import { normalizePodcast, normalizePodcasts } from './normalize';
import type { Podcast } from './podcasts';

// ==================== PODCASTS ====================

export type PodcastSort = 'newest' | 'oldest' | 'most_played' | 'most_liked';

export async function fetchPodcasts(params?: {
  search?: string;
  category?: string;
  sort?: PodcastSort;
  min_duration?: number;
  max_duration?: number;
  date_from?: string;
  date_to?: string;
  limit?: number;
  offset?: number;
}): Promise<Podcast[]> {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append('search', params.search);
  if (params?.category) queryParams.append('category', params.category);
  if (params?.sort) queryParams.append('sort', params.sort);
  if (params?.min_duration != null) queryParams.append('min_duration', params.min_duration.toString());
  if (params?.max_duration != null) queryParams.append('max_duration', params.max_duration.toString());
  if (params?.date_from) queryParams.append('date_from', params.date_from);
  if (params?.date_to) queryParams.append('date_to', params.date_to);
  if (params?.limit) queryParams.append('limit', params.limit.toString());
  if (params?.offset) queryParams.append('offset', params.offset.toString());

  const query = queryParams.toString() ? `?${queryParams.toString()}` : '';
  const data = await publicApiRequest<Podcast[]>(`/api/podcasts${query}`);
  return normalizePodcasts(data);
}

export async function fetchPodcastById(id: string): Promise<Podcast> {
  const data = await publicApiRequest<Podcast>(`/api/podcasts/${id}`);
  return normalizePodcast(data);
}

export async function fetchTrendingPodcasts(limit: number = 10): Promise<Podcast[]> {
  const data = await publicApiRequest<Podcast[]>(`/api/podcasts/trending?limit=${limit}`);
  return normalizePodcasts(data);
}
