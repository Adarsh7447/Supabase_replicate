Execute this first: /Users/adarshbadjate/code/Supabase_replicate/SUPABASE_EDGE_FUNCTIONS/service_role_policy.sql

Create Edge Functions in Supabase:
Dashboard → Edge Functions → Create New Function

Functions:
1. new_unfied_member
2. run_new_unified_agents_pipeline

JWT Verification:
Edge Function Settings →
- Verify JWT with legacy secret → OFF

Reason:
    Authentication handled manually inside function using email + password.

Edge Function Security Flow
- Each function:
    1. Accepts email and password
    2. Authenticates using Supabase Auth (anon key)
    3. On success:
        Uses service_role key
        Executes DB function (RPC)
    4. Returns execution status

Secrets Configuration (UI-Based)
Dashboard → Edge Functions → Secrets
Added:
    1. SUPABASE_URL
    2. SUPABASE_ANON_KEY
    3. SUPABASE_SERVICE_ROLE_KEY

Keys are not exposed publicly.
- Execution Order
    1. Step 1 – Populate Unified Member Table
    2. Service Role key is stored in Edge Function Secrets only.


-- first run this 
    curl --location 'https://lpebzfhrsgcmuxgblbal.functions.supabase.co/new_unfied_member' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "email": "{email}",
    "password": "{password}"
    }'

-- second priority 
    curl --location 'https://lpebzfhrsgcmuxgblbal.functions.supabase.co/run_new_unified_agents_pipeline' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "email": "{email}",
    "password": "{password}"
    }'

