-- FIX: Corrigir FK de sleep_records.recorded_by

-- 1. Remover a FK antiga que aponta para "users"
ALTER TABLE public.sleep_records DROP CONSTRAINT IF EXISTS sleep_records_recorded_by_fkey;

-- 2. Criar a FK nova apontando para "profiles"
ALTER TABLE public.sleep_records 
ADD CONSTRAINT sleep_records_recorded_by_fkey 
FOREIGN KEY (recorded_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Confirmar que funcionou
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'sleep_records' AND tc.constraint_type = 'FOREIGN KEY';
