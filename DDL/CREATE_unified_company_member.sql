create table public.unified_company_member (
    id uuid default gen_random_uuid() primary key,
    research_uuid uuid,
    team_id uuid,

    website text,
    domain text,

    member_name text,
    email_normalized text[],
    phone_normalized text[],
    member_designation text,

    record_hash text unique,
    source_position int,
    created_at timestamptz default now(),
    processed boolean default false
);

comment on table public.unified_company_member is
'Table containing flattened and normalized company + team member data derived from company_info_raw table. Designed for query performance and deduplication.';




