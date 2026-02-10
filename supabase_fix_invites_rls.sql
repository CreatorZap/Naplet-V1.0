-- ============================================
-- FIX: RLS Policies for invites table
-- ============================================

-- First, let's see what policies exist
-- SELECT * FROM pg_policies WHERE tablename = 'invites';

-- Drop existing policies on invites
DROP POLICY IF EXISTS "Users can view invites they created" ON invites;
DROP POLICY IF EXISTS "Users can view invites for their babies" ON invites;
DROP POLICY IF EXISTS "Users can create invites for their babies" ON invites;
DROP POLICY IF EXISTS "Users can update invites they created" ON invites;
DROP POLICY IF EXISTS "Users can delete invites they created" ON invites;
DROP POLICY IF EXISTS "invites_select_policy" ON invites;
DROP POLICY IF EXISTS "invites_insert_policy" ON invites;
DROP POLICY IF EXISTS "invites_update_policy" ON invites;
DROP POLICY IF EXISTS "invites_delete_policy" ON invites;

-- Enable RLS on invites table
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- Policy: Users can SELECT invites for babies they own or are caregivers of
CREATE POLICY "invites_select_policy" ON invites
    FOR SELECT
    USING (
        -- User created the invite
        invited_by = auth.uid()
        OR
        -- User owns the baby
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        -- User is a caregiver with invite permission (owner or parent)
        baby_id IN (
            SELECT baby_id FROM caregivers 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'parent')
        )
    );

-- Policy: Users can INSERT invites for babies they own or have invite permission
CREATE POLICY "invites_insert_policy" ON invites
    FOR INSERT
    WITH CHECK (
        -- User is creating the invite (invited_by must be current user)
        invited_by = auth.uid()
        AND
        (
            -- User owns the baby
            baby_id IN (
                SELECT id FROM babies WHERE owner_id = auth.uid()
            )
            OR
            -- User is a caregiver with invite permission
            baby_id IN (
                SELECT baby_id FROM caregivers 
                WHERE user_id = auth.uid() 
                AND role IN ('owner', 'parent')
                AND accepted_at IS NOT NULL
            )
        )
    );

-- Policy: Users can UPDATE invites they created or for babies they own
CREATE POLICY "invites_update_policy" ON invites
    FOR UPDATE
    USING (
        invited_by = auth.uid()
        OR
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
    );

-- Policy: Users can DELETE invites they created or for babies they own
CREATE POLICY "invites_delete_policy" ON invites
    FOR DELETE
    USING (
        invited_by = auth.uid()
        OR
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
    );

-- ============================================
-- FIX: RLS Policies for caregivers table
-- ============================================

-- Drop existing policies on caregivers
DROP POLICY IF EXISTS "Users can view caregivers for their babies" ON caregivers;
DROP POLICY IF EXISTS "Users can insert caregivers" ON caregivers;
DROP POLICY IF EXISTS "Users can update caregivers" ON caregivers;
DROP POLICY IF EXISTS "Users can delete caregivers" ON caregivers;
DROP POLICY IF EXISTS "caregivers_select_policy" ON caregivers;
DROP POLICY IF EXISTS "caregivers_insert_policy" ON caregivers;
DROP POLICY IF EXISTS "caregivers_update_policy" ON caregivers;
DROP POLICY IF EXISTS "caregivers_delete_policy" ON caregivers;

-- Enable RLS on caregivers table
ALTER TABLE caregivers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can SELECT caregivers for babies they own or are caregivers of
CREATE POLICY "caregivers_select_policy" ON caregivers
    FOR SELECT
    USING (
        -- User is this caregiver
        user_id = auth.uid()
        OR
        -- User owns the baby
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        -- User is a caregiver of this baby
        baby_id IN (
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can INSERT caregivers (for accepting invites or creating owner)
CREATE POLICY "caregivers_insert_policy" ON caregivers
    FOR INSERT
    WITH CHECK (
        -- User is creating their own caregiver record (accepting invite)
        user_id = auth.uid()
        OR
        -- User owns the baby (creating owner record)
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
    );

-- Policy: Users can UPDATE caregivers for babies they own
CREATE POLICY "caregivers_update_policy" ON caregivers
    FOR UPDATE
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
    );

-- Policy: Users can DELETE caregivers for babies they own (except owner)
CREATE POLICY "caregivers_delete_policy" ON caregivers
    FOR DELETE
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        AND role != 'owner'
    );

-- ============================================
-- Verify policies were created
-- ============================================
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('invites', 'caregivers')
ORDER BY tablename, policyname;
