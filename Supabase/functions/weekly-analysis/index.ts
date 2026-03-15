/**
 * Edge Function: weekly-analysis
 *
 * Analiza el progreso semanal del usuario y devuelve sugerencias de adaptación
 * generadas por Claude Sonnet, complementando las reglas determinísticas de la app.
 *
 * Request  → { user_id: string }
 * Response → { suggestions: AdaptationSuggestion[] }
 *
 * AdaptationSuggestion: { id, type, reason, previousValue?, newValue? }
 */

import { callClaude, extractText, extractJSON } from "../_shared/anthropic.ts";
import { handleCors, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-sonnet-4-6";
const MAX_TOKENS = 1024;

const SYSTEM_PROMPT = `Eres un entrenador personal experto analizando el progreso semanal de un atleta.

Basándote en los datos proporcionados, identifica las adaptaciones más importantes que debería hacer el usuario.

RESPONDE ÚNICAMENTE con un array JSON válido (sin texto adicional, sin markdown):
[
  {
    "id": "<tipo_adaptación>",
    "type": "<calories_up | calories_down | volume_up | volume_down | deload | macro_adjustment | weight_progression>",
    "reason": "<explicación concisa en español, máximo 2 frases>",
    "previousValue": "<valor actual como string, o null>",
    "newValue": "<valor sugerido como string, o null>"
  }
]

REGLAS:
- Devuelve entre 0 y 3 sugerencias (solo las más relevantes)
- Si no hay datos suficientes para analizar, devuelve []
- Prioriza sugerencias de alto impacto
- Usa los tipos definidos, no inventes otros
- previousValue y newValue son strings descriptivos (ej: "2500 kcal", "4 días/semana")
- Si todo está bien, puedes devolver [] o 1 sugerencia positiva de refuerzo`;

interface WeeklyMetricsRow {
  week_start_date: string;
  avg_weight_7d: number | null;
  weight_change_vs_prev_week: number | null;
  avg_calorie_adherence: number | null;
  training_sessions_completed: number;
  training_sessions_planned: number;
  total_volume_by_muscle: Record<string, number> | null;
  estimated_1rm: Record<string, number> | null;
}

interface UserProfileRow {
  primary_goal: string;
  experience_level: string;
  weight_kg: number;
  available_training_days: number;
}

interface NutritionGoalRow {
  calories_target: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user_id } = await req.json();

    if (!user_id) {
      return errorResponse("user_id es requerido", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Fetch user profile
    const { data: profileRows } = await supabase
      .from("user_profiles")
      .select("primary_goal, experience_level, weight_kg, available_training_days")
      .eq("user_id", user_id)
      .limit(1);

    const profile: UserProfileRow | null = profileRows?.[0] ?? null;

    if (!profile) {
      return jsonResponse({ suggestions: [] });
    }

    // Fetch last 2 weeks of metrics
    const { data: metricsRows } = await supabase
      .from("weekly_metrics")
      .select(
        "week_start_date, avg_weight_7d, weight_change_vs_prev_week, avg_calorie_adherence, training_sessions_completed, training_sessions_planned, total_volume_by_muscle, estimated_1rm"
      )
      .eq("user_id", user_id)
      .order("week_start_date", { ascending: false })
      .limit(2);

    const metrics: WeeklyMetricsRow[] = metricsRows ?? [];

    // Fetch active nutrition goal
    const { data: goalRows } = await supabase
      .from("nutrition_goals")
      .select("calories_target, protein_g, carbs_g, fat_g")
      .eq("user_id", user_id)
      .is("end_date", null)
      .order("start_date", { ascending: false })
      .limit(1);

    const nutritionGoal: NutritionGoalRow | null = goalRows?.[0] ?? null;

    if (metrics.length === 0) {
      return jsonResponse({ suggestions: [] });
    }

    // Build analysis prompt
    const latest = metrics[0];
    const previous = metrics[1] ?? null;

    const goalMap: Record<string, string> = {
      hypertrophy: "ganar músculo (superávit calórico moderado, +0.25-0.5% peso/sem)",
      strength: "ganar fuerza (superávit pequeño, +0.1-0.3% peso/sem)",
      fat_loss: "perder grasa (déficit, -0.5-1% peso/sem)",
      recomposition: "recomposición (peso estable ±0.1% peso/sem)",
    };

    const expMap: Record<string, string> = {
      beginner: "principiante",
      intermediate: "intermedio",
      advanced: "avanzado",
    };

    const lines: string[] = [
      `Objetivo: ${goalMap[profile.primary_goal] ?? profile.primary_goal}`,
      `Nivel: ${expMap[profile.experience_level] ?? profile.experience_level}`,
      `Peso actual: ${profile.weight_kg} kg`,
      `Días de entrenamiento planificados: ${profile.available_training_days}/semana`,
      "",
      "=== ÚLTIMA SEMANA ===",
      `Sesiones completadas: ${latest.training_sessions_completed}/${latest.training_sessions_planned}`,
    ];

    if (latest.avg_weight_7d != null) {
      lines.push(`Peso medio 7 días: ${latest.avg_weight_7d.toFixed(2)} kg`);
    }
    if (latest.weight_change_vs_prev_week != null) {
      const sign = latest.weight_change_vs_prev_week >= 0 ? "+" : "";
      lines.push(`Cambio de peso: ${sign}${latest.weight_change_vs_prev_week.toFixed(2)} kg`);
    }
    if (latest.avg_calorie_adherence != null) {
      lines.push(`Adherencia calórica: ${latest.avg_calorie_adherence.toFixed(0)}%`);
    }

    if (nutritionGoal) {
      lines.push(
        `Objetivo calórico actual: ${nutritionGoal.calories_target} kcal | P:${nutritionGoal.protein_g}g C:${nutritionGoal.carbs_g}g G:${nutritionGoal.fat_g}g`
      );
    }

    if (previous) {
      lines.push("", "=== SEMANA ANTERIOR ===");
      lines.push(
        `Sesiones completadas: ${previous.training_sessions_completed}/${previous.training_sessions_planned}`
      );
      if (previous.avg_weight_7d != null) {
        lines.push(`Peso medio 7 días: ${previous.avg_weight_7d.toFixed(2)} kg`);
      }
    }

    // Compare e1RMs if available
    if (latest.estimated_1rm && previous?.estimated_1rm) {
      const latestRMs = latest.estimated_1rm;
      const prevRMs = previous.estimated_1rm;
      const common = Object.keys(latestRMs).filter((k) => k in prevRMs);
      if (common.length > 0) {
        const avgLatest = common.reduce((s, k) => s + latestRMs[k], 0) / common.length;
        const avgPrev   = common.reduce((s, k) => s + prevRMs[k], 0) / common.length;
        const pct = ((avgLatest - avgPrev) / avgPrev) * 100;
        lines.push(
          `Cambio e1RM medio: ${pct >= 0 ? "+" : ""}${pct.toFixed(1)}% (sobre ${common.length} ejercicios)`
        );
      }
    }

    const userPrompt = lines.join("\n") + "\n\nGenera las sugerencias de adaptación más relevantes para este usuario.";

    const response = await callClaude({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: userPrompt }],
    });

    const text = extractText(response);
    const suggestions = extractJSON<unknown[]>(text);

    return jsonResponse({ suggestions });
  } catch (err) {
    console.error("weekly-analysis error:", err);
    return errorResponse(err instanceof Error ? err.message : "Error interno", 500);
  }
});
