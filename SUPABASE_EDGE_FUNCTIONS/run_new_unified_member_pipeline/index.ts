import { createClient } from "npm:@supabase/supabase-js@2"

Deno.serve(async (req) => {
  try {

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

    // 1️⃣ Create client with anon key
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    )

    // 2️⃣ Authenticate user
    const { data, error } =
      await authClient.auth.signInWithPassword({
        email,
        password
      })

    if (error) {
      return new Response(
        JSON.stringify({ login_error: error.message }),
        { status: 401 }
      )
    }


    // OPTIONAL: restrict to specific admin email
    // if (data.user.email !== "admin@yourdomain.com") {
    //   return new Response(
    //     JSON.stringify({ error: "Forbidden" }),
    //     { status: 403 }
    //   )
    // }

    // 3️⃣ Use service role to execute DB function
    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { error: rpcError } =
      await adminClient.rpc("run_unified_member_pipeline")

    if (rpcError) {
      return new Response(
        JSON.stringify({ error: rpcError.message }),
        { status: 500 }
      )
    }

    return new Response(
      JSON.stringify({
        status: "Pipeline executed successfully",
        executed_by: data.user.email
      }),
      { status: 200 }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500 }
    )
  }
})
