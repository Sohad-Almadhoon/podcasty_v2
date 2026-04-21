-- ============================================
-- Migration 003: Podcast Series/Seasons
-- Run in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS public.series (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    cover_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_series_user_id ON public.series(user_id);

-- Links podcasts to a series with season/episode numbering
CREATE TABLE IF NOT EXISTS public.series_episodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    series_id UUID NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
    podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
    season_number INTEGER NOT NULL DEFAULT 1,
    episode_number INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(series_id, podcast_id),
    UNIQUE(series_id, season_number, episode_number)
);

CREATE INDEX IF NOT EXISTS idx_series_episodes_series_id ON public.series_episodes(series_id);
CREATE INDEX IF NOT EXISTS idx_series_episodes_podcast_id ON public.series_episodes(podcast_id);

-- RLS
ALTER TABLE public.series ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_episodes ENABLE ROW LEVEL SECURITY;

-- Series: everyone can read, owners can manage
CREATE POLICY "Series are viewable by everyone" ON public.series FOR SELECT USING (true);
CREATE POLICY "Users can create own series" ON public.series FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);
CREATE POLICY "Users can update own series" ON public.series FOR UPDATE USING (auth.uid() = user_id OR auth.uid() IS NULL);
CREATE POLICY "Users can delete own series" ON public.series FOR DELETE USING (auth.uid() = user_id OR auth.uid() IS NULL);

-- Episodes: everyone can read, series owners can manage
CREATE POLICY "Series episodes are viewable by everyone" ON public.series_episodes FOR SELECT USING (true);
CREATE POLICY "Users can manage series episodes" ON public.series_episodes FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update series episodes" ON public.series_episodes FOR UPDATE USING (true);
CREATE POLICY "Users can remove series episodes" ON public.series_episodes FOR DELETE USING (true);
