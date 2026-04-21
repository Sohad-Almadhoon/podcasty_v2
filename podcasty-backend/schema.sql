-- ============================================
-- PODCASTY DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
-- Create a public users table to store additional user profile data
-- This references auth.users but doesn't modify it
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY,
    username TEXT NOT NULL,
    avatar_url TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PODCASTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.podcasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_name TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    audio_url TEXT NOT NULL,
    play_count INTEGER DEFAULT 0,
    ai_voice TEXT DEFAULT 'alloy',
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category TEXT,
    duration_seconds INTEGER,
    chapters JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_podcasts_user_id ON public.podcasts(user_id);
CREATE INDEX IF NOT EXISTS idx_podcasts_category ON public.podcasts(category);
CREATE INDEX IF NOT EXISTS idx_podcasts_created_at ON public.podcasts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_podcasts_play_count ON public.podcasts(play_count DESC);

-- ============================================
-- LIKES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(podcast_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_podcast_id ON public.likes(podcast_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);

-- ============================================
-- COMMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_podcast_id ON public.comments(podcast_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

-- ============================================
-- BOOKMARKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(podcast_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_podcast_id ON public.bookmarks(podcast_id);

-- ============================================
-- PLAYLISTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);

-- ============================================
-- PLAYLIST ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.playlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    playlist_id UUID NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    position INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(playlist_id, podcast_id)
);

CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist_id ON public.playlist_items(playlist_id);

-- ============================================
-- FOLLOWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

-- ============================================
-- PLAYS LOG TABLE (for analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS public.plays_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    played_at TIMESTAMPTZ DEFAULT NOW(),
    played_date DATE DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_plays_log_podcast_id ON public.plays_log(podcast_id);
CREATE INDEX IF NOT EXISTS idx_plays_log_played_date ON public.plays_log(played_date DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.podcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plays_log ENABLE ROW LEVEL SECURITY;

-- Users: Everyone can read, users can update their own profile
CREATE POLICY "Users are viewable by everyone" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id OR auth.uid() IS NULL);

-- Podcasts: Everyone can read, users can create, only owners can update/delete
CREATE POLICY "Podcasts are viewable by everyone" ON public.podcasts FOR SELECT USING (true);
CREATE POLICY "Users can create podcasts" ON public.podcasts FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own podcasts" ON public.podcasts FOR UPDATE USING (auth.uid() = user_id OR auth.uid() IS NULL);
CREATE POLICY "Users can delete own podcasts" ON public.podcasts FOR DELETE USING (auth.uid() = user_id OR auth.uid() IS NULL);

-- Likes: Everyone can read, authenticated users can create/delete their own
CREATE POLICY "Likes are viewable by everyone" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Users can create likes" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own likes" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- Comments: Everyone can read, users can create, only authors can delete
CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Users can create comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON public.comments FOR UPDATE USING (auth.uid() = user_id);

-- Bookmarks: Users can only see and manage their own
CREATE POLICY "Users can view own bookmarks" ON public.bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own bookmarks" ON public.bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own bookmarks" ON public.bookmarks FOR DELETE USING (auth.uid() = user_id);

-- Playlists: Users can only see and manage their own
CREATE POLICY "Users can view own playlists" ON public.playlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own playlists" ON public.playlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own playlists" ON public.playlists FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own playlists" ON public.playlists FOR DELETE USING (auth.uid() = user_id);

-- Playlist Items: Inherit from parent playlist permissions
CREATE POLICY "Users can view own playlist items" ON public.playlist_items FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid()));
CREATE POLICY "Users can add items to own playlists" ON public.playlist_items FOR INSERT 
    WITH CHECK (EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid()));
CREATE POLICY "Users can remove items from own playlists" ON public.playlist_items FOR DELETE 
    USING (EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid()));

-- Follows: Everyone can read, users manage their own follows
CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can create follows" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can delete own follows" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Plays Log: Everyone can read, anyone can log a play
CREATE POLICY "Plays are viewable by everyone" ON public.plays_log FOR SELECT USING (true);
CREATE POLICY "Anyone can log plays" ON public.plays_log FOR INSERT WITH CHECK (true);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to increment play count
CREATE OR REPLACE FUNCTION increment_play_count(podcast_uuid UUID, user_uuid UUID DEFAULT NULL)
RETURNS void AS $$
BEGIN
    UPDATE public.podcasts SET play_count = play_count + 1 WHERE id = podcast_uuid;
    INSERT INTO public.plays_log (podcast_id, user_id, played_at, played_date) 
    VALUES (podcast_uuid, user_uuid, NOW(), CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SEED DATA (Optional - for testing)
-- ============================================

-- Insert a test user (for development)
INSERT INTO public.users (id, username, avatar_url, email)
VALUES ('00000000-0000-0000-0000-000000000000', 'testuser', 'https://api.dicebear.com/7.x/avataaars/svg?seed=test', 'test@example.com')
ON CONFLICT (id) DO NOTHING;

-- Grant access for service role to bypass RLS
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

COMMENT ON TABLE public.podcasts IS 'Stores podcast episodes created by users';
COMMENT ON TABLE public.likes IS 'Stores user likes/favorites for podcasts';
COMMENT ON TABLE public.comments IS 'Stores comments on podcasts';
COMMENT ON TABLE public.bookmarks IS 'Stores bookmarked podcasts for later listening';
COMMENT ON TABLE public.playlists IS 'User-created playlists';
COMMENT ON TABLE public.playlist_items IS 'Podcasts within playlists';
COMMENT ON TABLE public.follows IS 'User follow relationships';
COMMENT ON TABLE public.plays_log IS 'Analytics log of podcast plays';
