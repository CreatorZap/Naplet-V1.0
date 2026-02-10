-- =====================================================
-- NAPLET - FIX PARA CARTEIRA DE DOCUMENTOS
-- Execute no Supabase SQL Editor
-- =====================================================

-- Desabilitar RLS temporariamente para debug (REMOVER DEPOIS!)
-- ALTER TABLE public.baby_documents DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 1. VERIFICAR SE AS TABELAS EXISTEM
-- =====================================================

-- Verificar document_types
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'document_types'
) as document_types_exists;

-- Verificar baby_documents
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'baby_documents'
) as baby_documents_exists;

-- Verificar document_files
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'document_files'
) as document_files_exists;

-- =====================================================
-- 2. RECRIAR POLITICAS COM EXISTS (MAIS EFICIENTE)
-- =====================================================

-- Drop existing policies
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
            WHERE b.id = baby_id
            AND b.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.caregivers c
            WHERE c.baby_id = baby_id
            AND c.user_id = auth.uid()
            AND c.accepted_at IS NOT NULL
        )
    );

-- UPDATE: Owner ou caregiver pode atualizar
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
-- 3. POLITICAS PARA DOCUMENT_FILES
-- =====================================================

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
            WHERE bd.id = document_id
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
-- 4. VERIFICAR POLICIES CRIADAS
-- =====================================================

SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename IN ('baby_documents', 'document_files', 'document_types')
ORDER BY tablename, policyname;

-- =====================================================
-- 5. TESTE DE INSERCAO (EXECUTE MANUALMENTE)
-- =====================================================

-- Descomente para testar inserção manual:
/*
-- Primeiro, obtenha um baby_id válido
SELECT id, name FROM public.babies WHERE owner_id = auth.uid() LIMIT 1;

-- Depois, obtenha um document_type_id válido
SELECT id, code FROM public.document_types LIMIT 1;

-- Teste a inserção
INSERT INTO public.baby_documents (baby_id, document_type_id, title)
VALUES (
    'SEU_BABY_ID_AQUI'::uuid,
    (SELECT id FROM public.document_types WHERE code = 'birth_certificate'),
    'Teste de Documento'
) RETURNING *;
*/

SELECT 'Policies atualizadas com sucesso!' as status;
