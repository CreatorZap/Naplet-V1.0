-- ============================================
-- Sprint 2: Diaper, Health Records & Pumping
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- PART 1: DIAPER RECORDS TABLE
-- ============================================

-- Create diaper_records table
CREATE TABLE IF NOT EXISTS diaper_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    content TEXT NOT NULL CHECK (content IN ('dry', 'wet', 'dirty', 'mixed')),
    weight_grams INTEGER,
    notes TEXT,
    recorded_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_diaper_baby_id ON diaper_records(baby_id);
CREATE INDEX IF NOT EXISTS idx_diaper_changed_at ON diaper_records(changed_at DESC);

-- Enable Row Level Security
ALTER TABLE diaper_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "diaper_select_policy" ON diaper_records;
DROP POLICY IF EXISTS "diaper_insert_policy" ON diaper_records;
DROP POLICY IF EXISTS "diaper_update_policy" ON diaper_records;
DROP POLICY IF EXISTS "diaper_delete_policy" ON diaper_records;

-- Policy: Users can SELECT diaper records for babies they own or are caregivers of
CREATE POLICY "diaper_select_policy" ON diaper_records
    FOR SELECT USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can INSERT diaper records for babies they own or are caregivers of
CREATE POLICY "diaper_insert_policy" ON diaper_records
    FOR INSERT WITH CHECK (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can UPDATE diaper records for babies they own or are caregivers of
CREATE POLICY "diaper_update_policy" ON diaper_records
    FOR UPDATE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can DELETE diaper records for babies they own or are caregivers of
CREATE POLICY "diaper_delete_policy" ON diaper_records
    FOR DELETE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- ============================================
-- PART 2: HEALTH RECORDS TABLE
-- ============================================

-- Create health_records table
CREATE TABLE IF NOT EXISTS health_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('temperature', 'medication')),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    temperature_celsius DECIMAL(3,1),
    medication_name TEXT,
    medication_dose TEXT,
    notes TEXT,
    recorded_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_baby_id ON health_records(baby_id);
CREATE INDEX IF NOT EXISTS idx_health_recorded_at ON health_records(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_type ON health_records(type);

-- Enable Row Level Security
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "health_select_policy" ON health_records;
DROP POLICY IF EXISTS "health_insert_policy" ON health_records;
DROP POLICY IF EXISTS "health_update_policy" ON health_records;
DROP POLICY IF EXISTS "health_delete_policy" ON health_records;

-- Policy: Users can SELECT health records for babies they own or are caregivers of
CREATE POLICY "health_select_policy" ON health_records
    FOR SELECT USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can INSERT health records for babies they own or are caregivers of
CREATE POLICY "health_insert_policy" ON health_records
    FOR INSERT WITH CHECK (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can UPDATE health records for babies they own or are caregivers of
CREATE POLICY "health_update_policy" ON health_records
    FOR UPDATE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- Policy: Users can DELETE health records for babies they own or are caregivers of
CREATE POLICY "health_delete_policy" ON health_records
    FOR DELETE USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
            UNION
            SELECT baby_id FROM caregivers WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- ============================================
-- PART 3: ADD PUMPING TO FEEDING RECORDS
-- ============================================

-- First, we need to update the feeding_type enum to include 'pumping'
-- Since PostgreSQL doesn't allow easy enum modification, we'll use ALTER TYPE
DO $$ BEGIN
    ALTER TYPE feeding_type ADD VALUE IF NOT EXISTS 'pumping';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add pumping-specific columns to feeding_records
ALTER TABLE feeding_records
ADD COLUMN IF NOT EXISTS pumping_mode TEXT CHECK (pumping_mode IN ('total', 'per_side')),
ADD COLUMN IF NOT EXISTS pumping_left_ml INTEGER,
ADD COLUMN IF NOT EXISTS pumping_right_ml INTEGER,
ADD COLUMN IF NOT EXISTS pumping_total_ml INTEGER;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify diaper_records table
SELECT 'diaper_records table created successfully' as status;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'diaper_records'
ORDER BY ordinal_position;

-- Verify health_records table
SELECT 'health_records table created successfully' as status;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'health_records'
ORDER BY ordinal_position;

-- Verify feeding_records has new columns
SELECT 'feeding_records updated with pumping columns' as status;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'feeding_records'
ORDER BY ordinal_position;
