"use server";
/**
 * Server actions for authenticated API calls
 * These functions handle authenticated requests from client components
 */

import { 
  createPodcast as apiCreatePodcast, 
  deletePodcast as apiDeletePodcast,
} from './api/podcasts';

import { 
  generatePodcastContent as apiGeneratePodcastContent,
} from './api/generation';

import { 
  likePodcast as apiLikePodcast,
  unlikePodcast as apiUnlikePodcast,
} from './api/likes';

import {
  addBookmark as apiAddBookmark,
  removeBookmark as apiRemoveBookmark,
} from './api/bookmarks';

import {
  followUser as apiFollowUser,
  unfollowUser as apiUnfollowUser,
} from './api/users';

import {
  createPlaylist as apiCreatePlaylist,
  addToPlaylist as apiAddToPlaylist,
} from './api/playlists';

import {
  createSeries as apiCreateSeries,
  addEpisodeToSeries as apiAddEpisodeToSeries,
} from './api/series';

import {
  fetchNotificationPreferences as apiFetchNotificationPreferences,
  updateNotificationPreferences as apiUpdateNotificationPreferences,
  type NotificationPreferences,
} from './api/notifications';

import { revalidatePath } from 'next/cache';

export async function generatePodcastAction(data: {
  prompt: string;
  voice: string;
}): Promise<{ success: boolean; imageUrl?: string; audioUrl?: string; error?: string }> {
  try {
    const result = await apiGeneratePodcastContent(data);
    return {
      success: true,
      imageUrl: result.image_url,
      audioUrl: result.audio_url,
    };
  } catch (error: any) {
    console.error('Error generating podcast content:', error);
    return {
      success: false,
      error: error.message || 'Failed to generate podcast content',
    };
  }
}

export async function createPodcastAction(data: {
  podcast_name: string;
  description: string;
  image_url: string;
  audio_url: string;
  ai_voice?: string;
  category: string;
  chapters?: { title: string; start: number }[];
}): Promise<{ success: boolean; id?: string; error?: string }> {
  try {
    const podcast = await apiCreatePodcast(data);
    revalidatePath('/podcasts');
    revalidatePath('/');
    return {
      success: true,
      id: podcast.id,
    };
  } catch (error: any) {
    console.error('Error creating podcast:', error);
    return {
      success: false,
      error: error.message || 'Failed to create podcast',
    };
  }
}

export async function toggleLikeAction(podcastId: string, currentlyLiked: boolean): Promise<{ success: boolean; liked?: boolean; count?: number; error?: string }> {
  try {
    const result = currentlyLiked 
      ? await apiUnlikePodcast(podcastId)
      : await apiLikePodcast(podcastId);
    
    revalidatePath(`/podcasts/${podcastId}`);
    return {
      success: true,
      liked: result.liked,
      count: result.count,
    };
  } catch (error: any) {
    console.error('Error toggling like:', error);
    return {
      success: false,
      error: error.message || 'Failed to toggle like',
    };
  }
}

export async function deletePodcastAction(podcastId: string): Promise<{ success: boolean; error?: string }> {
  try {
    await apiDeletePodcast(podcastId);
    revalidatePath('/podcasts');
    revalidatePath('/');
    revalidatePath(`/profile`);
    return {
      success: true,
    };
  } catch (error: any) {
    console.error('Error deleting podcast:', error);
    return {
      success: false,
      error: error.message || 'Failed to delete podcast',
    };
  }
}

export async function toggleBookmarkAction(podcastId: string, currentlyBookmarked: boolean): Promise<{ success: boolean; bookmarked?: boolean; error?: string }> {
  try {
    currentlyBookmarked 
      ? await apiRemoveBookmark(podcastId)
      : await apiAddBookmark(podcastId);
    
    revalidatePath(`/podcasts/${podcastId}`);
    revalidatePath('/bookmarks');
    return {
      success: true,
      bookmarked: !currentlyBookmarked,
    };
  } catch (error: any) {
    console.error('Error toggling bookmark:', error);
    return {
      success: false,
      error: error.message || 'Failed to toggle bookmark',
    };
  }
}

export async function toggleFollowAction(userId: string, currentlyFollowing: boolean): Promise<{ success: boolean; following?: boolean; error?: string }> {
  try {
    const result = currentlyFollowing 
      ? await apiUnfollowUser(userId)
      : await apiFollowUser(userId);
    
    revalidatePath(`/profile/${userId}`);
    revalidatePath('/feed');
    return {
      success: true,
      following: result.following,
    };
  } catch (error: any) {
    console.error('Error toggling follow:', error);
    return {
      success: false,
      error: error.message || 'Failed to toggle follow',
    };
  }
}

export async function createPlaylistAction(data: {
  name: string;
  description?: string;
}): Promise<{ success: boolean; id?: string; error?: string }> {
  try {
    const playlist = await apiCreatePlaylist(data);
    revalidatePath('/playlists');
    return {
      success: true,
      id: playlist.id,
    };
  } catch (error: any) {
    console.error('Error creating playlist:', error);
    return {
      success: false,
      error: error.message || 'Failed to create playlist',
    };
  }
}

export async function createSeriesAction(data: {
  title: string;
  description?: string;
  cover_url?: string;
}): Promise<{ success: boolean; id?: string; error?: string }> {
  try {
    const series = await apiCreateSeries(data);
    revalidatePath('/series');
    return {
      success: true,
      id: series.id,
    };
  } catch (error: any) {
    console.error('Error creating series:', error);
    return {
      success: false,
      error: error.message || 'Failed to create series',
    };
  }
}

export async function addEpisodeToSeriesAction(data: {
  series_id: string;
  podcast_id: string;
  season_number: number;
  episode_number: number;
}): Promise<{ success: boolean; error?: string }> {
  try {
    await apiAddEpisodeToSeries(data);
    revalidatePath(`/series/${data.series_id}`);
    return { success: true };
  } catch (error: any) {
    console.error('Error adding episode to series:', error);
    return {
      success: false,
      error: error.message || 'Failed to add episode to series',
    };
  }
}

export async function getNotificationPreferencesAction(): Promise<{
  success: boolean;
  preferences?: NotificationPreferences;
  error?: string;
}> {
  try {
    const preferences = await apiFetchNotificationPreferences();
    return { success: true, preferences };
  } catch (error: any) {
    if (error?.digest === 'DYNAMIC_SERVER_USAGE') throw error;
    console.error('Error fetching notification preferences:', error);
    return { success: false, error: error.message || 'Failed to load preferences' };
  }
}

export async function updateNotificationPreferencesAction(
  data: Omit<NotificationPreferences, 'user_id'>
): Promise<{ success: boolean; preferences?: NotificationPreferences; error?: string }> {
  try {
    const preferences = await apiUpdateNotificationPreferences(data);
    revalidatePath('/settings/notifications');
    return { success: true, preferences };
  } catch (error: any) {
    console.error('Error updating notification preferences:', error);
    return { success: false, error: error.message || 'Failed to save preferences' };
  }
}

export async function addToPlaylistAction(playlistId: string, podcastId: string): Promise<{ success: boolean; error?: string }> {
  try {
    await apiAddToPlaylist(playlistId, podcastId);
    revalidatePath('/playlists');
    revalidatePath(`/playlists/${playlistId}`);
    return {
      success: true,
    };
  } catch (error: any) {
    console.error('Error adding to playlist:', error);
    return {
      success: false,
      error: error.message || 'Failed to add to playlist',
    };
  }
}
