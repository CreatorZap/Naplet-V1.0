-- ================================================
-- NAPLET - VACCINATION SCHEMA
-- Execute este SQL no Supabase para criar as tabelas de vacinação
-- ================================================

-- ================================================
-- 1. ENUM para categoria da vacina
-- ================================================
DO $$ BEGIN
    CREATE TYPE vaccine_category AS ENUM ('mandatory', 'recommended', 'optional');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ================================================
-- 2. ENUM para status da vacinação
-- ================================================
DO $$ BEGIN
    CREATE TYPE vaccination_status AS ENUM ('pending', 'completed', 'skipped');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ================================================
-- 3. TABELA VACCINES (Catálogo de vacinas)
-- ================================================
-- Se a tabela já existe, vamos adicionar as colunas que faltam
-- Primeiro, tenta criar a tabela completa
CREATE TABLE IF NOT EXISTS public.vaccines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    abbreviation TEXT,
    description TEXT,
    recommended_age_months INTEGER NOT NULL DEFAULT 0,
    max_age_months INTEGER,
    dose_number INTEGER NOT NULL DEFAULT 1,
    total_doses INTEGER NOT NULL DEFAULT 1,
    is_required BOOLEAN NOT NULL DEFAULT true,
    category vaccine_category NOT NULL DEFAULT 'mandatory',
    diseases_prevented TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Adiciona colunas que podem estar faltando (se tabela já existia)
DO $$
BEGIN
    -- abbreviation
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'abbreviation') THEN
        ALTER TABLE public.vaccines ADD COLUMN abbreviation TEXT;
    END IF;

    -- description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'description') THEN
        ALTER TABLE public.vaccines ADD COLUMN description TEXT;
    END IF;

    -- recommended_age_months
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'recommended_age_months') THEN
        ALTER TABLE public.vaccines ADD COLUMN recommended_age_months INTEGER NOT NULL DEFAULT 0;
    END IF;

    -- max_age_months
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'max_age_months') THEN
        ALTER TABLE public.vaccines ADD COLUMN max_age_months INTEGER;
    END IF;

    -- dose_number
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'dose_number') THEN
        ALTER TABLE public.vaccines ADD COLUMN dose_number INTEGER NOT NULL DEFAULT 1;
    END IF;

    -- total_doses
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'total_doses') THEN
        ALTER TABLE public.vaccines ADD COLUMN total_doses INTEGER NOT NULL DEFAULT 1;
    END IF;

    -- is_required
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'is_required') THEN
        ALTER TABLE public.vaccines ADD COLUMN is_required BOOLEAN NOT NULL DEFAULT true;
    END IF;

    -- category (como TEXT se enum não existir)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'category') THEN
        ALTER TABLE public.vaccines ADD COLUMN category vaccine_category NOT NULL DEFAULT 'mandatory';
    END IF;

    -- diseases_prevented
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'diseases_prevented') THEN
        ALTER TABLE public.vaccines ADD COLUMN diseases_prevented TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;

    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'created_at') THEN
        ALTER TABLE public.vaccines ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL;
    END IF;

    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vaccines' AND column_name = 'updated_at') THEN
        ALTER TABLE public.vaccines ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL;
    END IF;
END $$;

-- ================================================
-- 4. TABELA BABY_VACCINATIONS (Registro por bebê)
-- ================================================
CREATE TABLE IF NOT EXISTS public.baby_vaccinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
    vaccine_id UUID NOT NULL REFERENCES public.vaccines(id) ON DELETE CASCADE,
    status vaccination_status NOT NULL DEFAULT 'pending',
    application_date TIMESTAMPTZ,
    batch_number TEXT,
    location TEXT,
    health_professional TEXT,
    notes TEXT,
    reactions TEXT,
    recorded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    -- Unique constraint: um bebê só pode ter uma vacina específica uma vez
    CONSTRAINT baby_vaccinations_unique UNIQUE (baby_id, vaccine_id)
);

