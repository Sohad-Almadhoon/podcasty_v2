-- ============================================
-- Migration 002: User Badges & Achievements
-- Run in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_key TEXT NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, badge_key)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON public.user_badges(user_id);

ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- Everyone can see badges (they're public achievements)
CREATE POLICY "Badges are viewable by everyone"
    ON public.user_badges FOR SELECT USING (true);

-- Only the server (service role) inserts badges; users don't self-award
CREATE POLICY "Service role can insert badges"
    ON public.user_badges FOR INSERT WITH CHECK (true);
