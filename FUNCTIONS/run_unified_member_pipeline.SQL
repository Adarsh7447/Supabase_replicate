create or replace function public.run_unified_member_pipeline()
returns void
language plpgsql
security definer
as $$
begin

    insert into public.unified_company_member (
        research_uuid,
        team_id,
        website,
        domain,
        member_name,
        email_normalized,
        phone_normalized,
        member_designation,
        record_hash,
        source_position
    )
    with flattened as (
        select
            r.research_uuid,
            r.team_id,
            r.website,
            lower(split_part(r.website, '/', 1)) as domain,
            m,
            ordinality as source_position
        from bronze.company_info_raw r
        cross join lateral jsonb_array_elements(r.team_members)
        with ordinality as t(m, ordinality)
        where r.team_members is not null
          and jsonb_typeof(r.team_members) = 'array'
    ),

    cleaned as (
        select
            research_uuid,
            team_id,
            website,
            domain,

            nullif(trim(m->>'name'), '') as member_name,

            -- Normalize email into array
            array(
                select distinct lower(trim(e))
                from unnest(
                    regexp_split_to_array(
                        coalesce(m->>'email',''),
                        '\s*[,;/]\s*'
                    )
                ) as e
                where trim(e) <> ''
            ) as email_array,

            -- Normalize phone numbers
            array(
                select distinct cleaned_phone
                from (
                    select regexp_replace(
                               regexp_replace(trim(p), '(x|ext).*$', '', 'i'),
                               '[^0-9]',
                               '',
                               'g'
                           ) as cleaned_phone
                    from unnest(
                        regexp_split_to_array(
                            coalesce(m->>'phone',''),
                            '\s*[/,;]\s*'
                        )
                    ) as p
                ) s
                where cleaned_phone <> ''
            ) as phone_array,

            nullif(trim(m->>'designation'), '') as member_designation,
            source_position

        from flattened
    )

    select
        research_uuid,
        team_id,
        website,
        domain,
        member_name,
        email_array,
        phone_array,
        member_designation,

        -- Deterministic hash for deduplication
        md5(
            coalesce(array_to_string(email_array,''),'') ||
            coalesce(array_to_string(phone_array,''),'') ||
            coalesce(member_name,'')
        ) as record_hash,

        source_position

    from cleaned
    where member_name is not null

    on conflict (record_hash) do nothing;

end;
$$;
