"use server";
import { apiRequest } from './client';
import type { Podcast } from './podcasts';

// ==================== TYPES ====================

export interface Playlist {
  id: string;
  name: string;
  description?: string;
  user_id: string;
  created_at: string;
  podcasts?: Podcast[];
}

// ==================== API FUNCTIONS ====================

export async function fetchPlaylists(): Promise<Playlist[]> {
  return apiRequest<Playlist[]>('/api/playlists');
}

export async function fetchPlaylist(id: string): Promise<Playlist> {
  return apiRequest<Playlist>(`/api/playlists/${id}`);
}

export async function fetchPlaylistItems(playlistId: string): Promise<any[]> {
  return apiRequest<any[]>(`/api/playlists/items?playlist_id=${playlistId}`);
}

export async function createPlaylist(data: {
  name: string;
  description?: string;
}): Promise<Playlist> {
  return apiRequest<Playlist>('/api/playlists/create', {
    method: 'POST',
    data,
  });
}

export async function addToPlaylist(playlistId: string, podcastId: string): Promise<{ message: string }> {
  return apiRequest('/api/playlists/items/add', {
    method: 'POST',
    data: { playlist_id: playlistId, podcast_id: podcastId },
  });
}

export async function removeFromPlaylist(playlistId: string, podcastId: string): Promise<{ message: string }> {
  return apiRequest(`/api/playlists/items/remove?playlist_id=${playlistId}&podcast_id=${podcastId}`, {
    method: 'DELETE',
  });
}
