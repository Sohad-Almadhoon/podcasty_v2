-- Quick Fix: Manually create your user in public.users
-- This will create the user record for sohadalmadhoon2021@gmail.com

-- First, verify your user exists in auth.users
SELECT id, email, raw_user_meta_data 
FROM auth.users 
WHERE email = 'sohadalmadhoon2021@gmail.com';

-- Then insert into public.users
INSERT INTO public.users (id, email, username, avatar_url, created_at)
VALUES (
  'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0',
  'sohadalmadhoon2021@gmail.com',
  'sohadalmadhoon2021',
  '',  -- You can add an avatar URL later
  NOW()
)
ON CONFLICT (id) DO NOTHING;
