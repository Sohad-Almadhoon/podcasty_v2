"use server";
import { apiRequest } from './client';
import { publicApiRequest } from './client';

export interface Series {
  id: string;
  user_id: string;
  title: string;
  description?: string;
  cover_url?: string;
  created_at: string;
  users?: { username: string; avatar_url: string };
  series_episodes?: { count: number }[] | SeriesEpisode[];
}

export interface SeriesEpisode {
  id: string;
  series_id: string;
  podcast_id: string;
  season_number: number;
  episode_number: number;
  podcasts?: any;
}

export async function fetchAllSeries(userId?: string): Promise<Series[]> {
  const params = userId ? `?user_id=${userId}` : '';
  return publicApiRequest<Series[]>(`/api/series${params}`);
}

export async function fetchSeries(id: string): Promise<Series> {
  return publicApiRequest<Series>(`/api/series/${id}`);
}

export async function createSeries(data: {
  title: string;
  description?: string;
  cover_url?: string;
}): Promise<Series> {
  return apiRequest<Series>('/api/series/create', {
    method: 'POST',
    data,
  });
}

export async function deleteSeries(id: string): Promise<{ message: string }> {
  return apiRequest(`/api/series/delete?id=${id}`, {
    method: 'DELETE',
  });
}

export async function addEpisodeToSeries(data: {
  series_id: string;
  podcast_id: string;
  season_number: number;
  episode_number: number;
}): Promise<any> {
  return apiRequest('/api/series/episodes/add', {
    method: 'POST',
    data,
  });
}

export async function removeEpisodeFromSeries(
  seriesId: string,
  podcastId: string
): Promise<{ message: string }> {
  return apiRequest(`/api/series/episodes/remove?series_id=${seriesId}&podcast_id=${podcastId}`, {
    method: 'DELETE',
  });
}
