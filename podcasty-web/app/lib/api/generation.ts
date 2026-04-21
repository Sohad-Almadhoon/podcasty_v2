"use server";
import { apiRequest } from './client';

// ==================== API FUNCTIONS ====================

export async function generatePodcastContent(data: {
  prompt: string;
  voice: string;
}): Promise<{ image_url: string; audio_url: string }> {
  return apiRequest('/api/generate', {
    method: 'POST',
    data: {
      prompt: data.prompt,
      voice: data.voice,
    },
  });
}
