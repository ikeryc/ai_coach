/**
 * Edge Function: ai-chat
 *
 * Gestiona el chat con el entrenador IA. Recupera el historial de la conversación
 * desde Supabase, inyecta el contexto del usuario y llama a Claude Sonnet.
 *
 * Request  → { conversationId: string, userMessage: string, contextJSON: string }
 * Response → { assistantMessage: string, tokensUsed: number }
 */

import { callClaude, extractText } from "../_shared/anthropic.ts";
import { handleCors, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-sonnet-4-6";
const MAX_TOKENS = 1024;
const MAX_HISTORY_MESSAGES = 10; // últimos N mensajes del historial

const SYSTEM_PROMPT = `Eres un entrenador personal y nutricionista experto, integrado en la app AI Coach.

Tu personalidad:
- Directo, motivador y empático
- Basas tus respuestas en evidencia científica actualizada (hipertrofia, nutrición deportiva, recuperación)
- Adaptas el nivel técnico al usuario (principiante = explicaciones simples, avanzado = terminología técnica)
- Siempre respondes en español
- Nunca diagnosticas enfermedades ni sustituyes a un médico

Cuando el usuario te pregunta sobre su progreso, usa el contexto proporcionado (métricas semanales, programa activo, objetivo nutricional) para dar respuestas específicas y personalizadas, no genéricas.

Si el usuario pregunta algo fuera del ámbito del fitness y nutrición, redirige amablemente la conversación.

Formato de respuesta: texto natural, conciso. Usa listas solo cuando sea necesario. Máximo 3-4 párrafos.`;

interface ChatContext {
  goal?: string;
  experience?: string;
  weight_kg?: number;
  height_cm?: number;
  age?: number;
  sex?: string;
  active_program?: {
    name: string;
    current_week?: number;
    total_weeks: number;
  };
  latest_week?: {
    sessions_completed: number;
    sessions_planned: number;
    adherence_pct: number;
    avg_weight_7d?: number;
    weight_change_kg?: number;
  };
  nutrition_goal?: {
    calories: number;
    protein_g: number;
    carbs_g: number;
    fat_g: number;
  };
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { conversationId, userMessage, contextJSON } = await req.json();

    if (!userMessage || !conversationId) {
      return errorResponse("conversationId y userMessage son requeridos", 400);
    }

    // Fetch conversation history from Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: historyRows } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .order("created_at", { ascending: true })
      .limit(MAX_HISTORY_MESSAGES);

    const history: Array<{ role: "user" | "assistant"; content: string }> =
      (historyRows ?? []).filter(
        (r: { role: string }) => r.role === "user" || r.role === "assistant"
      ) as Array<{ role: "user" | "assistant"; content: string }>;

    // Build context string to inject in the first user message
    let contextNote = "";
    try {
      const ctx: ChatContext = JSON.parse(contextJSON ?? "{}");
      const parts: string[] = [];

      if (ctx.goal) {
        const goalMap: Record<string, string> = {
          hypertrophy: "ganar músculo",
          strength: "ganar fuerza",
          fat_loss: "perder grasa",
          recomposition: "recomposición",
        };
        parts.push(`Objetivo: ${goalMap[ctx.goal] ?? ctx.goal}`);
      }
      if (ctx.experience) {
        const expMap: Record<string, string> = {
          beginner: "principiante",
          intermediate: "intermedio",
          advanced: "avanzado",
        };
        parts.push(`Experiencia: ${expMap[ctx.experience] ?? ctx.experience}`);
      }
      if (ctx.weight_kg) parts.push(`Peso actual: ${ctx.weight_kg} kg`);
      if (ctx.height_cm) parts.push(`Altura: ${ctx.height_cm} cm`);
      if (ctx.age)       parts.push(`Edad: ${ctx.age} años`);

      if (ctx.active_program) {
        const prog = ctx.active_program;
        const weekInfo = prog.current_week
          ? `semana ${prog.current_week}/${prog.total_weeks}`
          : `${prog.total_weeks} semanas`;
        parts.push(`Programa activo: ${prog.name} (${weekInfo})`);
      }

      if (ctx.latest_week) {
        const w = ctx.latest_week;
        parts.push(
          `Esta semana: ${w.sessions_completed}/${w.sessions_planned} sesiones, adherencia ${w.adherence_pct}%`
        );
        if (w.avg_weight_7d) parts.push(`Peso medio 7d: ${w.avg_weight_7d.toFixed(1)} kg`);
        if (w.weight_change_kg != null) {
          const sign = w.weight_change_kg >= 0 ? "+" : "";
          parts.push(`Cambio de peso: ${sign}${w.weight_change_kg.toFixed(2)} kg/sem`);
        }
      }

      if (ctx.nutrition_goal) {
        const n = ctx.nutrition_goal;
        parts.push(`Objetivo nutricional: ${n.calories} kcal | P:${n.protein_g}g C:${n.carbs_g}g G:${n.fat_g}g`);
      }

      if (parts.length > 0) {
        contextNote = `[Contexto del usuario: ${parts.join(" | ")}]\n\n`;
      }
    } catch {
      // contextJSON inválido — continúa sin contexto
    }

    // Build messages array
    const messages: Array<{ role: "user" | "assistant"; content: string }> = [
      ...history,
    ];

    // If this is the first message (no history), prepend context to user message
    const finalUserMessage =
      history.length === 0 && contextNote
        ? `${contextNote}${userMessage}`
        : userMessage;

    messages.push({ role: "user", content: finalUserMessage });

    const response = await callClaude({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages,
    });

    const assistantMessage = extractText(response);
    const tokensUsed =
      (response.usage?.input_tokens ?? 0) + (response.usage?.output_tokens ?? 0);

    return jsonResponse({ assistantMessage, tokensUsed });
  } catch (err) {
    console.error("ai-chat error:", err);
    return errorResponse(err instanceof Error ? err.message : "Error interno", 500);
  }
});
