-- =====================================================
-- NAPLET - CORREÇÃO DAS POLÍTICAS RLS PARA DOCUMENTOS
-- Execute no Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. VERIFICAR SE AS TABELAS EXISTEM
-- =====================================================

SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = table_name) 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status
FROM (VALUES 
    ('document_types'),
    ('baby_documents'),
    ('document_files')
) AS t(table_name);

-- =====================================================
-- 2. GARANTIR QUE RLS ESTÁ HABILITADO
-- =====================================================

ALTER TABLE IF EXISTS public.document_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.baby_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.document_files ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. POLÍTICAS PARA DOCUMENT_TYPES (leitura pública)
-- =====================================================

DROP POLICY IF EXISTS "document_types_select_public" ON public.document_types;
CREATE POLICY "document_types_select_public" ON public.document_types
    FOR SELECT USING (true);

-- =====================================================
-- 4. POLÍTICAS PARA BABY_DOCUMENTS
-- =====================================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "baby_documents_select" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_insert" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_update" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_delete" ON public.baby_documents;

-- SELECT: Owner ou caregiver pode ver
CREATE POLICY "baby_documents_select" ON public.baby_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.babies b
            WHERE b.id = baby_documents.baby_id
            AND b.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = baby_documents.baby_id
            AND c.user_id = auth.uid()
            AND c.accepted_at IS NOT NULL
        )
    );

-- INSERT: Owner ou caregiver pode inserir
CREATE POLICY "baby_documents_insert" ON public.baby_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.babies b
            WHERE b.id = baby_documents.baby_id
            AND b.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = baby_documents.baby_id
            AND c.user_id = auth.uid()
            AND c.accepted_at IS NOT NULL
        )
    );

-- UPDATE: Owner ou caregiver pode atualizar (com with_check)
CREATE POLICY "baby_documents_update" ON public.baby_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.babies b
            WHERE b.id = baby_documents.baby_id
            AND b.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = baby_documents.baby_id
            AND c.user_id = auth.uid()
            AND c.accepted_at IS NOT NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.babies b
            WHERE b.id = baby_documents.baby_id
            AND b.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = baby_documents.baby_id
            AND c.user_id = auth.uid()
            AND c.accepted_at IS NOT NULL
        )
    );

-- DELETE: Apenas owner pode deletar
CREATE POLICY "baby_documents_delete" ON public.baby_documents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.babies b
            WHERE b.id = baby_documents.baby_id
            AND b.owner_id = auth.uid()
        )
    );

-- =====================================================
-- 5. POLÍTICAS PARA DOCUMENT_FILES
-- =====================================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "document_files_select" ON public.document_files;
DROP POLICY IF EXISTS "document_files_insert" ON public.document_files;
DROP POLICY IF EXISTS "document_files_update" ON public.document_files;
DROP POLICY IF EXISTS "document_files_delete" ON public.document_files;

-- SELECT
CREATE POLICY "document_files_select" ON public.document_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c
                WHERE c.baby_id = bd.baby_id
                AND c.user_id = auth.uid()
                AND c.accepted_at IS NOT NULL
            ))
        )
    );

-- INSERT
CREATE POLICY "document_files_insert" ON public.document_files
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c
                WHERE c.baby_id = bd.baby_id
                AND c.user_id = auth.uid()
                AND c.accepted_at IS NOT NULL
            ))
        )
    );

-- UPDATE
CREATE POLICY "document_files_update" ON public.document_files
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c
                WHERE c.baby_id = bd.baby_id
                AND c.user_id = auth.uid()
                AND c.accepted_at IS NOT NULL
            ))
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c
                WHERE c.baby_id = bd.baby_id
                AND c.user_id = auth.uid()
                AND c.accepted_at IS NOT NULL
            ))
        )
    );

-- DELETE
CREATE POLICY "document_files_delete" ON public.document_files
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND b.owner_id = auth.uid()
        )
    );

-- =====================================================
-- 6. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'HAS qual'
        ELSE 'NO qual'
    END as has_qual,
    CASE 
        WHEN with_check IS NOT NULL THEN 'HAS with_check'
        ELSE 'NO with_check'
    END as has_with_check
FROM pg_policies
WHERE tablename IN ('baby_documents', 'document_files', 'document_types')
ORDER BY tablename, policyname;

-- =====================================================
-- 7. VERIFICAR SE RLS ESTÁ HABILITADO
-- =====================================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('document_types', 'baby_documents', 'document_files')
ORDER BY tablename;

SELECT 'Políticas RLS corrigidas com sucesso!' as status;
