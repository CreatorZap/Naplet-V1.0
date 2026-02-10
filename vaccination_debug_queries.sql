-- ================================================
-- QUERIES SQL PARA DEBUG DA CARTEIRA DE VACINAÇÃO
-- Execute estas queries no Supabase SQL Editor
-- ================================================

-- 1. Verificar estrutura da tabela baby_vaccinations
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'baby_vaccinations'
ORDER BY ordinal_position;

-- 2. Verificar se existem registros de vacinação para qualquer bebê
SELECT 
    bv.id as vaccination_id,
    bv.baby_id,
    bv.vaccine_id,
    bv.status,
    bv.application_date,
    v.name as vaccine_name
FROM baby_vaccinations bv
LEFT JOIN vaccines v ON bv.vaccine_id = v.id
LIMIT 20;

-- 3. Verificar RLS policies na tabela baby_vaccinations
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

-- 4. Verificar se a tabela vaccines tem dados
SELECT id, name, age_months, dose_number, total_doses
FROM vaccines
ORDER BY age_months, dose_number
LIMIT 20;

-- 5. Verificar todas as tabelas relacionadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%vaccin%';

-- 6. Verificar permissões do usuário atual
SELECT current_user, current_role;

-- 7. Teste de update (NÃO EXECUTE se tiver dados reais - apenas para teste)
-- UPDATE baby_vaccinations 
-- SET status = 'completed', application_date = '2024-01-01'
-- WHERE id = 'SEU-ID-AQUI'
-- RETURNING *;
