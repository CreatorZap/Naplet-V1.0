-- ============================================
-- Feeding Records Table for Naplet
-- Run this in Supabase SQL Editor
-- ============================================

-- Create ENUMs for feeding types
DO $$ BEGIN
    CREATE TYPE feeding_type AS ENUM ('breast', 'bottle', 'solid');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE breast_side AS ENUM ('left', 'right', 'both');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE bottle_content_type AS ENUM ('breast_milk', 'formula', 'mixed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create feeding_records table
CREATE TABLE IF NOT EXISTS feeding_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    type feeding_type NOT NULL,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    breast_side breast_side,
    duration_left_seconds INTEGER,
    duration_right_seconds INTEGER,
    bottle_amount_ml DECIMAL(5,1),
    bottle_type bottle_content_type,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_feeding_baby_id ON feeding_records(baby_id);
CREATE INDEX IF NOT EXISTS idx_feeding_start_time ON feeding_records(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_feeding_type ON feeding_records(type);
CREATE INDEX IF NOT EXISTS idx_feeding_active ON feeding_records(baby_id) WHERE end_time IS NULL;

-- Enable Row Level Security
ALTER TABLE feeding_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "feeding_select_policy" ON feeding_records;
DROP POLICY IF EXISTS "feeding_insert_policy" ON feeding_records;
DROP POLICY IF EXISTS "feeding_update_policy" ON feeding_records;
DROP POLICY IF EXISTS "feeding_delete_policy" ON feeding_records;

-- Policy: Users can SELECT feeding records for babies they own or are caregivers of
CREATE POLICY "feeding_select_policy" ON feeding_records
    FOR SELECT USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can INSERT feeding records for babies they own or are caregivers of
CREATE POLICY "feeding_insert_policy" ON feeding_records
    FOR INSERT WITH CHECK (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can UPDATE feeding records for babies they own or are caregivers of
CREATE POLICY "feeding_update_policy" ON feeding_records
    FOR UPDATE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can DELETE feeding records for babies they own or are caregivers of
CREATE POLICY "feeding_delete_policy" ON feeding_records
    FOR DELETE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_feeding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_feeding_records_updated_at ON feeding_records;
CREATE TRIGGER update_feeding_records_updated_at
    BEFORE UPDATE ON feeding_records
    FOR EACH ROW
    EXECUTE FUNCTION update_feeding_updated_at();

-- ============================================
-- Useful queries for the app
-- ============================================

-- Get today's feeding records for a baby
-- SELECT * FROM feeding_records
-- WHERE baby_id = 'your-baby-id'
-- AND start_time >= CURRENT_DATE
-- ORDER BY start_time DESC;

-- Get active (ongoing) feeding session
-- SELECT * FROM feeding_records
-- WHERE baby_id = 'your-baby-id'
-- AND end_time IS NULL
-- LIMIT 1;

-- Get feeding statistics for today
-- SELECT
--     type,
--     COUNT(*) as count,
--     SUM(COALESCE(duration_left_seconds, 0) + COALESCE(duration_right_seconds, 0)) as total_breast_seconds,
--     SUM(bottle_amount_ml) as total_bottle_ml
-- FROM feeding_records
-- WHERE baby_id = 'your-baby-id'
-- AND start_time >= CURRENT_DATE
-- GROUP BY type;

-- Verify table created successfully
SELECT 'feeding_records table created successfully' as status;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'feeding_records'
ORDER BY ordinal_position;
