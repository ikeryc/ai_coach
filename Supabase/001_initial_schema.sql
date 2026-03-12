-- =====================================================
-- AI Coach — Schema inicial
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- PERFIL Y USUARIO
-- =====================================================

CREATE TABLE user_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    age             INT NOT NULL,
    sex             TEXT NOT NULL CHECK (sex IN ('male', 'female', 'other')),
    weight_kg       DECIMAL(5,2) NOT NULL,
    height_cm       DECIMAL(5,1) NOT NULL,
    body_fat_percentage DECIMAL(4,1),
    experience_level TEXT NOT NULL CHECK (experience_level IN ('beginner','intermediate','advanced')),
    primary_goal    TEXT NOT NULL CHECK (primary_goal IN ('hypertrophy','strength','fat_loss','recomposition')),
    available_training_days INT NOT NULL CHECK (available_training_days BETWEEN 1 AND 7),
    equipment       TEXT NOT NULL CHECK (equipment IN ('full_gym','home','dumbbells_only')),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);

-- =====================================================
-- EJERCICIOS
-- =====================================================

CREATE TABLE exercises (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wger_id                 INT,
    name                    TEXT NOT NULL,
    primary_muscle_group    TEXT NOT NULL,
    secondary_muscle_groups TEXT[],
    equipment_required      TEXT,
    exercise_type           TEXT CHECK (exercise_type IN ('compound','isolation')),
    instructions            TEXT,
    gif_url                 TEXT,
    thumbnail_url           TEXT,
    is_custom               BOOLEAN NOT NULL DEFAULT false,
    user_id                 UUID REFERENCES auth.users(id) ON DELETE CASCADE
    -- user_id = NULL → ejercicio global de la biblioteca
);

CREATE INDEX idx_exercises_muscle ON exercises(primary_muscle_group);
CREATE INDEX idx_exercises_user ON exercises(user_id);

-- =====================================================
-- PROGRAMAS Y MESOCICLOS
-- =====================================================

CREATE TABLE training_programs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name                    TEXT NOT NULL,
    goal                    TEXT NOT NULL,
    total_weeks             INT NOT NULL,
    start_date              DATE,
    end_date                DATE,
    status                  TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','completed','paused')),
    ai_generated            BOOLEAN NOT NULL DEFAULT false,
    ai_generation_context   JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE mesocycles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id  UUID NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    number      INT NOT NULL,
    week_start  INT NOT NULL,
    week_end    INT NOT NULL,
    phase       TEXT NOT NULL CHECK (phase IN ('accumulation','intensification','deload')),
    notes       TEXT
);

CREATE TABLE workout_templates (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id                  UUID NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    week_number                 INT NOT NULL,
    day_of_week                 INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    name                        TEXT NOT NULL,
    estimated_duration_minutes  INT,
    is_deload                   BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE exercise_slots (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
    exercise_id         UUID NOT NULL REFERENCES exercises(id),
    order_index         INT NOT NULL,
    sets_count          INT NOT NULL,
    rep_range_min       INT NOT NULL,
    rep_range_max       INT NOT NULL,
    rir_target          INT,
    rest_seconds        INT,
    progression_model   TEXT CHECK (progression_model IN ('linear','double_progression','rir_based','undulating')),
    notes               TEXT
);

-- =====================================================
-- SESIONES REALES
-- =====================================================

CREATE TABLE training_sessions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_template_id UUID REFERENCES workout_templates(id),
    date                DATE NOT NULL,
    started_at          TIMESTAMPTZ,
    ended_at            TIMESTAMPTZ,
    perceived_fatigue   INT CHECK (perceived_fatigue BETWEEN 1 AND 10),
    notes               TEXT,
    completed           BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_sessions_user_date ON training_sessions(user_id, date DESC);

CREATE TABLE exercise_sets (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id  UUID NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id),
    set_number  INT NOT NULL,
    weight_kg   DECIMAL(6,2) NOT NULL,
    reps        INT NOT NULL,
    rir_actual  INT,
    is_warmup   BOOLEAN NOT NULL DEFAULT false,
    logged_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sets_session ON exercise_sets(session_id);
CREATE INDEX idx_sets_exercise ON exercise_sets(exercise_id);

-- =====================================================
-- PESO CORPORAL
-- =====================================================

CREATE TABLE body_weight_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    weight_kg   DECIMAL(5,2) NOT NULL,
    source      TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','healthkit')),
    notes       TEXT,
    UNIQUE (user_id, date)
);

