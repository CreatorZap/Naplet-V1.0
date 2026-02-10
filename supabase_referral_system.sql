-- =====================================================
-- SISTEMA DE INDICAÇÃO (REFERRAL) - NAPLET
-- Execute este SQL no Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. TABELA DE CÓDIGOS DE INDICAÇÃO
-- =====================================================

CREATE TABLE IF NOT EXISTS public.referral_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    code VARCHAR(8) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Índice para busca rápida por código
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON public.referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_codes_user_id ON public.referral_codes(user_id);

-- Comentários
COMMENT ON TABLE public.referral_codes IS 'Códigos únicos de indicação para cada usuário';
COMMENT ON COLUMN public.referral_codes.code IS 'Código de 6 caracteres alfanumérico';

-- =====================================================
-- 2. TABELA DE INDICAÇÕES REALIZADAS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    referred_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    referral_code VARCHAR(8) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'converted', 'expired')),
    converted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    CONSTRAINT fk_referral_code FOREIGN KEY (referral_code)
        REFERENCES public.referral_codes(code) ON DELETE CASCADE
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals(referred_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals(status);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);

-- Comentários
COMMENT ON TABLE public.referrals IS 'Registro de indicações entre usuários';
COMMENT ON COLUMN public.referrals.status IS 'Status: pending (aguardando), converted (convertida), expired (expirada)';

-- =====================================================
-- 3. ADICIONAR CAMPOS NA TABELA PROFILES
-- =====================================================

-- Adicionar campos de referral ao perfil do usuário
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS
    referred_by_code VARCHAR(8);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS
    is_ambassador BOOLEAN DEFAULT false;

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS
    ambassador_since TIMESTAMPTZ;

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS
    total_referrals INT DEFAULT 0;

-- Comentários
COMMENT ON COLUMN public.profiles.referred_by_code IS 'Código de quem indicou este usuário';
COMMENT ON COLUMN public.profiles.is_ambassador IS 'Se tem badge de Embaixadora (5+ indicações)';
COMMENT ON COLUMN public.profiles.ambassador_since IS 'Data em que virou embaixadora';
COMMENT ON COLUMN public.profiles.total_referrals IS 'Total de indicações convertidas';

-- =====================================================
-- 4. HABILITAR RLS (Row Level Security)
-- =====================================================

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. POLÍTICAS RLS PARA referral_codes
-- =====================================================

-- Usuários podem ver seu próprio código
DROP POLICY IF EXISTS "Users can view own referral code" ON public.referral_codes;
CREATE POLICY "Users can view own referral code" ON public.referral_codes
FOR SELECT USING (auth.uid() = user_id);

-- Qualquer um pode validar códigos (para buscar ao cadastrar)
DROP POLICY IF EXISTS "Anyone can validate referral codes" ON public.referral_codes;
CREATE POLICY "Anyone can validate referral codes" ON public.referral_codes
FOR SELECT USING (true);

-- Sistema pode criar códigos
DROP POLICY IF EXISTS "System can create referral codes" ON public.referral_codes;
CREATE POLICY "System can create referral codes" ON public.referral_codes
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 6. POLÍTICAS RLS PARA referrals
-- =====================================================

-- Usuários podem ver indicações onde são referrer ou referred
DROP POLICY IF EXISTS "Users can view own referrals" ON public.referrals;
CREATE POLICY "Users can view own referrals" ON public.referrals
FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- Sistema pode criar indicações
DROP POLICY IF EXISTS "System can create referrals" ON public.referrals;
CREATE POLICY "System can create referrals" ON public.referrals
FOR INSERT WITH CHECK (true);

-- Sistema pode atualizar indicações
DROP POLICY IF EXISTS "System can update referrals" ON public.referrals;
CREATE POLICY "System can update referrals" ON public.referrals
FOR UPDATE USING (true);

-- =====================================================
-- 7. FUNÇÃO PARA GERAR CÓDIGO ALEATÓRIO
-- =====================================================

CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS VARCHAR(8) AS $$
DECLARE
    -- Caracteres sem ambiguidade (sem 0, O, 1, I, L)
    chars VARCHAR(36) := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result VARCHAR(8) := '';
    i INT;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_referral_code() IS 'Gera código de 6 caracteres alfanumérico único';

-- =====================================================
-- 8. FUNÇÃO PARA CRIAR CÓDIGO PARA NOVO USUÁRIO
-- =====================================================

CREATE OR REPLACE FUNCTION create_user_referral_code()
RETURNS TRIGGER AS $$
DECLARE
    new_code VARCHAR(8);
    code_exists BOOLEAN;
