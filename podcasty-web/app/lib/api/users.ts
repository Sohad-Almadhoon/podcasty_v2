"use server";
import { apiRequest } from './client';
import { normalizePodcasts } from './normalize';
import type { Podcast } from './podcasts';

// ==================== TYPES ====================

export interface User {
  id: string;
  email: string;
  username: string;
  avatar_url: string;
  created_at: string;
}

// ==================== API FUNCTIONS ====================

export async function fetchUser(userId: string): Promise<User> {
  return apiRequest<User>(`/api/users/${userId}`, {
    method: 'GET',
  });
}

export async function fetchUserPodcasts(userId: string): Promise<Podcast[]> {
  const data = await apiRequest<Podcast[]>(`/api/users/${userId}/podcasts`, {
    method: 'GET',
  });
  return normalizePodcasts(data);
}

export async function followUser(userId: string): Promise<{ message: string; following: boolean }> {
  return apiRequest('/api/users/follow', {
    method: 'POST',
    data: { user_id: userId },
  });
}

export async function unfollowUser(userId: string): Promise<{ message: string; following: boolean }> {
  return apiRequest('/api/users/unfollow', {
    method: 'POST',
    data: { user_id: userId },
  });
}

export async function checkFollowStatus(userId: string): Promise<{ following: boolean }> {
  return apiRequest<{ following: boolean }>(`/api/users/follow/status?user_id=${userId}`);
}

export async function fetchFollows(): Promise<any[]> {
  return apiRequest<any[]>('/api/users/follows');
}

export async function updateUser(userId: string, data: {
  username?: string;
  avatar_url?: string;
}): Promise<User> {
  return apiRequest<User>(`/api/users/${userId}`, {
    method: 'PATCH',
    data,
  });
}
