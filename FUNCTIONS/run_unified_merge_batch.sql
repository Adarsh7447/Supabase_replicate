create or replace function public.run_unified_merge_batch()
returns void
language plpgsql
security definer
as $$
begin

    with ucm_source as (
        select *
        from public.unified_company_member
        where processed = false
          and team_id is not null
          and member_name is not null
    ),

    na_source as (
        select *
        from public.new_agents
        where team_id is not null
    ),

    matched_candidates as (
        select 
            ucm.id as ucm_id,
            ucm.member_name,
            ucm.member_designation,
            ucm.email_normalized,
            ucm.phone_normalized,
            ucm.team_id,
            na.full_name,
            na.email_clean,
            na.phone_digits,

            case 
                when ucm.email_normalized && coalesce(na.email_clean, '{}'::text[]) then 100
                when ucm.phone_normalized && coalesce(na.phone_digits, '{}'::text[]) then 90
                when lower(ucm.member_name) = lower(na.full_name)
                     and ucm.team_id = na.team_id then 80
                when similarity(ucm.member_name, na.full_name) > 0.8
                     and ucm.team_id = na.team_id then 60
                else null
            end as confidence_score

        from ucm_source ucm
        left join na_source na
          on ucm.team_id = na.team_id
    ),

    best_matches as (
        select distinct on (ucm_id)
            *
        from matched_candidates
        where confidence_score is not null
        order by ucm_id, confidence_score desc
    ),

    new_records as (
        select
            ucm.id as ucm_id,
            ucm.member_name,
            ucm.member_designation,
            ucm.email_normalized,
            ucm.phone_normalized,
            ucm.team_id,
            0 as confidence_score
        from ucm_source ucm
        where not exists (
            select 1
            from best_matches bm
            where bm.ucm_id = ucm.id
        )
    ),

    combined as (
        select
            coalesce(bm.full_name, bm.member_name) as full_name,
            bm.member_designation as designation,
            array_merge_unique(
                coalesce(bm.email_clean, '{}'::text[]),
                coalesce(bm.email_normalized, '{}'::text[])
            ) as emails,
            array_merge_unique(
                coalesce(bm.phone_digits, '{}'::text[]),
                coalesce(bm.phone_normalized, '{}'::text[])
            ) as phone_numbers,
            bm.team_id as source_team_id,
            bm.confidence_score,
            (bm.confidence_score <= 60) as needs_review,
            bm.ucm_id
        from best_matches bm

        union all

        select
            nr.member_name,
            nr.member_designation,
            coalesce(nr.email_normalized, '{}'::text[]),
            coalesce(nr.phone_normalized, '{}'::text[]),
            nr.team_id,
            nr.confidence_score,
            true,
            nr.ucm_id
        from new_records nr
    ),

    final_dedup as (
        select distinct on (full_name, source_team_id)
            *
        from combined
        order by full_name, source_team_id, confidence_score desc
    ),

    upserted as (
        insert into public.new_unified_agents (
            full_name,
            designation,
            emails,
            phone_numbers,
            source_team_id,
            confidence_score,
            needs_review
        )
        select
            full_name,
            designation,
            emails,
            phone_numbers,
            source_team_id,
            confidence_score,
            needs_review
        from final_dedup

        on conflict (full_name, source_team_id)
        do update set
            emails = array_merge_unique(
                new_unified_agents.emails,
                excluded.emails
            ),
            phone_numbers = array_merge_unique(
                new_unified_agents.phone_numbers,
                excluded.phone_numbers
            ),
            confidence_score = greatest(
                new_unified_agents.confidence_score,
                excluded.confidence_score
            ),
            needs_review = case
                when greatest(
                    new_unified_agents.confidence_score,
                    excluded.confidence_score
                ) > 60 then false
                else true
            end,
            last_updated = now()
        returning full_name
    )

    update public.unified_company_member
    set processed = true
    where id in (
        select ucm_id from final_dedup
    );

end;
$$;


