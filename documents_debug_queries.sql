-- ================================================
-- QUERIES PARA DEBUG DA FUNCIONALIDADE DE DOCUMENTOS
-- Execute estas queries no Supabase SQL Editor
-- ================================================

-- QUERY 1: Verificar se as tabelas existem
SELECT 
    table_name,
    table_schema
FROM information_schema.tables
WHERE table_name IN ('document_types', 'baby_documents', 'document_files')
ORDER BY table_name;

-- QUERY 2: Verificar estrutura da tabela document_types
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'document_types'
ORDER BY ordinal_position;

-- QUERY 3: Verificar estrutura da tabela baby_documents
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'baby_documents'
ORDER BY ordinal_position;

-- QUERY 4: Verificar estrutura da tabela document_files
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'document_files'
ORDER BY ordinal_position;

-- QUERY 5: Verificar se há tipos de documentos cadastrados
SELECT 
    COUNT(*) as total_types,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_types
FROM document_types;

-- QUERY 6: Ver alguns tipos de documentos
SELECT 
    id,
    code,
    name,
    is_active,
    order_index
FROM document_types
ORDER BY order_index
LIMIT 10;

-- QUERY 7: Verificar se há documentos cadastrados
SELECT 
    COUNT(*) as total_documents
FROM baby_documents;

-- QUERY 8: Verificar constraints e foreign keys da tabela baby_documents
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
WHERE tc.table_name = 'baby_documents';

-- QUERY 9: Verificar políticas RLS (Row Level Security) - MUITO IMPORTANTE!
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
WHERE tablename IN ('document_types', 'baby_documents', 'document_files')
ORDER BY tablename, policyname;

-- QUERY 10: Verificar se RLS está habilitado nas tabelas
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('document_types', 'baby_documents', 'document_files')
ORDER BY tablename;

-- QUERY 11: Verificar relacionamentos (foreign keys)
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('baby_documents', 'document_files')
ORDER BY tc.table_name;
