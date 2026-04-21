"use server";
import { apiRequest } from './client';

// ==================== TYPES ====================

export interface LeaderboardUser {
  user_id: string;
  username: string;
  avatar_url: string;
  total_plays: number;
  total_likes: number;
  podcast_count: number;
}

// ==================== API FUNCTIONS ====================

export async function fetchLeaderboard(params?: {
  limit?: number;
  sort_by?: 'plays' | 'likes' | 'podcasts';
}): Promise<LeaderboardUser[]> {
  const queryParams = new URLSearchParams();
  if (params?.limit) queryParams.append('limit', params.limit.toString());
  if (params?.sort_by) queryParams.append('sort_by', params.sort_by);

  const query = queryParams.toString() ? `?${queryParams.toString()}` : '';
  return apiRequest<LeaderboardUser[]>(`/api/leaderboard${query}`);
}
