import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") || "";
const GROQ_TRANSCRIPTION_MODEL = Deno.env.get("GROQ_TRANSCRIPTION_MODEL") || "whisper-large-v3-turbo";
const GROQ_BASE_URL = Deno.env.get("GROQ_API_BASE_URL") || "https://api.groq.com/openai/v1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const formData = await req.formData();
    const audioFile = formData.get("file");

    if (!audioFile || !(audioFile instanceof File)) {
      return new Response(JSON.stringify({ error: "No audio file provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const groqFormData = new FormData();
    groqFormData.append("file", audioFile);
    groqFormData.append("model", GROQ_TRANSCRIPTION_MODEL);
    groqFormData.append("response_format", "json");

    const groqResponse = await fetch(`${GROQ_BASE_URL}/audio/transcriptions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
      },
      body: groqFormData,
    });

    if (!groqResponse.ok) {
      const errText = await groqResponse.text();
      return new Response(JSON.stringify({ error: "Groq Whisper API error", details: errText }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await groqResponse.json();
    return new Response(JSON.stringify({ text: result.text || "" }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
