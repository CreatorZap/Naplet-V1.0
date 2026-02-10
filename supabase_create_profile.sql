-- Verificar e criar profile para o usuário

-- 1. Primeiro, ver se o profile existe
SELECT * FROM public.profiles WHERE id = 'dae16d76-fa73-4741-bfe8-1f433219cb6e';

-- 2. Se não retornar nada, executar este INSERT (sem ON CONFLICT):
INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
SELECT 
    'dae16d76-fa73-4741-bfe8-1f433219cb6e'::uuid,
    'contato@edysouza.com.br',
    'Edy Souza',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = 'dae16d76-fa73-4741-bfe8-1f433219cb6e'
);

-- 3. Confirmar que foi criado
SELECT * FROM public.profiles WHERE id = 'dae16d76-fa73-4741-bfe8-1f433219cb6e';
