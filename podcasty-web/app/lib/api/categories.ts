"use server";
import { apiRequest } from './client';

// ==================== API FUNCTIONS ====================

export async function fetchCategories(): Promise<string[]> {
  return apiRequest<string[]>('/api/categories');
}
