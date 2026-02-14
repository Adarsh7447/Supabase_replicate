-- Execute this first before defining edge functions in supabase: 

revoke all on function public.run_unified_merge_batch() from public;
grant execute on function public.run_unified_merge_batch() to service_role;

revoke all on function public.run_unified_member_pipeline() from public;
grant execute on function public.run_unified_member_pipeline() to service_role;