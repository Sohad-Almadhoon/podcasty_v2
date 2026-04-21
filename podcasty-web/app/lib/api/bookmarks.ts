"use server";
import { apiRequest } from './client';
import { normalizePodcast } from './normalize';
import type { Podcast } from './podcasts';

// A bookmark row as returned by the API: the bookmark metadata plus the
// embedded podcast.
export interface BookmarkRow {
  id: string;
  user_id: string;
  podcast_id: string;
  created_at: string;
  podcasts: Podcast;
}

// ==================== API FUNCTIONS ====================

export async function fetchBookmarks(): Promise<BookmarkRow[]> {
  const data = await apiRequest<BookmarkRow[]>('/api/bookmarks');
  // Normalize the embedded podcast on each row so consumers don't have to
  // worry about the users-as-array shape.
  return data.map((row) => ({
    ...row,
    podcasts: row.podcasts ? normalizePodcast(row.podcasts) : row.podcasts,
  }));
}

export async function addBookmark(podcastId: string): Promise<{ message: string }> {
  return apiRequest('/api/bookmarks/add', {
    method: 'POST',
    data: { podcast_id: podcastId },
  });
}

export async function removeBookmark(podcastId: string): Promise<{ message: string }> {
  return apiRequest(`/api/bookmarks/remove?podcast_id=${podcastId}`, {
    method: 'DELETE',
  });
}

export async function checkBookmarkStatus(podcastId: string): Promise<{ bookmarked: boolean }> {
  return apiRequest<{ bookmarked: boolean }>(`/api/bookmarks/status?podcast_id=${podcastId}`);
}
