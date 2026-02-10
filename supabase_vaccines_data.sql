-- ================================================
-- DADOS DAS VACINAS - CALENDÁRIO VACINAL BRASILEIRO
-- Execute este SQL no Supabase para popular a tabela vaccines
-- ================================================

-- Limpa dados existentes (opcional - remova se quiser manter)
-- TRUNCATE TABLE vaccines CASCADE;

-- BCG (Ao nascer)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'BCG', 'BCG', 'Vacina contra tuberculose', 0, 48, 1, 1, true, 'mandatory', ARRAY['Tuberculose', 'Meningite tuberculosa', 'Tuberculose miliar']);

-- Hepatite B (Ao nascer)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Hepatite B', 'HepB', 'Vacina contra Hepatite B - dose ao nascer', 0, 1, 1, 1, true, 'mandatory', ARRAY['Hepatite B']);

-- Pentavalente (2, 4 e 6 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Pentavalente', 'DTP-Hib-HB', 'Vacina Pentavalente - 1ª dose', 2, 7, 1, 3, true, 'mandatory', ARRAY['Difteria', 'Tétano', 'Coqueluche', 'Haemophilus influenzae B', 'Hepatite B']),
(gen_random_uuid(), 'Pentavalente', 'DTP-Hib-HB', 'Vacina Pentavalente - 2ª dose', 4, 7, 2, 3, true, 'mandatory', ARRAY['Difteria', 'Tétano', 'Coqueluche', 'Haemophilus influenzae B', 'Hepatite B']),
(gen_random_uuid(), 'Pentavalente', 'DTP-Hib-HB', 'Vacina Pentavalente - 3ª dose', 6, 7, 3, 3, true, 'mandatory', ARRAY['Difteria', 'Tétano', 'Coqueluche', 'Haemophilus influenzae B', 'Hepatite B']);

-- VIP/VOP - Poliomielite (2, 4, 6 meses e reforços)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Poliomielite Inativada', 'VIP', 'Vacina Poliomielite Inativada - 1ª dose', 2, 7, 1, 3, true, 'mandatory', ARRAY['Poliomielite', 'Paralisia infantil']),
(gen_random_uuid(), 'Poliomielite Inativada', 'VIP', 'Vacina Poliomielite Inativada - 2ª dose', 4, 7, 2, 3, true, 'mandatory', ARRAY['Poliomielite', 'Paralisia infantil']),
(gen_random_uuid(), 'Poliomielite Inativada', 'VIP', 'Vacina Poliomielite Inativada - 3ª dose', 6, 7, 3, 3, true, 'mandatory', ARRAY['Poliomielite', 'Paralisia infantil']);

-- Rotavírus (2 e 4 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Rotavírus', 'VORH', 'Vacina contra Rotavírus - 1ª dose', 2, 4, 1, 2, true, 'mandatory', ARRAY['Diarreia por Rotavírus', 'Gastroenterite']),
(gen_random_uuid(), 'Rotavírus', 'VORH', 'Vacina contra Rotavírus - 2ª dose', 4, 8, 2, 2, true, 'mandatory', ARRAY['Diarreia por Rotavírus', 'Gastroenterite']);

-- Pneumocócica 10-valente (2, 4 meses e reforço 12 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Pneumocócica 10-valente', 'Pneumo 10', 'Vacina Pneumocócica - 1ª dose', 2, 7, 1, 3, true, 'mandatory', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média']),
(gen_random_uuid(), 'Pneumocócica 10-valente', 'Pneumo 10', 'Vacina Pneumocócica - 2ª dose', 4, 7, 2, 3, true, 'mandatory', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média']),
(gen_random_uuid(), 'Pneumocócica 10-valente', 'Pneumo 10', 'Vacina Pneumocócica - Reforço', 12, 18, 3, 3, true, 'mandatory', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média']);

-- Meningocócica C (3, 5 meses e reforço 12 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Meningocócica C', 'MenC', 'Vacina Meningocócica C - 1ª dose', 3, 7, 1, 3, true, 'mandatory', ARRAY['Meningite meningocócica C', 'Doença meningocócica']),
(gen_random_uuid(), 'Meningocócica C', 'MenC', 'Vacina Meningocócica C - 2ª dose', 5, 7, 2, 3, true, 'mandatory', ARRAY['Meningite meningocócica C', 'Doença meningocócica']),
(gen_random_uuid(), 'Meningocócica C', 'MenC', 'Vacina Meningocócica C - Reforço', 12, 18, 3, 3, true, 'mandatory', ARRAY['Meningite meningocócica C', 'Doença meningocócica']);

-- Febre Amarela (9 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Febre Amarela', 'FA', 'Vacina contra Febre Amarela', 9, 60, 1, 1, true, 'mandatory', ARRAY['Febre Amarela']);

-- Tríplice Viral (12 e 15 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Tríplice Viral', 'SCR', 'Vacina Tríplice Viral - 1ª dose', 12, 18, 1, 2, true, 'mandatory', ARRAY['Sarampo', 'Caxumba', 'Rubéola']),
(gen_random_uuid(), 'Tríplice Viral', 'SCR', 'Vacina Tríplice Viral - 2ª dose', 15, 24, 2, 2, true, 'mandatory', ARRAY['Sarampo', 'Caxumba', 'Rubéola']);

-- Hepatite A (15 meses)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Hepatite A', 'HepA', 'Vacina contra Hepatite A', 15, 60, 1, 1, true, 'mandatory', ARRAY['Hepatite A']);

-- DTP - Reforços (15 meses e 4 anos)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'DTP', 'DTP', 'Vacina Tríplice Bacteriana - 1º Reforço', 15, 24, 1, 2, true, 'mandatory', ARRAY['Difteria', 'Tétano', 'Coqueluche']),
(gen_random_uuid(), 'DTP', 'DTP', 'Vacina Tríplice Bacteriana - 2º Reforço', 48, 72, 2, 2, true, 'mandatory', ARRAY['Difteria', 'Tétano', 'Coqueluche']);

-- Poliomielite Oral - Reforços (15 meses e 4 anos)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Poliomielite Oral', 'VOP', 'Vacina Poliomielite Oral - 1º Reforço', 15, 24, 1, 2, true, 'mandatory', ARRAY['Poliomielite', 'Paralisia infantil']),
(gen_random_uuid(), 'Poliomielite Oral', 'VOP', 'Vacina Poliomielite Oral - 2º Reforço', 48, 72, 2, 2, true, 'mandatory', ARRAY['Poliomielite', 'Paralisia infantil']);

-- Varicela (4 anos)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Varicela', 'VZ', 'Vacina contra Varicela (Catapora)', 48, 72, 1, 1, true, 'mandatory', ARRAY['Varicela', 'Catapora']);

-- ================================================
-- VACINAS RECOMENDADAS (não obrigatórias no PNI)
-- ================================================

-- Meningocócica B (3, 5 meses + reforços)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Meningocócica B', 'MenB', 'Vacina Meningocócica B - 1ª dose', 3, 24, 1, 3, false, 'recommended', ARRAY['Meningite meningocócica B', 'Doença meningocócica invasiva']),
(gen_random_uuid(), 'Meningocócica B', 'MenB', 'Vacina Meningocócica B - 2ª dose', 5, 24, 2, 3, false, 'recommended', ARRAY['Meningite meningocócica B', 'Doença meningocócica invasiva']),
(gen_random_uuid(), 'Meningocócica B', 'MenB', 'Vacina Meningocócica B - Reforço', 12, 24, 3, 3, false, 'recommended', ARRAY['Meningite meningocócica B', 'Doença meningocócica invasiva']);

-- Meningocócica ACWY (11-12 anos recomendado, mas pode ser dado antes)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Meningocócica ACWY', 'MenACWY', 'Vacina Meningocócica ACWY', 12, NULL, 1, 1, false, 'recommended', ARRAY['Meningite A', 'Meningite C', 'Meningite W', 'Meningite Y']);

-- Pneumocócica 13-valente (alternativa à 10-valente)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Pneumocócica 13-valente', 'Pneumo 13', 'Vacina Pneumocócica 13-valente - 1ª dose', 2, 7, 1, 4, false, 'recommended', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média', 'Sinusite']),
(gen_random_uuid(), 'Pneumocócica 13-valente', 'Pneumo 13', 'Vacina Pneumocócica 13-valente - 2ª dose', 4, 7, 2, 4, false, 'recommended', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média', 'Sinusite']),
(gen_random_uuid(), 'Pneumocócica 13-valente', 'Pneumo 13', 'Vacina Pneumocócica 13-valente - 3ª dose', 6, 7, 3, 4, false, 'recommended', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média', 'Sinusite']),
(gen_random_uuid(), 'Pneumocócica 13-valente', 'Pneumo 13', 'Vacina Pneumocócica 13-valente - Reforço', 12, 18, 4, 4, false, 'recommended', ARRAY['Pneumonia', 'Meningite pneumocócica', 'Otite média', 'Sinusite']);

-- Influenza (a partir de 6 meses - anual)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Influenza (Gripe)', 'Flu', 'Vacina contra Influenza - dose anual', 6, NULL, 1, 1, false, 'recommended', ARRAY['Gripe', 'Influenza']);

-- Dengue (a partir de 4 anos em áreas endêmicas)
INSERT INTO vaccines (id, name, abbreviation, description, recommended_age_months, max_age_months, dose_number, total_doses, is_required, category, diseases_prevented)
VALUES
(gen_random_uuid(), 'Dengue', 'DNG', 'Vacina contra Dengue - 1ª dose', 48, NULL, 1, 2, false, 'recommended', ARRAY['Dengue']),
(gen_random_uuid(), 'Dengue', 'DNG', 'Vacina contra Dengue - 2ª dose', 51, NULL, 2, 2, false, 'recommended', ARRAY['Dengue']);

-- ================================================
-- FIM DOS DADOS
-- ================================================
-- Após executar este SQL, as vacinas estarão disponíveis no app.
-- O app irá criar os registros de baby_vaccinations automaticamente
-- quando a função initializeVaccinationsForBaby for chamada ao criar um bebê.
