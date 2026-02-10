-- =============================================
-- QUERIES DE VERIFICAÇÃO - FUNCIONALIDADE DOCUMENTOS
-- Execute cada query separadamente e envie o resultado
-- =============================================

-- =============================================
-- QUERY 1: Verificar se document_types tem dados
-- =============================================
SELECT 
    'document_types' as table_name,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE is_active = true) as active_rows
FROM document_types;

-- =============================================
-- QUERY 2: Listar todos os document_types
-- =============================================
SELECT 
    id,
    code,
    name,
    icon,
    is_active,
    order_index,
    created_at
FROM document_types
ORDER BY order_index;

-- =============================================
-- QUERY 3: Verificar estrutura da tabela document_types
-- =============================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'document_types'
ORDER BY ordinal_position;

-- =============================================
-- QUERY 4: Verificar RLS está habilitado
-- =============================================
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('document_types', 'baby_documents', 'document_files');

-- =============================================
-- QUERY 5: Verificar políticas RLS de document_types
-- =============================================
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'document_types';

-- =============================================
-- QUERY 6: Verificar políticas RLS de baby_documents
-- =============================================
SELECT 
    policyname,
    cmd,
    permissive,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'baby_documents';

-- =============================================
-- QUERY 7: Testar SELECT em document_types com usuário atual
-- =============================================
SELECT 
    auth.uid() as current_user_id,
    (SELECT COUNT(*) FROM document_types WHERE is_active = true) as accessible_types;

-- =============================================
-- QUERY 8: Verificar se há bebês cadastrados
-- =============================================
SELECT 
    id,
    owner_id,
    name,
    created_at
FROM babies
LIMIT 5;

-- =============================================
-- QUERY 9: Verificar formato dos dados de created_at
-- =============================================
SELECT 
    id,
    code,
    name,
    created_at,
    pg_typeof(created_at) as created_at_type
FROM document_types
LIMIT 3;

-- =============================================
-- QUERY 10: Verificar se RLS permite leitura pública em document_types
-- Se não houver política SELECT ou se não for pública, pode ser o problema
-- =============================================
SELECT 
    'document_types' as table_name,
    EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'document_types' 
        AND cmd = 'SELECT'
    ) as has_select_policy,
    (
        SELECT qual FROM pg_policies 
        WHERE tablename = 'document_types' 
        AND cmd = 'SELECT'
        LIMIT 1
    ) as select_condition;

