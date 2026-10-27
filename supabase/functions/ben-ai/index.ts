import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") || "";
const GROQ_CHAT_MODEL = Deno.env.get("GROQ_CHAT_MODEL") || "openai/gpt-oss-20b";
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

    const { action, query, notifications } = await req.json();

    const prompt = `
You are Ben, an intelligent mobile personal notification assistant with a futuristic Ben 10 personality.
Your task is to summarize the user's notifications and answer their questions without making them open every application.

Notifications context:
${JSON.stringify(notifications || [], null, 2)}

User request / query:
${query || "Summarize what notifications I missed and highlight what needs attention."}

Instructions:
1. Provide a concise, conversational summary identifying total counts, app breakdown, and important deadlines/reminders.
2. Highlight high-priority notifications (deadlines, urgent payments, meetings).
3. Return STRICTLY valid JSON with this format:
{
  "summary": "conversational summary string",
  "priorities": [
    {
      "source": "App Name",
      "priority": "high" | "normal" | "low",
      "reason": "short explanation"
    }
  ],
  "groups": [
    {
      "source": "App Name",
      "count": 1,
      "summary": "short summary"
    }
  ]
}
`;

    const groqResponse = await fetch(`${GROQ_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_CHAT_MODEL,
        messages: [
          { role: "system", content: "You are Ben, a helpful mobile notification AI assistant. Always output JSON." },
          { role: "user", content: prompt }
        ],
        response_format: { type: "json_object" },
        temperature: 0.2,
      }),
    });

    if (!groqResponse.ok) {
      const errText = await groqResponse.text();
      return new Response(JSON.stringify({ error: "Groq API error", details: errText }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const groqData = await groqResponse.json();
    const content = groqData.choices[0]?.message?.content;
    const parsed = JSON.parse(content || "{}");

    return new Response(JSON.stringify(parsed), {
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
