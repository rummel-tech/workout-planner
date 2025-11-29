// Edge Function: ai-trigger
// Calls external Python AI server after new workouts are uploaded.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  try {
    const body = await req.json();
    const user_id = body.user_id;

    if (!user_id) {
      return new Response("Missing user_id", { status: 400 });
    }

    const aiUrl = Deno.env.get("AI_SERVER_URL") + "/daily";

    const aiResp = await fetch(aiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body.metrics ?? {}),
    });

    const result = await aiResp.json();

    return new Response(JSON.stringify({ status: "ok", ai_result: result }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response("Error", { status: 500 });
  }
});
