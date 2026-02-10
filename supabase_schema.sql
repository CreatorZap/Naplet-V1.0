-- ============================================
-- NAPLET - SUPABASE DATABASE SCHEMA
-- ============================================
-- Execute este SQL no Supabase Dashboard:
-- SQL Editor → New Query → Cole e Execute
-- ============================================

-- ============================================
-- 1. EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. CUSTOM TYPES (ENUMS)
-- ============================================

-- Gênero do bebê
CREATE TYPE baby_gender AS ENUM ('male', 'female', 'other');

-- Tipo de sono
CREATE TYPE sleep_type AS ENUM ('nap', 'night');

-- Qualidade do sono
CREATE TYPE sleep_quality AS ENUM ('good', 'restless', 'difficult');

-- Motivo do despertar noturno
CREATE TYPE waking_reason AS ENUM ('feeding', 'diaper', 'comfort', 'unknown');

-- Role do cuidador
CREATE TYPE caregiver_role AS ENUM ('owner', 'parent', 'grandparent', 'nanny', 'other');

-- Status do convite
CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'expired', 'cancelled');

-- Status da assinatura
CREATE TYPE subscription_status AS ENUM ('free', 'premium', 'trial');

-- ============================================
-- 3. TABLES
-- ============================================

-- -----------------------------------------
-- PROFILES (extends auth.users)
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    subscription_status subscription_status DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
    timezone TEXT DEFAULT 'America/Sao_Paulo',
    locale TEXT DEFAULT 'pt-BR',
    notification_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index para busca por email
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- -----------------------------------------
-- BABIES
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.babies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    birth_date DATE NOT NULL,
    gender baby_gender,
    photo_url TEXT,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT babies_name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 100)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_babies_owner ON public.babies(owner_id);
CREATE INDEX IF NOT EXISTS idx_babies_created ON public.babies(created_at DESC);

-- -----------------------------------------
-- CAREGIVERS (many-to-many: users <-> babies)
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role caregiver_role NOT NULL DEFAULT 'other',
    display_name TEXT,
    invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Unique constraint: um usuário só pode ser cuidador de um bebê uma vez
    CONSTRAINT caregivers_unique_user_baby UNIQUE (baby_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_caregivers_baby ON public.caregivers(baby_id);
CREATE INDEX IF NOT EXISTS idx_caregivers_user ON public.caregivers(user_id);

-- -----------------------------------------
-- INVITES (convites para cuidadores)
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
    invited_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL UNIQUE,
    email TEXT, -- Email do convidado (opcional)
    role caregiver_role NOT NULL DEFAULT 'other',
    status invite_status DEFAULT 'pending',
    accepted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invites_code ON public.invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_invites_baby ON public.invites(baby_id);
CREATE INDEX IF NOT EXISTS idx_invites_status ON public.invites(status) WHERE status = 'pending';

-- -----------------------------------------
-- SLEEP RECORDS
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.sleep_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
    type sleep_type NOT NULL DEFAULT 'nap',
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    quality sleep_quality,
    notes TEXT,
    recorded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT sleep_records_time_check CHECK (end_time IS NULL OR end_time > start_time),
    CONSTRAINT sleep_records_notes_length CHECK (notes IS NULL OR char_length(notes) <= 500)
);

-- Indexes para queries frequentes
CREATE INDEX IF NOT EXISTS idx_sleep_baby ON public.sleep_records(baby_id);
CREATE INDEX IF NOT EXISTS idx_sleep_baby_start ON public.sleep_records(baby_id, start_time DESC);
-- Índice composto para filtros por range de data (usa start_time diretamente)
-- Queries devem filtrar: WHERE baby_id = ? AND start_time >= ? AND start_time < ?
CREATE INDEX IF NOT EXISTS idx_sleep_baby_start_asc ON public.sleep_records(baby_id, start_time);
CREATE INDEX IF NOT EXISTS idx_sleep_active ON public.sleep_records(baby_id, end_time) WHERE end_time IS NULL;
CREATE INDEX IF NOT EXISTS idx_sleep_recorded_by ON public.sleep_records(recorded_by);

