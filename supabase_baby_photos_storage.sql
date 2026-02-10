-- ============================================
-- NAPLET - Baby Photos Storage Setup
-- Execute este SQL no Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Criar bucket 'baby-photos' (se não existir)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'baby-photos',
    'baby-photos',
    true,  -- Bucket público para URLs de fotos
    2097152,  -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Remover políticas existentes (se houver) para evitar conflitos
DROP POLICY IF EXISTS "Owners can upload baby photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can update baby photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can delete baby photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view baby photos" ON storage.objects;
DROP POLICY IF EXISTS "Baby photo owners can upload" ON storage.objects;
DROP POLICY IF EXISTS "Baby photo owners can update" ON storage.objects;
DROP POLICY IF EXISTS "Baby photo owners can delete" ON storage.objects;
DROP POLICY IF EXISTS "Baby photos are publicly viewable" ON storage.objects;

-- 3. Políticas de Storage para o bucket 'baby-photos'

-- Permitir que owners façam upload de fotos de seus bebês
CREATE POLICY "Baby photo owners can upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'baby-photos'
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir que owners atualizem fotos de seus bebês
CREATE POLICY "Baby photo owners can update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'baby-photos'
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir que owners deletem fotos de seus bebês
CREATE POLICY "Baby photo owners can delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'baby-photos'
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir visualização pública de fotos de bebês
CREATE POLICY "Baby photos are publicly viewable"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'baby-photos');

-- ============================================
-- ALTERNATIVA: Se as políticas acima falharem por recursão RLS,
-- use estas versões mais simples:
-- ============================================

-- DROP POLICY IF EXISTS "Baby photo owners can upload" ON storage.objects;
-- DROP POLICY IF EXISTS "Baby photo owners can update" ON storage.objects;
-- DROP POLICY IF EXISTS "Baby photo owners can delete" ON storage.objects;
-- DROP POLICY IF EXISTS "Baby photos are publicly viewable" ON storage.objects;

-- -- Upload: Usuário autenticado pode fazer upload
-- CREATE POLICY "Authenticated users can upload baby photos"
-- ON storage.objects
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'baby-photos');

-- -- Update: Usuário autenticado pode atualizar
-- CREATE POLICY "Authenticated users can update baby photos"
-- ON storage.objects
-- FOR UPDATE
-- TO authenticated
-- USING (bucket_id = 'baby-photos');

-- -- Delete: Usuário autenticado pode deletar
-- CREATE POLICY "Authenticated users can delete baby photos"
-- ON storage.objects
-- FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'baby-photos');

-- -- Select: Público pode visualizar
-- CREATE POLICY "Baby photos are publicly viewable"
-- ON storage.objects
-- FOR SELECT
-- TO public
-- USING (bucket_id = 'baby-photos');

-- ============================================
-- VERIFICAÇÃO: Confirmar que photo_url existe na tabela babies
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'babies' AND column_name = 'photo_url'
    ) THEN
        ALTER TABLE babies ADD COLUMN photo_url TEXT;
    END IF;
END $$;

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. Se o INSERT em storage.buckets falhar, crie o bucket manualmente:
--    - Supabase Dashboard > Storage > New Bucket
--    - Nome: "baby-photos"
--    - Public: true
--    - File size limit: 2MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 2. Se as políticas com subquery na tabela babies falharem devido a
--    problemas de recursão RLS, use as políticas alternativas mais simples
--    (descomente a seção ALTERNATIVA acima)
--
-- 3. Estrutura de pastas esperada:
--    baby-photos/
--      {baby_id}/
--        photo.jpg
--
-- 4. O código Swift usa:
--    - Bucket: "baby-photos"
--    - Path: "{baby.id.uuidString}/photo.jpg"
--
-- ============================================
