-- =============================================
-- QUERIES DE VERIFICAÇÃO - STORAGE SUPABASE
-- Execute cada query separadamente
-- =============================================

-- =============================================
-- QUERY 1: Verificar buckets existentes
-- =============================================
SELECT 
    id,
    name,
    public,
    created_at
FROM storage.buckets;

-- =============================================
-- QUERY 2: Verificar se o bucket baby-documents existe
-- =============================================
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE name = 'baby-documents';

-- =============================================
-- QUERY 3: Verificar arquivos no bucket
-- =============================================
SELECT 
    id,
    name,
    bucket_id,
    created_at,
    metadata
FROM storage.objects
WHERE bucket_id = 'baby-documents'
LIMIT 10;

-- =============================================
-- QUERY 4: Verificar políticas de storage
-- =============================================
SELECT 
    policyname,
    tablename,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage';

-- =============================================
-- QUERY 5: Criar bucket se não existir (EXECUTE SE NECESSÁRIO)
-- =============================================
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--     'baby-documents',
--     'baby-documents', 
--     true,
--     52428800, -- 50MB
--     ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
-- )
-- ON CONFLICT (id) DO UPDATE SET
--     public = true,
--     allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];

-- =============================================
-- QUERY 6: Criar políticas de storage para baby-documents
-- =============================================
-- -- Permitir upload para usuários autenticados
-- CREATE POLICY "Authenticated users can upload documents"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'baby-documents');

-- -- Permitir leitura pública
-- CREATE POLICY "Public can read documents"
-- ON storage.objects FOR SELECT
-- TO public
-- USING (bucket_id = 'baby-documents');

-- -- Permitir delete para usuários autenticados
-- CREATE POLICY "Authenticated users can delete documents"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'baby-documents');

-- =============================================
-- QUERY 7: Verificar URLs dos arquivos salvos
-- =============================================
SELECT 
    df.id,
    df.file_name,
    df.file_path,
    df.file_url,
    df.mime_type,
    df.created_at
FROM document_files df
ORDER BY df.created_at DESC
LIMIT 10;

