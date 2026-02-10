-- =====================================================
-- NAPLET - SETUP INICIAL DOCUMENTOS
-- Execute PRIMEIRO este SQL no Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. CRIAR TABELA DE TIPOS DE DOCUMENTOS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.document_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_es TEXT NOT NULL,
    description TEXT,
    icon TEXT NOT NULL DEFAULT '📄',
    color TEXT NOT NULL DEFAULT '#7C3AED',
    has_expiration BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================
-- 2. INSERIR TIPOS DE DOCUMENTOS
-- =====================================================

INSERT INTO public.document_types (code, name, name_en, name_es, description, icon, color, has_expiration, order_index) VALUES
('birth_certificate', 'Certidao de Nascimento', 'Birth Certificate', 'Acta de Nacimiento',
 'Documento oficial de registro civil do nascimento', '📜', '#7C3AED', false, 1),
('rg', 'RG / Identidade', 'ID Card', 'Documento de Identidad',
 'Registro Geral - documento de identificacao', '🪪', '#EC4899', true, 2),
('cpf', 'CPF', 'Tax ID', 'CPF',
 'Cadastro de Pessoa Fisica', '📋', '#3B82F6', false, 3),
('passport', 'Passaporte', 'Passport', 'Pasaporte',
 'Documento para viagens internacionais', '🛂', '#10B981', true, 4),
('vaccination_card', 'Carteira de Vacinacao', 'Vaccination Card', 'Carnet de Vacunacion',
 'Caderneta fisica de vacinacao', '💉', '#F59E0B', false, 5),
('sus_card', 'Cartao do SUS', 'Public Health Card', 'Tarjeta de Salud Publica',
 'Cartao Nacional de Saude', '🏥', '#06B6D4', false, 6),
('health_insurance', 'Plano de Saude', 'Health Insurance', 'Seguro de Salud',
 'Carteirinha do convenio medico', '🏦', '#8B5CF6', true, 7),
('baptism_certificate', 'Certidao de Batismo', 'Baptism Certificate', 'Acta de Bautismo',
 'Documento religioso de batismo', '⛪', '#F97316', false, 8),
('medical_exams', 'Exames Medicos', 'Medical Exams', 'Examenes Medicos',
 'Resultados de exames laboratoriais e de imagem', '🔬', '#EF4444', false, 9),
('prescriptions', 'Receitas Medicas', 'Prescriptions', 'Recetas Medicas',
 'Prescricoes e receitas de medicamentos', '💊', '#84CC16', false, 10),
('medical_reports', 'Laudos Medicos', 'Medical Reports', 'Informes Medicos',
 'Laudos, atestados e relatorios medicos', '📑', '#14B8A6', false, 11),
('special_photos', 'Fotos Especiais', 'Special Photos', 'Fotos Especiales',
 'Ultrassom, fotos da maternidade, marcos importantes', '📸', '#EC4899', false, 12),
('other', 'Outros Documentos', 'Other Documents', 'Otros Documentos',
 'Documentos diversos', '📎', '#6B7280', false, 99)
ON CONFLICT (code) DO NOTHING;

-- RLS para document_types (leitura publica)
ALTER TABLE public.document_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "document_types_select_public" ON public.document_types;
CREATE POLICY "document_types_select_public" ON public.document_types
    FOR SELECT USING (true);

-- =====================================================
-- 3. CRIAR TABELA DE DOCUMENTOS DO BEBE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.baby_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
    document_type_id UUID NOT NULL REFERENCES public.document_types(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    document_number TEXT,
    issue_date DATE,
    expiration_date DATE,
    issuing_authority TEXT,
    notes TEXT,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_baby_documents_baby ON public.baby_documents(baby_id);
CREATE INDEX IF NOT EXISTS idx_baby_documents_type ON public.baby_documents(document_type_id);

-- RLS
ALTER TABLE public.baby_documents ENABLE ROW LEVEL SECURITY;

-- Politicas simplificadas
DROP POLICY IF EXISTS "baby_documents_select" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_insert" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_update" ON public.baby_documents;
DROP POLICY IF EXISTS "baby_documents_delete" ON public.baby_documents;

CREATE POLICY "baby_documents_select" ON public.baby_documents
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.babies WHERE id = baby_documents.baby_id AND owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.caregivers WHERE baby_id = baby_documents.baby_id AND user_id = auth.uid() AND accepted_at IS NOT NULL)
    );

CREATE POLICY "baby_documents_insert" ON public.baby_documents
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.babies WHERE id = baby_id AND owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.caregivers WHERE baby_id = baby_id AND user_id = auth.uid() AND accepted_at IS NOT NULL)
    );

CREATE POLICY "baby_documents_update" ON public.baby_documents
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.babies WHERE id = baby_documents.baby_id AND owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.caregivers WHERE baby_id = baby_documents.baby_id AND user_id = auth.uid() AND accepted_at IS NOT NULL)
    );

CREATE POLICY "baby_documents_delete" ON public.baby_documents
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.babies WHERE id = baby_documents.baby_id AND owner_id = auth.uid())
    );

-- =====================================================
-- 4. CRIAR TABELA DE ARQUIVOS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.document_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.baby_documents(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT,
    file_size INTEGER,
    mime_type TEXT NOT NULL DEFAULT 'image/jpeg',
    page_number INTEGER DEFAULT 1,
    width INTEGER,
    height INTEGER,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_document_files_document ON public.document_files(document_id);

-- RLS
ALTER TABLE public.document_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "document_files_select" ON public.document_files;
DROP POLICY IF EXISTS "document_files_insert" ON public.document_files;
DROP POLICY IF EXISTS "document_files_update" ON public.document_files;
DROP POLICY IF EXISTS "document_files_delete" ON public.document_files;

CREATE POLICY "document_files_select" ON public.document_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c WHERE c.baby_id = bd.baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL
            ))
        )
    );

CREATE POLICY "document_files_insert" ON public.document_files
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c WHERE c.baby_id = bd.baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL
            ))
        )
    );

CREATE POLICY "document_files_update" ON public.document_files
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.baby_documents bd
            JOIN public.babies b ON b.id = bd.baby_id
            WHERE bd.id = document_files.document_id
            AND (b.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.caregivers c WHERE c.baby_id = bd.baby_id AND c.user_id = auth.uid() AND c.accepted_at IS NOT NULL
            ))
        )
    );

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
-- 5. CRIAR BUCKET NO STORAGE
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'baby-documents',
    'baby-documents',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Politicas do Storage
DROP POLICY IF EXISTS "baby_documents_storage_select" ON storage.objects;
DROP POLICY IF EXISTS "baby_documents_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "baby_documents_storage_update" ON storage.objects;
DROP POLICY IF EXISTS "baby_documents_storage_delete" ON storage.objects;

CREATE POLICY "baby_documents_storage_select" ON storage.objects
    FOR SELECT USING (bucket_id = 'baby-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY "baby_documents_storage_insert" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'baby-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY "baby_documents_storage_update" ON storage.objects
    FOR UPDATE USING (bucket_id = 'baby-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY "baby_documents_storage_delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'baby-documents' AND auth.uid() IS NOT NULL);

-- =====================================================
-- 6. VERIFICACAO
-- =====================================================

SELECT 'Tabelas criadas:' as info;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('document_types', 'baby_documents', 'document_files');

SELECT 'Tipos de documento inseridos:' as info;
SELECT code, name, icon FROM public.document_types ORDER BY order_index;

SELECT '✅ Setup completo!' as status;
