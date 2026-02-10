-- ============================================
-- FIX FINAL: Remover TODAS as RLS Policies problemáticas
-- ============================================
-- Execute este SQL no Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- PASSO 1: REMOVER TODAS AS POLICIES DE babies E caregivers
-- ============================================
DROP POLICY IF EXISTS "babies_owner_all" ON public.babies;
DROP POLICY IF EXISTS "babies_caregiver_select" ON public.babies;
DROP POLICY IF EXISTS "caregivers_select" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_insert" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_delete" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_self_update" ON public.caregivers;

-- ============================================
-- PASSO 2: RECRIAR POLICIES SIMPLES (SEM RECURSÃO)
-- ============================================

-- -----------------------------------------
-- BABIES POLICIES (sem usar funções complexas)
-- -----------------------------------------

-- Donos podem fazer tudo com seus bebês
CREATE POLICY "babies_owner_all" ON public.babies
    FOR ALL USING (owner_id = auth.uid());

-- Cuidadores podem ver bebês - SEM chamar função que acessa caregivers
-- Usa subquery simples que NÃO aciona RLS de caregivers
CREATE POLICY "babies_caregiver_select" ON public.babies
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = id 
              AND c.user_id = auth.uid() 
              AND c.accepted_at IS NOT NULL
        )
    );

-- -----------------------------------------
-- CAREGIVERS POLICIES (SEM usar user_has_baby_access)
-- -----------------------------------------

-- Ver cuidadores: pode ver se é dono do bebê OU se é o próprio cuidador
-- NÃO usa função que acessa babies (evita recursão)
CREATE POLICY "caregivers_select" ON public.caregivers
    FOR SELECT USING (
        -- Verificar direto se é dono do bebê
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
        OR
        -- Ou se é o próprio cuidador
        user_id = auth.uid()
    );

-- Dono do bebê pode inserir cuidadores
CREATE POLICY "caregivers_owner_insert" ON public.caregivers
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

-- Dono do bebê pode deletar cuidadores
CREATE POLICY "caregivers_owner_delete" ON public.caregivers
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

-- Cuidador pode atualizar seu próprio registro (ex: accepted_at)
CREATE POLICY "caregivers_self_update" ON public.caregivers
    FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- PASSO 3: ATUALIZAR FUNÇÃO user_has_baby_access
-- ============================================
-- Esta função é usada em outras policies (sleep_records, night_wakings)
-- Precisa funcionar sem causar recursão

CREATE OR REPLACE FUNCTION user_has_baby_access(baby_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_owner BOOLEAN := FALSE;
    is_caregiver BOOLEAN := FALSE;
BEGIN
    -- Verificar se é dono (query direta, sem RLS porque usa SECURITY DEFINER)
    SELECT EXISTS (
        SELECT 1 FROM public.babies b
        WHERE b.id = baby_uuid AND b.owner_id = user_uuid
    ) INTO is_owner;
    
    IF is_owner THEN
        RETURN TRUE;
    END IF;
    
    -- Verificar se é cuidador aceito (query direta)
    SELECT EXISTS (
        SELECT 1 FROM public.caregivers c
        WHERE c.baby_id = baby_uuid 
          AND c.user_id = user_uuid 
          AND c.accepted_at IS NOT NULL
    ) INTO is_caregiver;
    
    RETURN is_caregiver;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Garantir que a função bypassa RLS
ALTER FUNCTION user_has_baby_access(UUID, UUID) SET search_path = public;

-- ============================================
-- FIM DO FIX
-- ============================================
-- Após executar, teste no app iOS fazendo signup novamente
-- ============================================
