-- Create test user for API testing and profile viewing
-- Run this in your Supabase SQL Editor

INSERT INTO public.users (id, username, avatar_url, email)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'Test User',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=test',
  'test@example.com'
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  avatar_url = EXCLUDED.avatar_url,
  email = EXCLUDED.email;

-- Verify user was created
SELECT * FROM public.users WHERE id = '00000000-0000-0000-0000-000000000000';
