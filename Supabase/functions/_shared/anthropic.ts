/**
 * Wrapper mínimo para la API de Mensajes de Anthropic.
 * Evita dependencias externas: usa fetch nativo de Deno.
 */

export const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
export const ANTHROPIC_VERSION = "2023-06-01";

export type Role = "user" | "assistant";

export interface Message {
  role: Role;
  content: string;
}

export interface AnthropicRequest {
  model: string;
  max_tokens: number;
  system?: string;
  messages: Message[];
}

export interface AnthropicResponse {
  id: string;
  content: Array<{ type: string; text: string }>;
  usage: { input_tokens: number; output_tokens: number };
}

export async function callClaude(req: AnthropicRequest): Promise<AnthropicResponse> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY no está configurada");

  const response = await fetch(ANTHROPIC_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
    },
    body: JSON.stringify(req),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Anthropic API error ${response.status}: ${error}`);
  }

  return response.json() as Promise<AnthropicResponse>;
}

/** Extrae el texto de la primera respuesta de contenido. */
export function extractText(response: AnthropicResponse): string {
  return response.content.find((c) => c.type === "text")?.text ?? "";
}

/** Extrae y parsea JSON del texto de respuesta (busca el primer objeto JSON). */
export function extractJSON<T>(text: string): T {
  // Busca el primer { o [ en el texto por si Claude añade texto antes del JSON
  const start = text.indexOf("{") !== -1 ? text.indexOf("{") : text.indexOf("[");
  if (start === -1) throw new Error("No se encontró JSON en la respuesta");
  const jsonStr = text.slice(start);
  return JSON.parse(jsonStr) as T;
}
