-- ============================================
-- NAPLET - Avatar Storage Setup
-- Execute este SQL no Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Criar bucket de avatars (se não existir)
-- Vá em Storage > New Bucket e crie manualmente, OU use a API:
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,  -- Bucket público para URLs de avatar
    2097152,  -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Políticas de Storage para o bucket 'avatars'

-- Permitir que usuários autenticados façam upload de seus próprios avatars
CREATE POLICY "Users can upload their own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Permitir que usuários atualizem/substituam seus próprios avatars
CREATE POLICY "Users can update their own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Permitir que usuários deletem seus próprios avatars
CREATE POLICY "Users can delete their own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Permitir que qualquer pessoa veja avatars (bucket público)
CREATE POLICY "Anyone can view avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- ============================================
-- VERIFICAÇÃO: Confirme que a coluna avatar_url existe na tabela profiles
-- ============================================

-- Adicionar coluna avatar_url se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
    END IF;
END $$;

-- ============================================
-- OPCIONAL: Criar bucket para fotos de bebês
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'babies',
    'babies',
    true,
    2097152,  -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Políticas para bucket 'babies'

-- Permitir que owners façam upload de fotos de seus bebês
CREATE POLICY "Owners can upload baby photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'babies' 
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir que owners atualizem fotos de seus bebês
CREATE POLICY "Owners can update baby photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'babies' 
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir que owners deletem fotos de seus bebês
CREATE POLICY "Owners can delete baby photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'babies' 
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM babies WHERE owner_id = auth.uid()
    )
);

-- Permitir visualização pública de fotos de bebês
CREATE POLICY "Anyone can view baby photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'babies');

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 
-- 1. Se o INSERT em storage.buckets falhar, crie os buckets manualmente:
--    - Supabase Dashboard > Storage > New Bucket
--    - Nome: "avatars" (ou "babies")
--    - Public: true
--    - File size limit: 2MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 2. Se as políticas já existirem, você verá erros de "already exists"
--    Isso é esperado e pode ser ignorado.
--
-- 3. Estrutura de pastas esperada:
--    avatars/
--      {user_id}/
--        avatar.jpg
--    babies/
--      {baby_id}/
--        photo.jpg
--
-- ============================================
