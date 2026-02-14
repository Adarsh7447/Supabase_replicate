
--- CREATE TABLE STATEMENT
create table if not exists public.unified_merge_logs (
    id bigserial primary key,
    started_at timestamptz not null default now(),
    finished_at timestamptz,
    total_processed int,
    status text not null,
    error_message text
);