CREATE TABLE IF NOT EXISTS public.new_agents (
    supabase_uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT,
    first_name TEXT,
    last_name TEXT,    -- Raw collected emails
    email JSONB DEFAULT '[]'::jsonb,
    email_clean JSONB DEFAULT '[]'::jsonb,
    phone JSONB DEFAULT '[]'::jsonb,
    phone_digits JSONB DEFAULT '[]'::jsonb,
    team_id UUID,
    social_links JSONB DEFAULT '{}'::jsonb,
    facebook TEXT,
    instagram TEXT,
    social_score TEXT,
    brokerage TEXT,
    crm JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.new_agents IS 
    'Master table for agent data from various sources';