-- ============================================
-- Migration 001: Chapters + Notification Preferences
-- Run in Supabase SQL Editor
-- ============================================

-- Add chapters column to podcasts (JSONB array of {title, start})
ALTER TABLE public.podcasts
    ADD COLUMN IF NOT EXISTS chapters JSONB DEFAULT '[]'::jsonb;

-- Notification preferences (one row per user)
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    email_on_new_comment BOOLEAN NOT NULL DEFAULT TRUE,
    email_on_new_follower BOOLEAN NOT NULL DEFAULT TRUE,
    email_on_new_like BOOLEAN NOT NULL DEFAULT FALSE,
    email_weekly_digest BOOLEAN NOT NULL DEFAULT FALSE,
    -- Tracks the last successful weekly digest delivery for idempotency.
    -- The digest worker only sends to users where this is NULL or older than
    -- 6 days, so a restart inside the send window can't double-send.
    last_digest_sent_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- For installs that already ran an earlier version of this migration:
ALTER TABLE public.notification_preferences
    ADD COLUMN IF NOT EXISTS last_digest_sent_at TIMESTAMPTZ;

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification preferences"
    ON public.notification_preferences FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can upsert own notification preferences"
    ON public.notification_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can update own notification preferences"
    ON public.notification_preferences FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() IS NULL);
