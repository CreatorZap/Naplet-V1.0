-- ============================================
-- FIX: Add missing columns to caregivers table
-- ============================================

-- Add created_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'caregivers' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE caregivers ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'caregivers' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE caregivers ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Add display_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'caregivers' AND column_name = 'display_name'
    ) THEN
        ALTER TABLE caregivers ADD COLUMN display_name TEXT;
    END IF;
END $$;

-- Add invited_by column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'caregivers' AND column_name = 'invited_by'
    ) THEN
        ALTER TABLE caregivers ADD COLUMN invited_by UUID REFERENCES profiles(id);
    END IF;
END $$;

-- Add accepted_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'caregivers' AND column_name = 'accepted_at'
    ) THEN
        ALTER TABLE caregivers ADD COLUMN accepted_at TIMESTAMPTZ;
    END IF;
END $$;

-- Update existing rows to have created_at and updated_at if null
UPDATE caregivers SET created_at = NOW() WHERE created_at IS NULL;
UPDATE caregivers SET updated_at = NOW() WHERE updated_at IS NULL;

-- Create trigger for updated_at if not exists
CREATE OR REPLACE FUNCTION update_caregivers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_caregivers_updated_at ON caregivers;
CREATE TRIGGER trigger_caregivers_updated_at
    BEFORE UPDATE ON caregivers
    FOR EACH ROW
    EXECUTE FUNCTION update_caregivers_updated_at();

-- ============================================
-- FIX: Ensure invites table has all columns
-- ============================================

-- Add updated_at to invites if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'invites' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE invites ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- ============================================
-- Verify tables structure
-- ============================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'caregivers'
ORDER BY ordinal_position;
