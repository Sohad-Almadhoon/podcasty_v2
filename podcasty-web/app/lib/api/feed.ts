"use server";
import { apiRequest } from './client';
import { normalizePodcasts } from './normalize';
import type { Podcast } from './podcasts';

// ==================== API FUNCTIONS ====================

export async function fetchFeed(params?: {
  limit?: number;
  offset?: number;
}): Promise<Podcast[]> {
  const queryParams = new URLSearchParams();
  if (params?.limit) queryParams.append('limit', params.limit.toString());
  if (params?.offset) queryParams.append('offset', params.offset.toString());

  const query = queryParams.toString() ? `?${queryParams.toString()}` : '';
  const data = await apiRequest<Podcast[]>(`/api/feed${query}`);
  return normalizePodcasts(data);
}
