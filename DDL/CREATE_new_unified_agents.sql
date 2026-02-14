CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE TABLE IF NOT EXISTS public.new_unified_agents (
    -- Primary Key
    agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core Identity Fields
    full_name TEXT NOT NULL,
    designation TEXT,
    
    -- Multi-value Contact Arrays (NEVER NULL, default empty array)
    emails TEXT[] NOT NULL DEFAULT '{}',
    phone_numbers TEXT[] NOT NULL DEFAULT '{}',
    
    -- Source Attribution
    source_team_id UUID,
    
    -- Data Quality & Governance
    confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    needs_review BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Metadata & Audit Trail
    source_metadata JSONB NOT NULL DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
    
);

alter table public.new_unified_agents
add constraint new_unified_agents_unique_name_team
unique (full_name, source_team_id);

CREATE INDEX IF NOT EXISTS idx_unified_agents_team_id 
    ON public.new_unified_agents(source_team_id);

CREATE INDEX IF NOT EXISTS idx_unified_agents_confidence 
    ON public.new_unified_agents(confidence_score);

CREATE INDEX IF NOT EXISTS idx_unified_agents_needs_review 
    ON public.new_unified_agents(needs_review) 
    WHERE needs_review = TRUE;

-- GIN indexes for array and JSONB columns
CREATE INDEX IF NOT EXISTS idx_unified_agents_emails_gin 
    ON public.new_unified_agents USING GIN(emails);

CREATE INDEX IF NOT EXISTS idx_unified_agents_phones_gin 
    ON public.new_unified_agents USING GIN(phone_numbers);

CREATE INDEX IF NOT EXISTS idx_unified_agents_source_metadata_gin 
    ON public.new_unified_agents USING GIN(source_metadata);

-- Trigram index for fuzzy name matching (optional, for future use)
CREATE INDEX IF NOT EXISTS idx_unified_agents_fullname_trgm 
    ON public.new_unified_agents USING GIN(full_name gin_trgm_ops);

DROP TRIGGER IF EXISTS trg_unified_agents_update_timestamp ON public.new_unified_agents;
CREATE TRIGGER trg_unified_agents_update_timestamp
    BEFORE UPDATE ON public.new_unified_agents
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated_column();

COMMENT ON TABLE public.new_unified_agents IS 
    'Unified master table combining unified_company_member and new_agents with confidence scoring';

COMMENT ON COLUMN public.new_unified_agents.agent_id IS 
    'Surrogate primary key (UUID)';

COMMENT ON COLUMN public.new_unified_agents.full_name IS 
    'Agent full name from source systems';

COMMENT ON COLUMN public.new_unified_agents.emails IS 
    'Array of all known email addresses (deduplicated)';

COMMENT ON COLUMN public.new_unified_agents.phone_numbers IS 
    'Array of all known phone numbers in digit format (deduplicated)';

COMMENT ON COLUMN public.new_unified_agents.confidence_score IS 
    'Match confidence: 100=email match, 90=phone match, 80=name+team, 65=fuzzy name';

COMMENT ON COLUMN public.new_unified_agents.needs_review IS 
    'Flag for manual review when confidence < 70';

COMMENT ON COLUMN public.new_unified_agents.source_metadata IS 
    'JSONB tracking source systems, record IDs, and enrichment history';