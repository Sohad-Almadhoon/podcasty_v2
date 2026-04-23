"use server";
import axios, { AxiosRequestConfig } from 'axios';
import { getSupabaseAuth } from '../supabase';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * Get the authentication token from Supabase
 */
async function getAuthToken(): Promise<string | null> {
  try {
    const supabase = await getSupabaseAuth();
    
    // First, validate and refresh the session by calling getUser
    // This ensures we have a valid, non-expired token
    const { data: { user }, error } = await supabase.auth.getUser();
    
    if (error || !user) {
      console.error('Error validating user session:', error);
      return null;
    }
    
    // Now get the fresh session token
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session?.access_token) {
      console.error('No access token in session');
      return null;
    }
    
    return session.access_token;
  } catch (error) {
    if ((error as { digest?: string })?.digest === 'DYNAMIC_SERVER_USAGE') {
      throw error;
    }
    console.error('Error getting auth token:', error);
    return null;
  }
}

/**
 * Make an authenticated API request (server-side)
 */
export async function apiRequest<T>(
  endpoint: string,
  options: Omit<AxiosRequestConfig, 'url' | 'baseURL'> = {}
): Promise<T> {
  const token = await getAuthToken();
  
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> || {}),
  };

  if (!headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await axios({
      url: endpoint,
      baseURL: API_BASE_URL,
      ...options,
      headers,
    });

    return response.data as T;
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      const message = error.response?.data?.message || error.response?.data || error.message;
      console.error(`API request failed for ${endpoint}:`, message);
      throw new Error(`API Error (${error.response?.status || 'Unknown'}): ${typeof message === 'string' ? message : JSON.stringify(message)}`);
    }
    console.error(`API request failed for ${endpoint}:`, error);
    throw error;
  }
}

/**
 * Make a public API request (client-side, no auth)
 */
export async function publicApiRequest<T>(
  endpoint: string,
  options: Omit<AxiosRequestConfig, 'url' | 'baseURL'> = {}
): Promise<T> {
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> || {}),
  };

  if (!headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  try {
    const response = await axios({
      url: endpoint,
      baseURL: API_BASE_URL,
      ...options,
      headers,
    });

    return response.data as T;
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      const message = error.response?.data?.message || error.response?.data || error.message;
      const status = error.response?.status || 'Network Error';
      console.error(`Public API request failed for ${endpoint}:`, {
        status,
        message,
        baseURL: API_BASE_URL,
        fullURL: `${API_BASE_URL}${endpoint}`,
      });
      throw new Error(`API Error (${status}): ${typeof message === 'string' ? message : JSON.stringify(message)}`);
    }
    console.error(`Public API unknown error for ${endpoint}:`, error);
    throw error;
  }
}
