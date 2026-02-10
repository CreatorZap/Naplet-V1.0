-- ================================================
-- FIX VACCINES TABLE - Adiciona colunas faltantes
-- Execute este SQL PRIMEIRO, antes do vaccines_data.sql
-- ================================================

-- Adiciona coluna abbreviation se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS abbreviation TEXT;

-- Adiciona coluna description se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS description TEXT;

-- Adiciona coluna recommended_age_months se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS recommended_age_months INTEGER DEFAULT 0;

-- Adiciona coluna max_age_months se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS max_age_months INTEGER;

-- Adiciona coluna dose_number se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS dose_number INTEGER DEFAULT 1;

-- Adiciona coluna total_doses se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS total_doses INTEGER DEFAULT 1;

-- Adiciona coluna is_required se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS is_required BOOLEAN DEFAULT true;

-- Adiciona coluna category se não existir (como TEXT simples)
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'mandatory';

-- Adiciona coluna diseases_prevented se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS diseases_prevented TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Adiciona coluna created_at se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Adiciona coluna updated_at se não existir
ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ================================================
-- Verifica as colunas da tabela
-- ================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vaccines'
ORDER BY ordinal_position;
