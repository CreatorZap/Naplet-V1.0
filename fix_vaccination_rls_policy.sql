-- ================================================
-- CORREÇÃO DA POLÍTICA RLS PARA baby_vaccinations
-- ================================================
-- PROBLEMA: A política baby_vaccinations_update não tem with_check,
-- o que impede UPDATEs quando RLS está habilitado.
-- ================================================

-- 1. Remover a política antiga (se existir)
DROP POLICY IF EXISTS "baby_vaccinations_update" ON "public"."baby_vaccinations";

-- 2. Recriar a política com with_check correto
CREATE POLICY "baby_vaccinations_update"
ON "public"."baby_vaccinations"
FOR UPDATE
USING (
    -- Verifica se o usuário pode ver o registro (qual)
    (
        baby_id IN (
            SELECT babies.id
            FROM babies
            WHERE babies.owner_id = auth.uid()
        )
    )
    OR (
        baby_id IN (
            SELECT caregivers.baby_id
            FROM caregivers
            WHERE caregivers.user_id = auth.uid()
            AND caregivers.accepted_at IS NOT NULL
        )
    )
)
WITH CHECK (
    -- Verifica se o usuário pode atualizar o registro (with_check)
    -- Mesma lógica do USING para garantir consistência
    (
        baby_id IN (
            SELECT babies.id
            FROM babies
            WHERE babies.owner_id = auth.uid()
        )
    )
    OR (
        baby_id IN (
            SELECT caregivers.baby_id
            FROM caregivers
            WHERE caregivers.user_id = auth.uid()
            AND caregivers.accepted_at IS NOT NULL
        )
    )
);

-- ================================================
-- VERIFICAÇÃO: Execute esta query para confirmar
-- ================================================
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'baby_vaccinations'
AND policyname = 'baby_vaccinations_update';
