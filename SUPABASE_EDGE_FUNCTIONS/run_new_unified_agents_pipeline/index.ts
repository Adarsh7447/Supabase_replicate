import { createClient } from "npm:@supabase/supabase-js@2"

Deno.serve(async (req) => {
  try {

    // Allow only POST
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405 }
      )
    }

    const body = await req.json()
    const { email, password } = body

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: "Email and password required" }),
        { status: 400 }
      )
    }

    // 1️⃣ Authenticate user with anon key
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    )

    const { data: authData, error: authError } =
      await authClient.auth.signInWithPassword({
        email,
        password
      })

    if (authError) {
      return new Response(
        JSON.stringify({ login_error: authError.message }),
        { status: 401 }
      )
    }

    // OPTIONAL: restrict to specific admin email
    // if (authData.user.email !== "admin@yourdomain.com") {
    //   return new Response(
    //     JSON.stringify({ error: "Forbidden" }),
    //     { status: 403 }
    //   )
    // }

    // 2️⃣ Create service-role client
    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // 3️⃣ Execute merge function
    const { error: rpcError } =
      await adminClient.rpc("run_unified_merge_batch")

    if (rpcError) {
      return new Response(
        JSON.stringify({ error: rpcError.message }),
        { status: 500 }
      )
    }

    // 4️⃣ Fetch latest execution log
    const { data: logData, error: logError } =
      await adminClient
        .from("unified_merge_logs")
        .select("*")
        .order("started_at", { ascending: false })
        .limit(1)
        .single()

    if (logError) {
      return new Response(
        JSON.stringify({
          status: "Pipeline executed but failed to fetch logs",
          log_error: logError.message
        }),
        { status: 500 }
      )
    }

    // 5️⃣ Return success response
    return new Response(
      JSON.stringify({
        status: "Pipeline executed successfully",
        executed_by: authData.user.email,
        execution_log: logData
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" }
      }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: err instanceof Error ? err.message : String(err)
      }),
      { status: 500 }
    )
  }
})
