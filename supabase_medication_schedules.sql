-- ============================================
-- NAPLET: MEDICATION SCHEDULES SYSTEM
-- Sistema de Lembretes de Medicamentos
-- ============================================

-- Tabela principal de agendamentos de medicamentos
CREATE TABLE IF NOT EXISTS medication_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,

    -- Informações do medicamento
    medication_name TEXT NOT NULL,
    dose TEXT,
    notes TEXT,

    -- Frequência e horários
    frequency TEXT NOT NULL, -- '4h', '6h', '8h', '12h', '24h', '2x', '3x', 'sos', 'custom'
    reminder_times JSONB NOT NULL DEFAULT '[]', -- ["08:00", "14:00", "20:00"]

    -- Duração do tratamento
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE, -- NULL = contínuo
    duration_type TEXT NOT NULL DEFAULT 'continuous', -- 'continuous', 'days', 'until_date'
    duration_days INT, -- Se duration_type = 'days'

    -- Controle de estoque
    doses_remaining INT, -- NULL = não controlar
    doses_per_take DECIMAL(5,2) DEFAULT 1, -- Quantas doses por vez
    low_stock_alert INT DEFAULT 5, -- Alertar quando restarem X doses

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_paused BOOLEAN NOT NULL DEFAULT false,
    paused_until TIMESTAMPTZ, -- Pausar até data específica

    -- Auditoria
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_med_schedules_baby_id ON medication_schedules(baby_id);
CREATE INDEX IF NOT EXISTS idx_med_schedules_active ON medication_schedules(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_med_schedules_baby_active ON medication_schedules(baby_id, is_active);

-- Tabela de logs de medicamentos administrados
CREATE TABLE IF NOT EXISTS medication_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES medication_schedules(id) ON DELETE CASCADE,
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,

    -- Informações da administração
    scheduled_time TIMESTAMPTZ NOT NULL, -- Horário programado
    actual_time TIMESTAMPTZ, -- Horário real da administração
    status TEXT NOT NULL, -- 'given', 'skipped', 'snoozed', 'missed'

    -- Detalhes
    dose_given TEXT, -- Dose efetivamente dada (pode diferir do programado)
    notes TEXT,

    -- Snooze tracking
    snooze_count INT DEFAULT 0,
    snoozed_until TIMESTAMPTZ,

    -- Quem administrou
    given_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para logs
CREATE INDEX IF NOT EXISTS idx_med_logs_schedule ON medication_logs(schedule_id);
CREATE INDEX IF NOT EXISTS idx_med_logs_baby ON medication_logs(baby_id);
CREATE INDEX IF NOT EXISTS idx_med_logs_scheduled_time ON medication_logs(scheduled_time DESC);
CREATE INDEX IF NOT EXISTS idx_med_logs_status ON medication_logs(status);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_medication_schedule_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para updated_at
DROP TRIGGER IF EXISTS trigger_update_medication_schedule_timestamp ON medication_schedules;
CREATE TRIGGER trigger_update_medication_schedule_timestamp
    BEFORE UPDATE ON medication_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_medication_schedule_timestamp();

-- Função para decrementar doses restantes
CREATE OR REPLACE FUNCTION decrement_medication_doses()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'given' AND OLD.status != 'given' THEN
        UPDATE medication_schedules
        SET doses_remaining = GREATEST(0, COALESCE(doses_remaining, 0) - COALESCE(doses_per_take, 1))
        WHERE id = NEW.schedule_id
        AND doses_remaining IS NOT NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para decrementar doses
DROP TRIGGER IF EXISTS trigger_decrement_medication_doses ON medication_logs;
CREATE TRIGGER trigger_decrement_medication_doses
    AFTER UPDATE ON medication_logs
    FOR EACH ROW
    EXECUTE FUNCTION decrement_medication_doses();

-- Também decrementar em INSERT com status 'given'
CREATE OR REPLACE FUNCTION decrement_medication_doses_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'given' THEN
        UPDATE medication_schedules
        SET doses_remaining = GREATEST(0, COALESCE(doses_remaining, 0) - COALESCE(doses_per_take, 1))
        WHERE id = NEW.schedule_id
        AND doses_remaining IS NOT NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_medication_doses_insert ON medication_logs;
CREATE TRIGGER trigger_decrement_medication_doses_insert
    AFTER INSERT ON medication_logs
    FOR EACH ROW
    EXECUTE FUNCTION decrement_medication_doses_on_insert();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE medication_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Usuários podem ver schedules dos seus bebês ou bebês onde são cuidadores
CREATE POLICY "Users can view medication schedules for their babies"
    ON medication_schedules FOR SELECT
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

-- Policy: Usuários podem criar schedules para seus bebês ou bebês onde são cuidadores
CREATE POLICY "Users can create medication schedules for their babies"
    ON medication_schedules FOR INSERT
    WITH CHECK (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

-- Policy: Usuários podem atualizar schedules dos seus bebês
CREATE POLICY "Users can update medication schedules for their babies"
    ON medication_schedules FOR UPDATE
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

-- Policy: Usuários podem deletar schedules dos seus bebês
CREATE POLICY "Users can delete medication schedules for their babies"
    ON medication_schedules FOR DELETE
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

-- Policies para medication_logs (mesma lógica)
CREATE POLICY "Users can view medication logs for their babies"
    ON medication_logs FOR SELECT
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

CREATE POLICY "Users can create medication logs for their babies"
    ON medication_logs FOR INSERT
    WITH CHECK (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

CREATE POLICY "Users can update medication logs for their babies"
    ON medication_logs FOR UPDATE
    USING (
        baby_id IN (
            SELECT id FROM babies WHERE owner_id = auth.uid()
        )
        OR
        baby_id IN (
            SELECT baby_id FROM caregivers
            WHERE user_id = auth.uid()
            AND accepted_at IS NOT NULL
        )
    );

-- ============================================
-- VIEWS ÚTEIS
-- ============================================

-- View: Próximos medicamentos do dia
CREATE OR REPLACE VIEW next_medications AS
SELECT
    ms.id as schedule_id,
    ms.baby_id,
    ms.medication_name,
    ms.dose,
    ms.frequency,
    ms.reminder_times,
    ms.doses_remaining,
    ms.low_stock_alert,
    ms.is_paused,
    b.name as baby_name,
    -- Calcular próximo horário
    (
        SELECT MIN(time_value::time)
        FROM jsonb_array_elements_text(ms.reminder_times) AS time_value
        WHERE time_value::time > CURRENT_TIME
    ) as next_time_today,
    -- Se não tiver mais horário hoje, pegar o primeiro de amanhã
    (
        SELECT MIN(time_value::time)
        FROM jsonb_array_elements_text(ms.reminder_times) AS time_value
    ) as first_time_tomorrow
FROM medication_schedules ms
JOIN babies b ON b.id = ms.baby_id
WHERE ms.is_active = true
AND ms.is_paused = false
AND (ms.end_date IS NULL OR ms.end_date >= CURRENT_DATE);

-- ============================================
-- COMENTÁRIOS
-- ============================================

COMMENT ON TABLE medication_schedules IS 'Agendamentos de medicamentos com horários e frequências';
COMMENT ON TABLE medication_logs IS 'Histórico de administração de medicamentos';
COMMENT ON COLUMN medication_schedules.frequency IS 'Frequência: 4h, 6h, 8h, 12h, 24h, 2x, 3x, sos, custom';
COMMENT ON COLUMN medication_schedules.duration_type IS 'Tipo de duração: continuous (contínuo), days (por X dias), until_date (até data)';
COMMENT ON COLUMN medication_schedules.reminder_times IS 'Array JSON de horários no formato HH:MM';
COMMENT ON COLUMN medication_logs.status IS 'Status: given (dado), skipped (pulado), snoozed (adiado), missed (perdido)';
