/**
 * Edge Function: generate-program
 *
 * Recibe el contexto del usuario y genera un programa de entrenamiento completo
 * usando Claude Opus. La API key de Anthropic nunca sale del servidor.
 *
 * Request  → { userId: string, contextJSON: string }
 * Response → { programJSON: string, explanation: string }
 *
 * contextJSON es un ProgramGenerationContext serializado:
 * { goal, experienceLevel, availableDays, equipment, language }
 *
 * programJSON es un GeneratedProgramDTO serializado:
 * { name, totalWeeks, days: [{ dayOfWeek, name, exercises: [...] }] }
 */

import { callClaude, extractText, extractJSON } from "../_shared/anthropic.ts";
import { handleCors, errorResponse, jsonResponse } from "../_shared/cors.ts";

const MODEL = "claude-opus-4-6";
const MAX_TOKENS = 4096;

const SYSTEM_PROMPT = `Eres un entrenador personal experto en periodización científica del entrenamiento de fuerza e hipertrofia.

Tu tarea es generar un programa de entrenamiento detallado y personalizado basado en el contexto del usuario.

RESPONDE ÚNICAMENTE con un objeto JSON válido con esta estructura EXACTA (sin texto adicional, sin markdown):
{
  "explanation": "Explicación breve del programa y por qué es adecuado para este usuario (2-3 frases)",
  "program": {
    "name": "Nombre descriptivo del programa",
    "totalWeeks": <número entero>,
    "days": [
      {
        "dayOfWeek": <0=lunes, 1=martes, 2=miércoles, 3=jueves, 4=viernes, 5=sábado, 6=domingo>,
        "name": "Nombre del día (ej: Push A, Lower, Full Body)",
        "exercises": [
          {
            "exerciseName": "<nombre del ejercicio en inglés, estándar>",
            "sets": <número entero>,
            "repMin": <número entero>,
            "repMax": <número entero>,
            "rir": <0-4, Reps In Reserve>,
            "restSeconds": <60-300>
          }
        ]
      }
    ]
  }
}

REGLAS OBLIGATORIAS:
1. Usa nombres de ejercicios en inglés estándar (Bench Press, Back Squat, Deadlift, Pull-Up, Overhead Press, etc.)
2. La última semana SIEMPRE es de descarga: mismo número de días pero sets reducidos (-1 por ejercicio) y RIR +2
3. Sigue principios basados en evidencia: MEV/MAV/MRV por grupo muscular, progresión doble, periodización por bloques
4. Para principiantes: 3 días Full Body, series 3x8-12, RIR 2-3
5. Para intermedios: 4 días Upper/Lower o PPL, series 3-4x8-15, RIR 1-2
6. Para avanzados: 5-6 días PPL o especialización, series 4-5x6-15, RIR 0-2
7. Equipamiento "home": solo ejercicios con peso corporal y mancuernas
8. Equipamiento "dumbbells_only": solo mancuernas y peso corporal
9. Equipamiento "full_gym": barras, máquinas y mancuernas
10. NO incluyas texto fuera del JSON`;

interface ProgramGenerationContext {
  goal: string;
  experienceLevel: string;
  availableDays: number;
  equipment: string;
  language?: string;
}

interface GeneratedProgram {
  explanation: string;
  program: {
    name: string;
    totalWeeks: number;
    days: Array<{
      dayOfWeek: number;
      name: string;
      exercises: Array<{
        exerciseName: string;
        sets: number;
        repMin: number;
        repMax: number;
        rir: number;
        restSeconds?: number;
      }>;
    }>;
  };
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { userId, contextJSON } = await req.json();

    if (!contextJSON) {
      return errorResponse("contextJSON es requerido", 400);
    }

    const context: ProgramGenerationContext = JSON.parse(contextJSON);

    const goalLabels: Record<string, string> = {
      hypertrophy: "hipertrofia (ganar músculo)",
      strength: "fuerza máxima",
      fat_loss: "pérdida de grasa (preservando músculo)",
      recomposition: "recomposición corporal",
    };

    const equipmentLabels: Record<string, string> = {
      full_gym: "gimnasio completo (barras, máquinas, mancuernas)",
      home: "casa (solo peso corporal)",
      dumbbells_only: "solo mancuernas",
    };

    const experienceLabels: Record<string, string> = {
      beginner: "principiante (< 1 año entrenando)",
      intermediate: "intermedio (1-3 años entrenando)",
      advanced: "avanzado (> 3 años entrenando)",
    };

    const userPrompt = `Genera un programa de entrenamiento con estas características:

- Objetivo: ${goalLabels[context.goal] ?? context.goal}
- Nivel de experiencia: ${experienceLabels[context.experienceLevel] ?? context.experienceLevel}
- Días de entrenamiento por semana: ${context.availableDays}
- Equipamiento disponible: ${equipmentLabels[context.equipment] ?? context.equipment}
- Idioma de los nombres de días: español
- Idioma de la explicación: español

Incluye entre ${context.availableDays} y ${Math.min(context.availableDays + 2, 7)} semanas de programación progresiva más la semana de descarga final.`;

    const response = await callClaude({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: userPrompt }],
    });

    const text = extractText(response);
    const parsed = extractJSON<GeneratedProgram>(text);

    return jsonResponse({
      programJSON: JSON.stringify(parsed.program),
      explanation: parsed.explanation ?? "",
    });
  } catch (err) {
    console.error("generate-program error:", err);
    return errorResponse(err instanceof Error ? err.message : "Error interno", 500);
  }
});
