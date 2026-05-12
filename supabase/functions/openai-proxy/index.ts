// Naplet - OpenAI Proxy Edge Function
//
// Recebe requisições do app iOS autenticadas via Supabase JWT,
// valida o usuário, e encaminha a chamada para a OpenAI API
// usando a chave armazenada como secret no Supabase.
//
// O app NUNCA tem acesso à chave OpenAI. Apenas o servidor.
//
// Endpoint: POST https://exwqjrdlanlqcthwjflt.supabase.co/functions/v1/openai-proxy
// Header obrigatório: Authorization: Bearer <SUPABASE_USER_JWT>
// Body: payload completo de chat completion da OpenAI (model, messages, etc)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const OPENAI_ENDPOINT = "https://api.openai.com/v1/chat/completions";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json",
    },
  });
}

serve(async (req: Request): Promise<Response> => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // Only POST allowed for actual proxy calls
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Validate required server-side secrets are present
  if (!OPENAI_API_KEY || !SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error("[openai-proxy] Missing required env vars");
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  // Validate JWT from caller (Supabase user)
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing or invalid Authorization header" }, 401);
  }

  // Resolve user from JWT
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) {
    console.warn("[openai-proxy] Auth failed:", userError?.message);
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  // Parse request body (OpenAI chat completion payload)
  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // Forward to OpenAI
  let openaiResponse: Response;
  try {
    openaiResponse = await fetch(OPENAI_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(body),
    });
  } catch (e) {
    console.error("[openai-proxy] OpenAI fetch failed:", e);
    return jsonResponse({ error: "Upstream OpenAI request failed" }, 502);
  }

  // Pass-through response (body, status). Streaming-friendly: don't consume body.
  return new Response(openaiResponse.body, {
    status: openaiResponse.status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": openaiResponse.headers.get("Content-Type") ?? "application/json",
    },
  });
});