-- -----------------------------------------
-- NIGHT WAKINGS (dentro de um sleep_record)
-- -----------------------------------------
CREATE TABLE IF NOT EXISTS public.night_wakings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleep_record_id UUID NOT NULL REFERENCES public.sleep_records(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    reason waking_reason,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index
CREATE INDEX IF NOT EXISTS idx_wakings_record ON public.night_wakings(sleep_record_id);

-- ============================================
-- 4. FUNCTIONS
-- ============================================

-- -----------------------------------------
-- Função para atualizar updated_at
-- -----------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------
-- Função para criar profile ao signup
-- -----------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------
-- Função para gerar invite code
-- -----------------------------------------
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists_count INTEGER;
BEGIN
    LOOP
        -- Gera código de 8 caracteres alfanuméricos
        code := upper(substring(md5(random()::text) from 1 for 8));
        
        -- Verifica se já existe
        SELECT COUNT(*) INTO exists_count FROM public.invites WHERE invite_code = code;
        
        -- Se não existe, retorna
        IF exists_count = 0 THEN
            RETURN code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------
-- Função para verificar acesso ao bebê
-- -----------------------------------------
CREATE OR REPLACE FUNCTION user_has_baby_access(baby_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.babies WHERE id = baby_uuid AND owner_id = user_uuid
        UNION
        SELECT 1 FROM public.caregivers WHERE baby_id = baby_uuid AND user_id = user_uuid AND accepted_at IS NOT NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. TRIGGERS
-- ============================================

-- Trigger para profiles.updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para babies.updated_at
DROP TRIGGER IF EXISTS update_babies_updated_at ON public.babies;
CREATE TRIGGER update_babies_updated_at
    BEFORE UPDATE ON public.babies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para caregivers.updated_at
DROP TRIGGER IF EXISTS update_caregivers_updated_at ON public.caregivers;
CREATE TRIGGER update_caregivers_updated_at
    BEFORE UPDATE ON public.caregivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para invites.updated_at
DROP TRIGGER IF EXISTS update_invites_updated_at ON public.invites;
CREATE TRIGGER update_invites_updated_at
    BEFORE UPDATE ON public.invites
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para sleep_records.updated_at
DROP TRIGGER IF EXISTS update_sleep_records_updated_at ON public.sleep_records;
CREATE TRIGGER update_sleep_records_updated_at
    BEFORE UPDATE ON public.sleep_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para criar profile automaticamente no signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.night_wakings ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------
-- PROFILES POLICIES
-- -----------------------------------------
-- Usuários podem ver seu próprio perfil
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Usuários podem atualizar seu próprio perfil
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Usuários podem ver perfis de co-cuidadores dos seus bebês
CREATE POLICY "profiles_select_co_caregivers" ON public.profiles
    FOR SELECT USING (
        id IN (
            SELECT DISTINCT c.user_id 
            FROM public.caregivers c
            WHERE c.baby_id IN (
                SELECT baby_id FROM public.caregivers WHERE user_id = auth.uid()
            )
        )
    );

-- -----------------------------------------
-- BABIES POLICIES
-- -----------------------------------------
-- Donos podem fazer tudo com seus bebês
CREATE POLICY "babies_owner_all" ON public.babies
    FOR ALL USING (owner_id = auth.uid());

-- Cuidadores podem ver bebês que cuidam
CREATE POLICY "babies_caregiver_select" ON public.babies
    FOR SELECT USING (
        id IN (
            SELECT baby_id FROM public.caregivers 
            WHERE user_id = auth.uid() AND accepted_at IS NOT NULL
        )
    );

-- -----------------------------------------
-- CAREGIVERS POLICIES
-- -----------------------------------------
-- Ver cuidadores dos bebês que você é dono ou cuidador
CREATE POLICY "caregivers_select" ON public.caregivers
    FOR SELECT USING (
        user_has_baby_access(baby_id, auth.uid())
    );

-- Dono do bebê pode inserir/deletar cuidadores
CREATE POLICY "caregivers_owner_insert" ON public.caregivers
    FOR INSERT WITH CHECK (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

CREATE POLICY "caregivers_owner_delete" ON public.caregivers
    FOR DELETE USING (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- Cuidador pode atualizar seu próprio registro (ex: accepted_at)
CREATE POLICY "caregivers_self_update" ON public.caregivers
    FOR UPDATE USING (user_id = auth.uid());

-- -----------------------------------------
-- INVITES POLICIES
-- -----------------------------------------
-- Ver convites dos seus bebês ou para você
CREATE POLICY "invites_select" ON public.invites
    FOR SELECT USING (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
        OR email = (SELECT email FROM public.profiles WHERE id = auth.uid())
    );

-- Criar convites apenas para bebês que você é dono
CREATE POLICY "invites_insert" ON public.invites
    FOR INSERT WITH CHECK (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- Atualizar convites (aceitar/cancelar)
CREATE POLICY "invites_update" ON public.invites
    FOR UPDATE USING (
        -- Dono pode cancelar
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
        OR
        -- Convidado pode aceitar
        email = (SELECT email FROM public.profiles WHERE id = auth.uid())
    );

-- -----------------------------------------
-- SLEEP RECORDS POLICIES
-- -----------------------------------------
-- Quem tem acesso ao bebê pode ver registros
CREATE POLICY "sleep_records_select" ON public.sleep_records
    FOR SELECT USING (
        user_has_baby_access(baby_id, auth.uid())
    );

-- Quem tem acesso ao bebê pode criar registros
CREATE POLICY "sleep_records_insert" ON public.sleep_records
    FOR INSERT WITH CHECK (
        user_has_baby_access(baby_id, auth.uid())
    );

-- Quem criou ou é dono do bebê pode atualizar
CREATE POLICY "sleep_records_update" ON public.sleep_records
    FOR UPDATE USING (
        recorded_by = auth.uid()
        OR baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- Quem criou ou é dono do bebê pode deletar
CREATE POLICY "sleep_records_delete" ON public.sleep_records
    FOR DELETE USING (
        recorded_by = auth.uid()
        OR baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- -----------------------------------------
-- NIGHT WAKINGS POLICIES
-- -----------------------------------------
-- Baseado no acesso ao sleep_record pai
CREATE POLICY "night_wakings_select" ON public.night_wakings
    FOR SELECT USING (
        sleep_record_id IN (
            SELECT id FROM public.sleep_records 
            WHERE user_has_baby_access(baby_id, auth.uid())
        )
    );

CREATE POLICY "night_wakings_insert" ON public.night_wakings
    FOR INSERT WITH CHECK (
        sleep_record_id IN (
            SELECT id FROM public.sleep_records 
            WHERE user_has_baby_access(baby_id, auth.uid())
        )
    );

CREATE POLICY "night_wakings_update" ON public.night_wakings
    FOR UPDATE USING (
        sleep_record_id IN (
            SELECT id FROM public.sleep_records sr
            WHERE sr.recorded_by = auth.uid()
               OR sr.baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
        )
    );

CREATE POLICY "night_wakings_delete" ON public.night_wakings
    FOR DELETE USING (
        sleep_record_id IN (
            SELECT id FROM public.sleep_records sr
            WHERE sr.recorded_by = auth.uid()
               OR sr.baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
        )
    );

-- ============================================
-- 7. VIEWS (para queries comuns)
-- ============================================

-- View de bebês com estatísticas básicas
CREATE OR REPLACE VIEW public.babies_with_stats AS
SELECT 
    b.*,
    (SELECT COUNT(*) FROM public.sleep_records sr WHERE sr.baby_id = b.id) as total_records,
    (SELECT COUNT(*) FROM public.caregivers c WHERE c.baby_id = b.id AND c.accepted_at IS NOT NULL) as caregiver_count
FROM public.babies b;

-- View de sono de hoje
CREATE OR REPLACE VIEW public.todays_sleep AS
SELECT 
    sr.*,
    b.name as baby_name,
    EXTRACT(EPOCH FROM COALESCE(sr.end_time, NOW()) - sr.start_time) as duration_seconds
FROM public.sleep_records sr
JOIN public.babies b ON b.id = sr.baby_id
WHERE DATE(sr.start_time) = CURRENT_DATE;

-- ============================================
-- 8. SAMPLE FUNCTIONS (para o app chamar)
-- ============================================

-- Função RPC para buscar sono ativo
CREATE OR REPLACE FUNCTION get_active_sleep(p_baby_id UUID)
RETURNS TABLE (
    id UUID,
    baby_id UUID,
    type sleep_type,
    start_time TIMESTAMPTZ,
    recorded_by UUID,
    duration_seconds DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sr.id,
        sr.baby_id,
        sr.type,
        sr.start_time,
        sr.recorded_by,
        EXTRACT(EPOCH FROM NOW() - sr.start_time) as duration_seconds
    FROM public.sleep_records sr
    WHERE sr.baby_id = p_baby_id 
      AND sr.end_time IS NULL
    ORDER BY sr.start_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função RPC para estatísticas diárias
CREATE OR REPLACE FUNCTION get_daily_stats(p_baby_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    total_sleep_seconds DOUBLE PRECISION,
    nap_count BIGINT,
    night_sleep_seconds DOUBLE PRECISION,
    average_nap_seconds DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(EXTRACT(EPOCH FROM COALESCE(sr.end_time, NOW()) - sr.start_time)), 0) as total_sleep_seconds,
        COUNT(*) FILTER (WHERE sr.type = 'nap') as nap_count,
        COALESCE(SUM(EXTRACT(EPOCH FROM COALESCE(sr.end_time, NOW()) - sr.start_time)) FILTER (WHERE sr.type = 'night'), 0) as night_sleep_seconds,
        COALESCE(AVG(EXTRACT(EPOCH FROM COALESCE(sr.end_time, NOW()) - sr.start_time)) FILTER (WHERE sr.type = 'nap'), 0) as average_nap_seconds
    FROM public.sleep_records sr
    WHERE sr.baby_id = p_baby_id 
      AND DATE(sr.start_time) = p_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para aceitar convite
CREATE OR REPLACE FUNCTION accept_invite(p_invite_code TEXT)
RETURNS JSON AS $$
DECLARE
    v_invite RECORD;
    v_user_id UUID;
    v_caregiver_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Not authenticated');
    END IF;
    
    -- Buscar convite válido
    SELECT * INTO v_invite
    FROM public.invites
    WHERE invite_code = p_invite_code
      AND status = 'pending'
      AND expires_at > NOW();
    
    IF v_invite IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Invalid or expired invite code');
    END IF;
    
    -- Verificar se já é cuidador
    IF EXISTS (SELECT 1 FROM public.caregivers WHERE baby_id = v_invite.baby_id AND user_id = v_user_id) THEN
        RETURN json_build_object('success', false, 'error', 'You are already a caregiver for this baby');
    END IF;
    
    -- Criar caregiver
    INSERT INTO public.caregivers (baby_id, user_id, role, invited_by, accepted_at)
    VALUES (v_invite.baby_id, v_user_id, v_invite.role, v_invite.invited_by, NOW())
    RETURNING id INTO v_caregiver_id;
    
    -- Atualizar convite
    UPDATE public.invites
    SET status = 'accepted', accepted_by = v_user_id, updated_at = NOW()
    WHERE id = v_invite.id;
    
    RETURN json_build_object(
        'success', true, 
        'caregiver_id', v_caregiver_id,
        'baby_id', v_invite.baby_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FIM DO SCHEMA
-- ============================================
-- Próximos passos:
-- 1. Execute este SQL no Supabase Dashboard
-- 2. Configure as variáveis de ambiente no app
-- 3. Teste as políticas RLS
-- ============================================
