"use server";
import { apiRequest } from './client';

export interface NotificationPreferences {
  user_id: string;
  email_on_new_comment: boolean;
  email_on_new_follower: boolean;
  email_on_new_like: boolean;
  email_weekly_digest: boolean;
}

export async function fetchNotificationPreferences(): Promise<NotificationPreferences> {
  return apiRequest<NotificationPreferences>('/api/notifications/preferences', {
    method: 'GET',
  });
}

export async function updateNotificationPreferences(
  prefs: Omit<NotificationPreferences, 'user_id'>
): Promise<NotificationPreferences> {
  return apiRequest<NotificationPreferences>('/api/notifications/preferences', {
    method: 'PUT',
    data: prefs,
  });
}
