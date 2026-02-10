-- ============================================
-- FIX: Remover recursão infinita nas RLS Policies
-- ============================================
-- Execute este SQL no Supabase Dashboard → SQL Editor
-- ============================================

-- 1. Dropar policies problemáticas
DROP POLICY IF EXISTS "babies_caregiver_select" ON public.babies;
DROP POLICY IF EXISTS "caregivers_select" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_insert" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_delete" ON public.caregivers;

-- 2. Recriar função user_has_baby_access SEM depender de RLS
-- (já tem SECURITY DEFINER, mas vamos garantir que está correto)
CREATE OR REPLACE FUNCTION user_has_baby_access(baby_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    has_access BOOLEAN;
BEGIN
    -- Verificar se é dono do bebê (direto, sem policy)
    SELECT EXISTS (
        SELECT 1 FROM public.babies b
        WHERE b.id = baby_uuid AND b.owner_id = user_uuid
    ) INTO has_access;
    
    IF has_access THEN
        RETURN TRUE;
    END IF;
    
    -- Verificar se é cuidador aceito (direto, sem policy)
    SELECT EXISTS (
        SELECT 1 FROM public.caregivers c
        WHERE c.baby_id = baby_uuid 
          AND c.user_id = user_uuid 
          AND c.accepted_at IS NOT NULL
    ) INTO has_access;
    
    RETURN has_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Recriar policy de babies para cuidadores (usando subquery simples)
-- Esta policy NÃO pode referenciar caregivers de forma que acione policies de caregivers
CREATE POLICY "babies_caregiver_select" ON public.babies
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = babies.id 
              AND c.user_id = auth.uid() 
              AND c.accepted_at IS NOT NULL
        )
    );

-- 4. Recriar policies de caregivers SEM usar user_has_baby_access
-- Usar verificação direta ao invés de função que causa recursão

-- Ver cuidadores: pode ver se é dono do bebê OU se é o próprio cuidador
CREATE POLICY "caregivers_select" ON public.caregivers
    FOR SELECT USING (
        -- É dono do bebê
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
        OR
        -- É o próprio cuidador
        user_id = auth.uid()
    );

-- Dono do bebê pode inserir cuidadores
CREATE POLICY "caregivers_owner_insert" ON public.caregivers
    FOR INSERT WITH CHECK (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- Dono do bebê pode deletar cuidadores
CREATE POLICY "caregivers_owner_delete" ON public.caregivers
    FOR DELETE USING (
        baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    );

-- ============================================
-- FIM DO FIX
-- ============================================
