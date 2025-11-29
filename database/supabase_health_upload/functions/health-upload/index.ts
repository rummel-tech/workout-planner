// Deno Edge Function: health-upload
// Receives HealthKit workout data and inserts into Supabase DB

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    const body = await req.json();
    const { user_id, workouts } = body;

    if (!user_id || !workouts) {
      return new Response("Missing fields", { status: 400 });
    }

    const { error } = await supabase
      .from("workouts_raw")
      .insert(
        workouts.map((w: any) => ({
          user_id,
          source: "healthkit",
          workout_type: w.type,
          start_time: new Date(w.start * 1000).toISOString(),
          end_time: new Date(w.end * 1000).toISOString(),
          duration_seconds: Math.round(w.end - w.start),
          calories: w.calories,
          distance_meters: w.distance,
          raw_json: w
        }))
      );

    if (error) {
      console.error("Supabase insert error:", error);
      return new Response("Insert failed", { status: 500 });
    }

    return new Response(JSON.stringify({ status: "success" }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Error:", err);
    return new Response("Invalid JSON", { status: 400 });
  }
});