-- Adiciona colunas que podem estar faltando
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baby_vaccinations' AND column_name = 'batch_number') THEN
        ALTER TABLE public.baby_vaccinations ADD COLUMN batch_number TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baby_vaccinations' AND column_name = 'location') THEN
        ALTER TABLE public.baby_vaccinations ADD COLUMN location TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baby_vaccinations' AND column_name = 'health_professional') THEN
        ALTER TABLE public.baby_vaccinations ADD COLUMN health_professional TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baby_vaccinations' AND column_name = 'reactions') THEN
        ALTER TABLE public.baby_vaccinations ADD COLUMN reactions TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'baby_vaccinations' AND column_name = 'recorded_by') THEN
        ALTER TABLE public.baby_vaccinations ADD COLUMN recorded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- ================================================
-- 5. INDEXES
-- ================================================
CREATE INDEX IF NOT EXISTS idx_vaccines_age ON public.vaccines(recommended_age_months);
CREATE INDEX IF NOT EXISTS idx_vaccines_category ON public.vaccines(category);
CREATE INDEX IF NOT EXISTS idx_baby_vaccinations_baby ON public.baby_vaccinations(baby_id);
CREATE INDEX IF NOT EXISTS idx_baby_vaccinations_vaccine ON public.baby_vaccinations(vaccine_id);
CREATE INDEX IF NOT EXISTS idx_baby_vaccinations_status ON public.baby_vaccinations(status);

-- ================================================
-- 6. TRIGGERS para updated_at
-- ================================================
DROP TRIGGER IF EXISTS update_vaccines_updated_at ON public.vaccines;
CREATE TRIGGER update_vaccines_updated_at
    BEFORE UPDATE ON public.vaccines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_baby_vaccinations_updated_at ON public.baby_vaccinations;
CREATE TRIGGER update_baby_vaccinations_updated_at
    BEFORE UPDATE ON public.baby_vaccinations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ================================================

-- Habilitar RLS
ALTER TABLE public.vaccines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.baby_vaccinations ENABLE ROW LEVEL SECURITY;

-- VACCINES POLICIES (leitura pública, apenas admins podem modificar)
DROP POLICY IF EXISTS "vaccines_select_all" ON public.vaccines;
CREATE POLICY "vaccines_select_all" ON public.vaccines
    FOR SELECT USING (true);

-- BABY_VACCINATIONS POLICIES
DROP POLICY IF EXISTS "baby_vaccinations_select" ON public.baby_vaccinations;
CREATE POLICY "baby_vaccinations_select" ON public.baby_vaccinations
    FOR SELECT USING (
        user_has_baby_access(baby_id, auth.uid())
    );

DROP POLICY IF EXISTS "baby_vaccinations_insert" ON public.baby_vaccinations;
CREATE POLICY "baby_vaccinations_insert" ON public.baby_vaccinations
    FOR INSERT WITH CHECK (
        user_has_baby_access(baby_id, auth.uid())
    );

DROP POLICY IF EXISTS "baby_vaccinations_update" ON public.baby_vaccinations;
CREATE POLICY "baby_vaccinations_update" ON public.baby_vaccinations
    FOR UPDATE USING (
        user_has_baby_access(baby_id, auth.uid())
    );

DROP POLICY IF EXISTS "baby_vaccinations_delete" ON public.baby_vaccinations;
CREATE POLICY "baby_vaccinations_delete" ON public.baby_vaccinations
    FOR DELETE USING (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- ================================================
-- 8. FUNÇÃO para inicializar vacinações de um bebê
-- ================================================
CREATE OR REPLACE FUNCTION initialize_baby_vaccinations(p_baby_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Insere registro de vacinação para cada vacina que o bebê ainda não tem
    INSERT INTO public.baby_vaccinations (baby_id, vaccine_id, status)
    SELECT p_baby_id, v.id, 'pending'
    FROM public.vaccines v
    WHERE NOT EXISTS (
        SELECT 1 FROM public.baby_vaccinations bv
        WHERE bv.baby_id = p_baby_id AND bv.vaccine_id = v.id
    );

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- FIM DO SCHEMA DE VACINAÇÃO
-- ================================================
-- Após executar este SQL, execute o supabase_vaccines_data.sql
-- para popular as vacinas do calendário brasileiro.
-- ================================================
