# Despliegue de Edge Functions

## Requisitos

- [Supabase CLI](https://supabase.com/docs/guides/cli) instalado
- Proyecto Supabase creado en [supabase.com](https://supabase.com)
- API key de Anthropic (consíguelo en [console.anthropic.com](https://console.anthropic.com))

---

## 1. Configurar credenciales en la app iOS

En `AICoach/Utils/Constants.swift`, reemplaza los placeholders:

```swift
static let supabaseURL     = "https://TU_PROJECT_ID.supabase.co"
static let supabaseAnonKey = "TU_ANON_KEY"  // Settings → API → anon public
```

---

## 2. Aplicar migraciones SQL

Desde el panel de Supabase → SQL Editor, ejecuta en orden:

1. `001_initial_schema.sql`
2. `002_rls_policies.sql`

---

## 3. Configurar el secreto de Anthropic

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

Verifica que esté guardado:

```bash
supabase secrets list
```

---

## 4. Desplegar las Edge Functions

```bash
# Login (solo la primera vez)
supabase login

# Vincula con tu proyecto (usa el Reference ID de Settings → General)
supabase link --project-ref TU_PROJECT_ID

# Despliega las tres funciones
supabase functions deploy generate-program
supabase functions deploy ai-chat
supabase functions deploy weekly-analysis
```

---

## 5. Verificar el despliegue

En el panel de Supabase → Edge Functions verás las tres funciones activas.

Puedes probarlas con curl (reemplaza `TOKEN` por un access token válido):

```bash
# Test generate-program
curl -X POST https://TU_PROJECT_ID.supabase.co/functions/v1/generate-program \
  -H "Authorization: Bearer TOKEN" \
  -H "apikey: TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "contextJSON": "{\"goal\":\"hypertrophy\",\"experienceLevel\":\"intermediate\",\"availableDays\":4,\"equipment\":\"full_gym\",\"language\":\"es\"}"
  }'

# Test ai-chat
curl -X POST https://TU_PROJECT_ID.supabase.co/functions/v1/ai-chat \
  -H "Authorization: Bearer TOKEN" \
  -H "apikey: TU_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-conv-id",
    "userMessage": "¿Cómo voy con mi progreso?",
    "contextJSON": "{\"goal\":\"hypertrophy\",\"weight_kg\":80}"
  }'
```

---

## Logs en tiempo real

```bash
supabase functions logs generate-program --tail
supabase functions logs ai-chat --tail
supabase functions logs weekly-analysis --tail
```

---

## Variables de entorno disponibles automáticamente

Supabase inyecta estas variables en todas las Edge Functions sin configuración adicional:

| Variable | Descripción |
|----------|-------------|
| `SUPABASE_URL` | URL de tu proyecto |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave de servicio (acceso total, sin RLS) |
| `SUPABASE_ANON_KEY` | Clave anónima pública |

Solo necesitas configurar manualmente `ANTHROPIC_API_KEY`.
