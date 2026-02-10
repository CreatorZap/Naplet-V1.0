-- ============================================
-- FIX NUCLEAR: Desabilitar RLS e recriar tudo
-- ============================================

-- PASSO 1: DESABILITAR RLS EM TODAS AS TABELAS
ALTER TABLE public.babies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.night_wakings DISABLE ROW LEVEL SECURITY;

-- PASSO 2: REMOVER TODAS AS POLICIES EXISTENTES
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.' || r.tablename;
    END LOOP;
END $$;

-- PASSO 3: REABILITAR RLS
ALTER TABLE public.babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.night_wakings ENABLE ROW LEVEL SECURITY;

-- PASSO 4: CRIAR POLICIES SIMPLES (sem funções, sem recursão)

-- BABIES: dono tem acesso total
CREATE POLICY "babies_owner" ON public.babies FOR ALL USING (owner_id = auth.uid());

-- CAREGIVERS: dono do bebê ou o próprio cuidador pode ver
CREATE POLICY "caregivers_view" ON public.caregivers FOR SELECT USING (
    user_id = auth.uid() 
    OR baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
);
CREATE POLICY "caregivers_insert" ON public.caregivers FOR INSERT WITH CHECK (
    baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
);
CREATE POLICY "caregivers_update" ON public.caregivers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "caregivers_delete" ON public.caregivers FOR DELETE USING (
    baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
);

-- SLEEP_RECORDS: dono do bebê tem acesso
CREATE POLICY "sleep_owner" ON public.sleep_records FOR ALL USING (
    baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
);

-- NIGHT_WAKINGS: dono do bebê tem acesso
CREATE POLICY "wakings_owner" ON public.night_wakings FOR ALL USING (
    sleep_record_id IN (
        SELECT id FROM public.sleep_records 
        WHERE baby_id IN (SELECT id FROM public.babies WHERE owner_id = auth.uid())
    )
);

-- FIM
