-- ============================================
-- FIX: Foreign Key Constraints for caregivers and invites
-- ============================================

-- First, check current foreign keys
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('caregivers', 'invites');

-- ============================================
-- Option 1: Ensure profiles exist for all auth users
-- ============================================

-- Create trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- Option 2: Fix foreign keys to reference auth.users instead of profiles
-- ============================================

-- Drop existing foreign key on caregivers.user_id
ALTER TABLE caregivers DROP CONSTRAINT IF EXISTS caregivers_user_id_fkey;

-- Recreate to reference auth.users directly (more reliable)
ALTER TABLE caregivers 
    ADD CONSTRAINT caregivers_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Same for invited_by
ALTER TABLE caregivers DROP CONSTRAINT IF EXISTS caregivers_invited_by_fkey;
ALTER TABLE caregivers 
    ADD CONSTRAINT caregivers_invited_by_fkey 
    FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Fix invites table
ALTER TABLE invites DROP CONSTRAINT IF EXISTS invites_invited_by_fkey;
ALTER TABLE invites 
    ADD CONSTRAINT invites_invited_by_fkey 
    FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE invites DROP CONSTRAINT IF EXISTS invites_accepted_by_fkey;
ALTER TABLE invites 
    ADD CONSTRAINT invites_accepted_by_fkey 
    FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- ============================================
-- Ensure profiles table exists with correct structure
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- Users can view all profiles
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT USING (true);

-- Users can insert their own profile
CREATE POLICY "profiles_insert_policy" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "profiles_update_policy" ON profiles
    FOR UPDATE USING (id = auth.uid());

-- ============================================
-- Create missing profiles for existing users
-- ============================================

INSERT INTO profiles (id, email, display_name, created_at, updated_at)
SELECT 
    id,
    email,
    COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(email, '@', 1)),
    created_at,
    NOW()
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Verify the fixes
-- ============================================

SELECT 'Profiles count:' as info, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'Auth users count:', COUNT(*) FROM auth.users
UNION ALL
SELECT 'Caregivers count:', COUNT(*) FROM caregivers
UNION ALL
SELECT 'Invites count:', COUNT(*) FROM invites;