CREATE INDEX idx_weight_user_date ON body_weight_logs(user_id, date DESC);

-- =====================================================
-- BASE DE DATOS DE ALIMENTOS
-- =====================================================

CREATE TABLE food_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id         TEXT,
    source              TEXT NOT NULL DEFAULT 'custom' CHECK (source IN ('open_food_facts','usda','custom')),
    name                TEXT NOT NULL,
    brand               TEXT,
    barcode             TEXT,
    calories_per_100g   DECIMAL(7,2) NOT NULL,
    protein_per_100g    DECIMAL(6,2) NOT NULL,
    carbs_per_100g      DECIMAL(6,2) NOT NULL,
    fat_per_100g        DECIMAL(6,2) NOT NULL,
    fiber_per_100g      DECIMAL(6,2),
    serving_size_g      DECIMAL(7,2),
    user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX idx_food_barcode ON food_items(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_food_name ON food_items USING gin(to_tsvector('spanish', name));

CREATE TABLE meal_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    meal_type   TEXT NOT NULL CHECK (meal_type IN ('breakfast','lunch','dinner','snack','pre_workout','post_workout'))
);

CREATE TABLE meal_food_entries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_log_id     UUID NOT NULL REFERENCES meal_logs(id) ON DELETE CASCADE,
    food_item_id    UUID NOT NULL REFERENCES food_items(id),
    quantity_g      DECIMAL(7,2) NOT NULL,
    calories        DECIMAL(7,2) NOT NULL,
    protein_g       DECIMAL(6,2) NOT NULL,
    carbs_g         DECIMAL(6,2) NOT NULL,
    fat_g           DECIMAL(6,2) NOT NULL
);

-- =====================================================
-- NUTRICIÓN
-- =====================================================

CREATE TABLE nutrition_goals (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_date          DATE NOT NULL,
    end_date            DATE,
    calories_target     INT NOT NULL,
    protein_g           INT NOT NULL,
    carbs_g             INT NOT NULL,
    fat_g               INT NOT NULL,
    adjustment_reason   TEXT,
    created_by          TEXT NOT NULL DEFAULT 'user' CHECK (created_by IN ('ai','user','rule_engine'))
);

CREATE TABLE nutrition_logs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date                    DATE NOT NULL,
    calories                INT NOT NULL DEFAULT 0,
    protein_g               DECIMAL(6,1) NOT NULL DEFAULT 0,
    carbs_g                 DECIMAL(6,1) NOT NULL DEFAULT 0,
    fat_g                   DECIMAL(6,1) NOT NULL DEFAULT 0,
    adherence_percentage    DECIMAL(5,2),
    notes                   TEXT,
    UNIQUE (user_id, date)
);

-- =====================================================
-- MÉTRICAS SEMANALES
-- =====================================================

CREATE TABLE weekly_metrics (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_start_date             DATE NOT NULL,
    avg_weight_7d               DECIMAL(5,2),
    weight_change_vs_prev_week  DECIMAL(4,2),
    estimated_1rm               JSONB,      -- {exercise_id: 1rm_kg}
    total_volume_by_muscle      JSONB,      -- {muscle_group: total_volume}
    avg_calorie_adherence       DECIMAL(5,2),
    training_sessions_completed INT NOT NULL DEFAULT 0,
    training_sessions_planned   INT NOT NULL DEFAULT 0,
    computed_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, week_start_date)
);

-- =====================================================
-- ADAPTACIONES AUTOMÁTICAS
-- =====================================================

CREATE TABLE adaptation_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    adaptation_type TEXT NOT NULL CHECK (adaptation_type IN (
        'calories_up','calories_down','volume_up','volume_down',
        'deload','program_change','macro_adjustment',
        'weight_progression','weight_regression'
    )),
    previous_value  JSONB,
    new_value       JSONB,
    trigger_reason  TEXT NOT NULL,
    triggered_by    TEXT NOT NULL CHECK (triggered_by IN ('rule_engine','ai','user')),
    user_approved   BOOLEAN NOT NULL DEFAULT false
);

-- =====================================================
-- CHAT IA
-- =====================================================

CREATE TABLE ai_conversations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL DEFAULT 'Nueva conversación',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ai_messages (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id     UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role                TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
    content             TEXT NOT NULL,
    context_snapshot    JSONB,
    tokens_used         INT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON ai_messages(conversation_id, created_at);
