-- ============================================
-- FIX: Recreate User Record in public.users
-- ============================================
-- Run this in Supabase SQL Editor
-- This will create your user record after recreating the users table

-- Step 1: Verify your auth user exists
-- Copy the output from this query
SELECT id, email, raw_user_meta_data->>'full_name' as full_name, raw_user_meta_data->>'avatar_url' as avatar_url
FROM auth.users 
WHERE email = 'sohadalmadhoon2021@gmail.com';

-- Step 2: Insert into public.users
-- Replace values if needed based on Step 1 output
INSERT INTO public.users (id, email, username, avatar_url, created_at)
VALUES (
  'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0',
  'sohadalmadhoon2021@gmail.com',
  'Sohad Al Madhoon',  -- You can change this to your preferred username
  '',                  -- Add avatar URL if you have one
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  username = EXCLUDED.username,
  avatar_url = EXCLUDED.avatar_url,
  updated_at = NOW();

-- Step 3: Verify the insert worked
SELECT * FROM public.users WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';

-- ============================================
-- ALTERNATIVE: Enable Service Key Auto-Creation
-- ============================================
-- If you want automatic user creation to work, ensure:
-- 1. Your .env has SUPABASE_SERVICE_KEY set
-- 2. Restart your Go backend after setting it

-- To get your Service Key:
-- 1. Go to Supabase Dashboard > Project Settings > API
-- 2. Copy the "service_role" key (the secret one)
-- 3. Add to podcasty-go/.env:
--    SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
