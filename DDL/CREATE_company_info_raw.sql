-- company_info_raw table 
CREATE TABLE IF NOT EXISTS bronze.company_info_raw (
    research_uuid UUID PRIMARY KEY,
    team_id UUID NULL,
    website TEXT NULL,
    team_page_url TEXT NULL,
    team_members JSONB NULL,
    research_email TEXT NULL,
    research_phone TEXT NULL,
    analysis TEXT NULL,
    sample_master_agent_uuid UUID NULL,
    master_brokerage_name TEXT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

