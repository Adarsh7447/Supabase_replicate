alter table public.company_info_raw enable row level security;
alter table public.company_info_raw force row level security;

alter table public.unified_company_member enable row level security;
alter table public.unified_company_member force row level security;

alter table public.new_agents enable row level security;
alter table public.new_agents force row level security;

alter table public.new_unified_agents enable row level security;
alter table public.new_unified_agents force row level security;

alter table public.unified_merge_logs enable row level security;
alter table public.unified_merge_logs force row level security;