"use server";
import { apiRequest } from './client';

// ==================== TYPES ====================

export interface Comment {
  id: string;
  podcast_id: string;
  user_id: string;
  body: string;
  created_at: string;
  users?: {
    username: string;
    avatar_url: string;
  };
}

// ==================== API FUNCTIONS ====================

export async function fetchComments(podcastId: string): Promise<Comment[]> {
  return apiRequest<Comment[]>(`/api/podcasts/comments?podcast_id=${podcastId}`);
}

export async function createComment(podcastId: string, body: string): Promise<Comment> {
  return apiRequest<Comment>('/api/podcasts/comments/create', {
    method: 'POST',
    data: {
      podcast_id: podcastId,
      body,
    },
  });
}

export async function deleteComment(commentId: string): Promise<{ message: string }> {
  return apiRequest(`/api/comments/delete?id=${commentId}`, {
    method: 'DELETE',
  });
}
