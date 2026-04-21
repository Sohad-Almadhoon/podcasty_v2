export interface AudioProps {
  audioUrl: string;
  podcastId: string;
  imageUrl: string;
  title: string;
  author: string;
}

export interface AudioContextType {
  audio: AudioProps | undefined;
  setAudio: React.Dispatch<React.SetStateAction<AudioProps | undefined>>;
  seekRequest: number | null;
  requestSeek: (seconds: number) => void;
  clearSeekRequest: () => void;
}

export interface Chapter {
  title: string;
  start: number; // seconds
}

export interface PodcastAuthor {
  username: string;
  avatar_url: string;
}

export interface Podcast {
  id: string;
  podcast_name: string;
  description: string;
  image_url: string;
  play_count: number;
  // String at the API boundary because the backend's voice catalog grows
  // independently from the frontend's `AiVoice` enum.
  ai_voice: string;
  user_id: string;
  audio_url: string;
  created_at?: string;
  category?: PodcastCategory;
  duration_seconds?: number;
  chapters?: Chapter[];
  likes?: { count: number }[];
  // Always a single object after passing through the API client's
  // `normalizePodcast`. PostgREST may return an array for embedded relations,
  // but consumers of this type should not have to handle that.
  users: PodcastAuthor;
}

export interface Comment {
  id: string;
  podcast_id: string;
  user_id: string;
  body: string;
  created_at: string;
  users: {
    username: string;
    avatar_url: string;
  };
}

export interface Bookmark {
  id: string;
  user_id: string;
  podcast_id: string;
  created_at: string;
  podcasts: Podcast;
}

export interface Playlist {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  items: PlaylistItem[];
}

export interface PlaylistItem {
  id: string;
  playlist_id: string;
  podcast_id: string;
  position: number;
  podcasts: Podcast;
}

export interface Follow {
  id: string;
  follower_id: string;
  following_id: string;
  created_at: string;
  users: {
    username: string;
    avatar_url: string;
  };
}

export interface LeaderboardEntry {
  user_id: string;
  username: string;
  avatar_url: string;
  total_plays: number;
  podcast_count: number;
  total_likes: number;
}

export interface Transcript {
  podcast_id: string;
  text: string;
  generated_at: string;
}

export interface DailyPlay {
  date: string;
  plays: number;
}

export interface PodcastAnalytics {
  podcast_id: string;
  total_plays: number;
  total_likes: number;
  total_comments: number;
  total_bookmarks: number;
  daily_plays: DailyPlay[];
}

export type PodcastCategory =
  | "Technology"
  | "Science"
  | "Business"
  | "Health"
  | "Comedy"
  | "True Crime"
  | "History"
  | "Education"
  | "Sports"
  | "Music"
  | "News"
  | "Politics"
  | "Gaming"
  | "Entertainment"
  | "Arts"
  | "Fiction"
  | "Self-Improvement"
  | "Society & Culture"
  | "Food"
  | "Travel";

export type AiVoice = "alloy" | "ash" | "coral" | "echo" | "fable" | "onyx" | "nova" | "sage" | "shimmer";
export type paramsType = Promise<{ id: string }>;