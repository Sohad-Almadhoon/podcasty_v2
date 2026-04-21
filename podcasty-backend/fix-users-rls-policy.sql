-- ============================================
-- FIX: User RLS Policy for Service Role Updates
-- ============================================
-- The issue: Service role (used by Go backend) needs to bypass RLS
-- completely to auto-create and update user records.

-- SOLUTION: Use permissive policies that always return true
-- Service role will bypass RLS due to GRANT permissions below.

-- Drop existing policies
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users are viewable by everyone" ON public.users;

-- Recreate policies with proper service role support
-- SELECT: Everyone can view all users
CREATE POLICY "Users are viewable by everyone" 
ON public.users 
FOR SELECT 
USING (true);

-- INSERT: Allow all inserts (service role + user self-registration)
CREATE POLICY "Users can insert own profile" 
ON public.users 
FOR INSERT 
WITH CHECK (true);

-- UPDATE: Allow users to update own profile OR via service role
CREATE POLICY "Users can update own profile" 
ON public.users 
FOR UPDATE 
USING (true)
WITH CHECK (auth.uid() = id OR auth.uid() IS NULL);

-- DELETE: Only users can delete their own profiles (if needed)
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
CREATE POLICY "Users can delete own profile" 
ON public.users 
FOR DELETE 
USING (auth.uid() = id);

-- Critical: Grant service role full access to bypass RLS
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT USAGE ON SCHEMA public TO service_role;

-- Verify configuration
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;
