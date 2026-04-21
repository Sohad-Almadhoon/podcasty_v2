-- ============================================
-- IMMEDIATE FIX: Insert User Manually
-- ============================================
-- Run this ENTIRE script in Supabase SQL Editor
-- This will fix the "User not found" error

-- Step 1: First, get your user info from auth
SELECT 
    id, 
    email, 
    raw_user_meta_data->>'full_name' as full_name,
    raw_user_meta_data->>'avatar_url' as avatar_url,
    raw_user_meta_data->>'picture' as picture
FROM auth.users 
WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';

-- Step 2: Delete existing user if any (to avoid conflicts)
DELETE FROM public.users WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';

-- Step 3: Insert your user
-- Replace username and avatar_url with values from Step 1 if needed
INSERT INTO public.users (id, email, username, avatar_url, created_at, updated_at)
VALUES (
  'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0',
  'sohadalmadhoon2021@gmail.com',
  'Sohad',  -- Change this to your preferred name
  '',       -- Add your avatar URL here if you have one
  NOW(),
  NOW()
);

-- Step 4: Verify it worked
SELECT * FROM public.users WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';

-- You should see your user record now
-- Refresh your app - the error should be gone!
