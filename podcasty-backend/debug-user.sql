-- ============================================
-- DEBUG: Check User Status
-- ============================================
-- Run each section one by one to diagnose the issue

-- STEP 1: Check if user exists in auth.users
SELECT 
    id, 
    email, 
    created_at,
    raw_user_meta_data->>'full_name' as full_name,
    raw_user_meta_data->>'avatar_url' as avatar
FROM auth.users 
WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';
-- Expected: Should return 1 row with your email

-- STEP 2: Check if user exists in public.users
SELECT * FROM public.users 
WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';
-- Expected: Should return 0 rows (user doesn't exist yet)

-- STEP 3: Check RLS policies on users table
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'users';
-- Expected: Should show all RLS policies

-- STEP 4: Try manual insert (bypassing RLS with service role)
-- Delete first if exists
DELETE FROM public.users WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';

-- Then insert
INSERT INTO public.users (id, email, username, avatar_url, created_at)
VALUES (
  'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0',
  'sohadalmadhoon2021@gmail.com',
  'Sohad',
  '',
  NOW()
);

-- Verify insert worked
SELECT * FROM public.users 
WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';
-- Expected: Should return the user you just inserted

-- STEP 5: If still having issues, temporarily disable RLS
-- (Re-enable after testing!)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Try the insert again
DELETE FROM public.users WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';
INSERT INTO public.users (id, email, username, avatar_url, created_at)
VALUES (
  'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0',
  'sohadalmadhoon2021@gmail.com',
  'Sohad',
  '',
  NOW()
);

-- Re-enable RLS IMPORTANT!
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Final verification
SELECT * FROM public.users 
WHERE id = 'a416337a-b57f-4cc9-bcf1-e0c3fb8919a0';
