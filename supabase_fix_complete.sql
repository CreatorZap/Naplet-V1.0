-- ============================================
-- FIX COMPLETO: Corrigir TODAS as RLS Policies
-- ============================================

-- PASSO 1: REMOVER TODAS AS POLICIES PROBLEMÁTICAS
DROP POLICY IF EXISTS "babies_owner_all" ON public.babies;
DROP POLICY IF EXISTS "babies_caregiver_select" ON public.babies;
DROP POLICY IF EXISTS "caregivers_select" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_insert" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_owner_delete" ON public.caregivers;
DROP POLICY IF EXISTS "caregivers_self_update" ON public.caregivers;
DROP POLICY IF EXISTS "sleep_records_select" ON public.sleep_records;
DROP POLICY IF EXISTS "sleep_records_insert" ON public.sleep_records;
DROP POLICY IF EXISTS "sleep_records_update" ON public.sleep_records;
DROP POLICY IF EXISTS "sleep_records_delete" ON public.sleep_records;
DROP POLICY IF EXISTS "night_wakings_select" ON public.night_wakings;
DROP POLICY IF EXISTS "night_wakings_insert" ON public.night_wakings;
DROP POLICY IF EXISTS "night_wakings_update" ON public.night_wakings;
DROP POLICY IF EXISTS "night_wakings_delete" ON public.night_wakings;

-- PASSO 2: RECRIAR POLICIES DE BABIES
CREATE POLICY "babies_owner_all" ON public.babies 
    FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "babies_caregiver_select" ON public.babies 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.caregivers c 
            WHERE c.baby_id = id 
              AND c.user_id = auth.uid() 
              AND c.accepted_at IS NOT NULL
        )
    );

-- PASSO 3: RECRIAR POLICIES DE CAREGIVERS (sem recursão)
CREATE POLICY "caregivers_select" ON public.caregivers 
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
        OR user_id = auth.uid()
    );

CREATE POLICY "caregivers_owner_insert" ON public.caregivers 
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

CREATE POLICY "caregivers_owner_delete" ON public.caregivers 
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

CREATE POLICY "caregivers_self_update" ON public.caregivers 
    FOR UPDATE USING (user_id = auth.uid());

-- PASSO 4: RECRIAR POLICIES DE SLEEP_RECORDS (SEM user_has_baby_access)
CREATE POLICY "sleep_records_select" ON public.sleep_records 
    FOR SELECT USING (
        -- É dono do bebê
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
        OR
        -- É cuidador aceito do bebê
        EXISTS (SELECT 1 FROM public.caregivers c WHERE c.baby_id = baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL)
    );

CREATE POLICY "sleep_records_insert" ON public.sleep_records 
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
        OR
        EXISTS (SELECT 1 FROM public.caregivers c WHERE c.baby_id = baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL)
    );

CREATE POLICY "sleep_records_update" ON public.sleep_records 
    FOR UPDATE USING (
        recorded_by = auth.uid()
        OR EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

CREATE POLICY "sleep_records_delete" ON public.sleep_records 
    FOR DELETE USING (
        recorded_by = auth.uid()
        OR EXISTS (SELECT 1 FROM public.babies b WHERE b.id = baby_id AND b.owner_id = auth.uid())
    );

-- PASSO 5: RECRIAR POLICIES DE NIGHT_WAKINGS (SEM user_has_baby_access)
CREATE POLICY "night_wakings_select" ON public.night_wakings 
    FOR SELECT USING (
        sleep_record_id IN (
            SELECT sr.id FROM public.sleep_records sr
            WHERE EXISTS (SELECT 1 FROM public.babies b WHERE b.id = sr.baby_id AND b.owner_id = auth.uid())
               OR EXISTS (SELECT 1 FROM public.caregivers c WHERE c.baby_id = sr.baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL)
        )
    );

CREATE POLICY "night_wakings_insert" ON public.night_wakings 
    FOR INSERT WITH CHECK (
        sleep_record_id IN (
            SELECT sr.id FROM public.sleep_records sr
            WHERE EXISTS (SELECT 1 FROM public.babies b WHERE b.id = sr.baby_id AND b.owner_id = auth.uid())
               OR EXISTS (SELECT 1 FROM public.caregivers c WHERE c.baby_id = sr.baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL)
        )
    );

CREATE POLICY "night_wakings_update" ON public.night_wakings 
    FOR UPDATE USING (
        sleep_record_id IN (
            SELECT sr.id FROM public.sleep_records sr
            WHERE sr.recorded_by = auth.uid()
               OR EXISTS (SELECT 1 FROM public.babies b WHERE b.id = sr.baby_id AND b.owner_id = auth.uid())
        )
    );

CREATE POLICY "night_wakings_delete" ON public.night_wakings 
    FOR DELETE USING (
        sleep_record_id IN (
            SELECT sr.id FROM public.sleep_records sr
            WHERE sr.recorded_by = auth.uid()
               OR EXISTS (SELECT 1 FROM public.babies b WHERE b.id = sr.baby_id AND b.owner_id = auth.uid())
        )
    );

-- FIM DO FIX COMPLETO
