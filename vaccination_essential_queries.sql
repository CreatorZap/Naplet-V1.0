-- ================================================
-- QUERIES ESSENCIAIS PARA DEBUG - Execute uma por vez
-- ================================================

-- QUERY 1: Estrutura da tabela baby_vaccinations
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'baby_vaccinations'
ORDER BY ordinal_position;

-- QUERY 2: Verificar se há registros de vacinação
SELECT 
    COUNT(*) as total_vaccinations,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending
FROM baby_vaccinations;

-- QUERY 3: Ver alguns registros de vacinação (últimos 10)
SELECT 
    bv.id,
    bv.baby_id,
    bv.vaccine_id,
    bv.status,
    bv.application_date,
    bv.batch_number,
    bv.location,
    bv.updated_at
FROM baby_vaccinations bv
ORDER BY bv.created_at DESC
LIMIT 10;

-- QUERY 4: Verificar constraints e foreign keys
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'baby_vaccinations';

-- QUERY 5: Verificar políticas RLS (Row Level Security) - MUITO IMPORTANTE!
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'baby_vaccinations';

-- QUERY 6: Verificar se RLS está habilitado na tabela
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'baby_vaccinations';

-- QUERY 7: Verificar se há vacinas cadastradas
SELECT 
    COUNT(*) as total_vaccines,
    MIN(age_months) as min_age,
    MAX(age_months) as max_age
FROM vaccines;

-- QUERY 8: Verificar se há bebês cadastrados
SELECT 
    COUNT(*) as total_babies,
    MIN(created_at) as oldest_baby,
    MAX(created_at) as newest_baby
FROM babies;