BEGIN
    -- Gerar código único
    LOOP
        new_code := generate_referral_code();
        SELECT EXISTS(SELECT 1 FROM public.referral_codes WHERE code = new_code) INTO code_exists;
        EXIT WHEN NOT code_exists;
    END LOOP;

    -- Inserir código para o usuário
    INSERT INTO public.referral_codes (user_id, code)
    VALUES (NEW.id, new_code)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_user_referral_code() IS 'Trigger function que cria código de referral para novo usuário';

-- =====================================================
-- 9. TRIGGER PARA CRIAR CÓDIGO AUTOMATICAMENTE
-- =====================================================

-- Remover trigger se existir
DROP TRIGGER IF EXISTS on_profile_created_referral ON public.profiles;

-- Criar trigger
CREATE TRIGGER on_profile_created_referral
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_user_referral_code();

-- =====================================================
-- 10. FUNÇÃO PARA PROCESSAR INDICAÇÃO CONVERTIDA
-- =====================================================

CREATE OR REPLACE FUNCTION process_referral_conversion(
    p_referred_user_id UUID,
    p_referral_code VARCHAR(8)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_referrer_id UUID;
    v_total INT;
    v_already_referred BOOLEAN;
BEGIN
    -- Verificar se já foi indicado antes
    SELECT EXISTS(
        SELECT 1 FROM public.referrals WHERE referred_id = p_referred_user_id
    ) INTO v_already_referred;

    IF v_already_referred THEN
        RETURN FALSE; -- Já foi indicado
    END IF;

    -- Buscar quem indicou
    SELECT user_id INTO v_referrer_id
    FROM public.referral_codes
    WHERE code = UPPER(p_referral_code);

    IF v_referrer_id IS NULL THEN
        RETURN FALSE; -- Código não existe
    END IF;

    -- Não pode se auto-indicar
    IF v_referrer_id = p_referred_user_id THEN
        RETURN FALSE;
    END IF;

    -- Criar registro de indicação
    INSERT INTO public.referrals (referrer_id, referred_id, referral_code, status, converted_at)
    VALUES (v_referrer_id, p_referred_user_id, UPPER(p_referral_code), 'converted', NOW())
    ON CONFLICT (referred_id) DO NOTHING;

    -- Atualizar contador do referrer
    UPDATE public.profiles
    SET total_referrals = COALESCE(total_referrals, 0) + 1
    WHERE id = v_referrer_id;

    -- Verificar se virou embaixadora (5+ indicações)
    SELECT COALESCE(total_referrals, 0) INTO v_total
    FROM public.profiles
    WHERE id = v_referrer_id;

    IF v_total >= 5 THEN
        UPDATE public.profiles
        SET is_ambassador = true, ambassador_since = NOW()
        WHERE id = v_referrer_id AND (is_ambassador = false OR is_ambassador IS NULL);
    END IF;

    -- Marcar no perfil do indicado quem indicou
    UPDATE public.profiles
    SET referred_by_code = UPPER(p_referral_code)
    WHERE id = p_referred_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION process_referral_conversion(UUID, VARCHAR) IS 'Processa uma indicação quando usuário se cadastra com código';

-- =====================================================
-- 11. CRIAR CÓDIGOS PARA USUÁRIOS EXISTENTES
-- =====================================================

-- Criar códigos para usuários que ainda não têm
DO $$
DECLARE
    user_record RECORD;
    new_code VARCHAR(8);
    code_exists BOOLEAN;
BEGIN
    FOR user_record IN
        SELECT p.id
        FROM public.profiles p
        LEFT JOIN public.referral_codes rc ON p.id = rc.user_id
        WHERE rc.id IS NULL
    LOOP
        -- Gerar código único
        LOOP
            new_code := generate_referral_code();
            SELECT EXISTS(SELECT 1 FROM public.referral_codes WHERE code = new_code) INTO code_exists;
            EXIT WHEN NOT code_exists;
        END LOOP;

        -- Inserir código
        INSERT INTO public.referral_codes (user_id, code)
        VALUES (user_record.id, new_code)
        ON CONFLICT (user_id) DO NOTHING;
    END LOOP;
END $$;

-- =====================================================
-- 12. GRANT PERMISSIONS
-- =====================================================

GRANT SELECT ON public.referral_codes TO authenticated;
GRANT INSERT ON public.referral_codes TO authenticated;
GRANT SELECT ON public.referrals TO authenticated;
GRANT INSERT ON public.referrals TO authenticated;
GRANT UPDATE ON public.referrals TO authenticated;
GRANT EXECUTE ON FUNCTION process_referral_conversion(UUID, VARCHAR) TO authenticated;

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se as tabelas foram criadas
SELECT 'referral_codes' as table_name, COUNT(*) as row_count FROM public.referral_codes
UNION ALL
SELECT 'referrals' as table_name, COUNT(*) as row_count FROM public.referrals;

-- Mostrar colunas adicionadas em profiles
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
AND column_name IN ('referred_by_code', 'is_ambassador', 'ambassador_since', 'total_referrals');
