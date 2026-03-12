-- =====================================================
-- AI Coach — Row Level Security (RLS)
-- Ejecutar después de 001_initial_schema.sql
-- Garantiza que cada usuario solo accede a sus propios datos
-- =====================================================

-- Activar RLS en todas las tablas con datos de usuario

ALTER TABLE user_profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises              ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_programs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE mesocycles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_templates      ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_slots         ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_sets          ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_weight_logs       ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_logs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_food_entries      ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_goals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_metrics         ENABLE ROW LEVEL SECURITY;
ALTER TABLE adaptation_log         ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages            ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- user_profiles: solo el propio usuario
-- =====================================================
CREATE POLICY "user_profiles_select" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_profiles_insert" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_profiles_update" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- exercises: biblioteca global (user_id IS NULL) + custom del usuario
-- =====================================================
CREATE POLICY "exercises_select" ON exercises
    FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "exercises_insert" ON exercises
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "exercises_update" ON exercises
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "exercises_delete" ON exercises
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- training_programs
-- =====================================================
CREATE POLICY "training_programs_all" ON training_programs
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- mesocycles — acceso via programa del usuario
-- =====================================================
CREATE POLICY "mesocycles_all" ON mesocycles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM training_programs tp
            WHERE tp.id = mesocycles.program_id
              AND tp.user_id = auth.uid()
        )
    );

-- =====================================================
-- workout_templates — acceso via programa
-- =====================================================
CREATE POLICY "workout_templates_all" ON workout_templates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM training_programs tp
            WHERE tp.id = workout_templates.program_id
              AND tp.user_id = auth.uid()
        )
    );

-- =====================================================
-- exercise_slots — acceso via workout_template → programa
-- =====================================================
CREATE POLICY "exercise_slots_all" ON exercise_slots
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM workout_templates wt
            JOIN training_programs tp ON tp.id = wt.program_id
            WHERE wt.id = exercise_slots.workout_template_id
              AND tp.user_id = auth.uid()
        )
    );

-- =====================================================
-- training_sessions
-- =====================================================
CREATE POLICY "training_sessions_all" ON training_sessions
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- exercise_sets — acceso via sesión del usuario
-- =====================================================
CREATE POLICY "exercise_sets_all" ON exercise_sets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM training_sessions ts
            WHERE ts.id = exercise_sets.session_id
              AND ts.user_id = auth.uid()
        )
    );

-- =====================================================
-- body_weight_logs
-- =====================================================
CREATE POLICY "body_weight_logs_all" ON body_weight_logs
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- food_items: globales (user_id IS NULL) + del usuario
-- =====================================================
CREATE POLICY "food_items_select" ON food_items
    FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "food_items_insert" ON food_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "food_items_update" ON food_items
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- meal_logs
-- =====================================================
CREATE POLICY "meal_logs_all" ON meal_logs
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- meal_food_entries — acceso via meal_log del usuario
-- =====================================================
CREATE POLICY "meal_food_entries_all" ON meal_food_entries
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM meal_logs ml
            WHERE ml.id = meal_food_entries.meal_log_id
              AND ml.user_id = auth.uid()
        )
    );

-- =====================================================
-- nutrition_goals y nutrition_logs
-- =====================================================
CREATE POLICY "nutrition_goals_all" ON nutrition_goals
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "nutrition_logs_all" ON nutrition_logs
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- weekly_metrics
-- =====================================================
CREATE POLICY "weekly_metrics_all" ON weekly_metrics
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- adaptation_log
-- =====================================================
CREATE POLICY "adaptation_log_all" ON adaptation_log
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- ai_conversations y ai_messages
-- =====================================================
CREATE POLICY "ai_conversations_all" ON ai_conversations
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "ai_messages_all" ON ai_messages
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM ai_conversations ac
            WHERE ac.id = ai_messages.conversation_id
              AND ac.user_id = auth.uid()
        )
    );

-- =====================================================
-- Edge Functions necesitan service_role para escribir
-- (las Edge Functions se autentican con service_role key,
--  que bypasea RLS — esto es correcto y seguro server-side)
-- =====================================================
