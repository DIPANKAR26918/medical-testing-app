-- Produce a stable, explainable recommendation feed from compact on-device
-- interactions.
--
-- Browsing events are intentionally passed as a bounded JSON payload and are
-- never persisted in Postgres. This keeps the discovery model responsive
-- without creating a server-side health-interest event log.

create or replace function public.get_personalized_medical_test_candidates(
  p_signals jsonb default '[]'::jsonb,
  p_age integer default null,
  p_gender text default null,
  p_limit integer default 10
)
returns table (
  id uuid,
  test_code text,
  name_sheet text,
  common_name text,
  mrp numeric,
  reporting_time text,
  sample_type_volume text,
  category text,
  body_system text,
  test_type text,
  purpose text,
  preparation text,
  age_recommendation text,
  home_collection_available boolean,
  lab_visit_required boolean,
  special_handling_required boolean,
  is_popular boolean,
  min_age integer,
  max_age integer,
  gender text,
  parameter_count integer,
  included_parameters text[],
  sample_source text,
  sample_source_label text,
  sample_collection_note text,
  recommendation_score double precision,
  recommendation_strategy text,
  recommendation_badge text,
  recommendation_reason text,
  model_version text
)
language sql
stable
security invoker
set search_path = ''
as $$
  with request as materialized (
    select
      case
        when jsonb_typeof(coalesce(p_signals, '[]'::jsonb)) = 'array'
          then coalesce(p_signals, '[]'::jsonb)
        else '[]'::jsonb
      end as signals,
      case
        when p_age between 0 and 130 then p_age
        else null
      end as age,
      case lower(btrim(coalesce(p_gender, '')))
        when 'male' then 'male'
        when 'female' then 'female'
        else null
      end as gender,
      least(greatest(coalesce(p_limit, 10), 1), 20) as result_limit,
      (select auth.uid()) as user_id
  ),
  raw_local_signals as materialized (
    select
      case
        when signal.item ->> 'test_id'
          ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
          then (signal.item ->> 'test_id')::uuid
        else null
      end as test_id,
      least(
        case
          when signal.item ->> 'detail_views' ~ '^[0-9]+$'
            then (signal.item ->> 'detail_views')::integer
          else 0
        end,
        20
      ) as detail_views,
      least(
        case
          when signal.item ->> 'search_opens' ~ '^[0-9]+$'
            then (signal.item ->> 'search_opens')::integer
          else 0
        end,
        20
      ) as search_opens,
      least(
        case
          when signal.item ->> 'category_opens' ~ '^[0-9]+$'
            then (signal.item ->> 'category_opens')::integer
          else 0
        end,
        20
      ) as category_opens,
      least(
        case
          when signal.item ->> 'recommendation_opens' ~ '^[0-9]+$'
            then (signal.item ->> 'recommendation_opens')::integer
          else 0
        end,
        20
      ) as recommendation_opens,
      least(
        case
          when signal.item ->> 'booking_starts' ~ '^[0-9]+$'
            then (signal.item ->> 'booking_starts')::integer
          else 0
        end,
        20
      ) as booking_starts,
      least(
        case
          when signal.item ->> 'booking_confirmations' ~ '^[0-9]+$'
            then (signal.item ->> 'booking_confirmations')::integer
          else 0
        end,
        20
      ) as booking_confirmations,
      case
        when signal.item ->> 'last_interacted_at'
          ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'
          then (signal.item ->> 'last_interacted_at')::timestamptz
        else null
      end as last_interacted_at
    from request
    cross join lateral jsonb_array_elements(request.signals)
      with ordinality as signal(item, position)
    where signal.position <= 40
  ),
  local_signals as materialized (
    select
      raw_signal.test_id,
      pg_catalog.ln(
        1
        + greatest(
            raw_signal.detail_views * 2.5
            + raw_signal.search_opens * 4.0
            + raw_signal.category_opens * 2.0
            + raw_signal.recommendation_opens * 1.25
            + raw_signal.booking_starts * 7.0
            + raw_signal.booking_confirmations * 10.0,
            0
          )
      )
      * pg_catalog.exp(
          -least(
            greatest(
              extract(
                epoch from (
                  now()
                  - coalesce(raw_signal.last_interacted_at, now() - interval '90 days')
                )
              ) / 86400.0,
              0
            ),
            90
          ) / 30.0
        ) as signal_score,
      raw_signal.last_interacted_at,
      raw_signal.booking_confirmations
    from raw_local_signals as raw_signal
    where raw_signal.test_id is not null
      and raw_signal.last_interacted_at >= now() - interval '90 days'
      and (
        raw_signal.detail_views
        + raw_signal.search_opens
        + raw_signal.category_opens
        + raw_signal.recommendation_opens
        + raw_signal.booking_starts
        + raw_signal.booking_confirmations
      ) > 0
  ),
  combined_signals as materialized (
    select
      local_signal.test_id,
      sum(local_signal.signal_score) as local_score,
      sum(local_signal.signal_score) as total_score,
      max(local_signal.last_interacted_at) as last_interacted_at,
      sum(local_signal.booking_confirmations) as booking_confirmations
    from local_signals as local_signal
    group by local_signal.test_id
  ),
  anchors as materialized (
    select
      combined_signal.test_id,
      combined_signal.local_score,
      combined_signal.total_score,
      combined_signal.last_interacted_at,
      combined_signal.booking_confirmations,
      coalesce(
        nullif(btrim(medical_test.common_name), ''),
        medical_test.name_sheet
      ) as display_name,
      coalesce(
        nullif(btrim(medical_test.category), ''),
        'Specialised Tests'
      ) as category,
      nullif(btrim(medical_test.body_system), '') as body_system,
      medical_test.test_type
    from combined_signals as combined_signal
    inner join public.medical_tests as medical_test
      on medical_test.id = combined_signal.test_id
     and medical_test.is_active = true
  ),
  category_affinity as materialized (
    select
      anchor.category,
      pg_catalog.ln(1 + sum(anchor.total_score)) as affinity
    from anchors as anchor
    group by anchor.category
  ),
  body_affinity as materialized (
    select
      anchor.body_system,
      pg_catalog.ln(1 + sum(anchor.total_score)) as affinity
    from anchors as anchor
    where anchor.body_system is not null
    group by anchor.body_system
  ),
  type_affinity as materialized (
    select
      anchor.test_type,
      pg_catalog.ln(1 + sum(anchor.total_score)) as affinity
    from anchors as anchor
    group by anchor.test_type
  ),
  recently_booked as materialized (
    select anchor.test_id
    from anchors as anchor
    where anchor.booking_confirmations > 0
      and anchor.last_interacted_at >= now() - interval '30 days'
  ),
  eligible_candidates as materialized (
    select
      medical_test.id,
      medical_test.test_code,
      medical_test.name_sheet,
      medical_test.common_name,
      medical_test.mrp,
      medical_test.reporting_time,
      medical_test.sample_type_volume,
      coalesce(
        nullif(btrim(medical_test.category), ''),
        'Specialised Tests'
      ) as category,
      medical_test.body_system,
      medical_test.test_type,
      medical_test.purpose,
      medical_test.preparation,
      medical_test.age_recommendation,
      medical_test.home_collection_available,
      medical_test.lab_visit_required,
      medical_test.special_handling_required,
      medical_test.is_popular,
      medical_test.min_age,
      medical_test.max_age,
      medical_test.gender,
      medical_test.parameter_count,
      medical_test.included_parameters,
      medical_test.sample_source,
      medical_test.sample_source_label,
      medical_test.sample_collection_note,
      coalesce(direct_signal.local_score, 0) as direct_local_score,
      coalesce(category_score.affinity, 0) as category_score,
      coalesce(body_score.affinity, 0) as body_score,
      coalesce(type_score.affinity, 0) as type_score,
      related_anchor.display_name as anchor_name,
      (
        coalesce(direct_signal.local_score, 0) * 2.60
        + coalesce(category_score.affinity, 0) * 1.10
        + coalesce(body_score.affinity, 0) * 0.85
        + coalesce(type_score.affinity, 0) * 0.20
        + case when medical_test.is_popular then 0.80 else 0 end
        + case
            when nullif(btrim(medical_test.common_name), '') is not null
              then 0.10
            else 0
          end
        + case
            when medical_test.home_collection_available
              and not medical_test.lab_visit_required
              then 0.08
            else 0
          end
        + (
            mod(
              mod(
                pg_catalog.hashtextextended(
                  medical_test.id::text
                  || ':'
                  || coalesce(request.user_id::text, 'guest')
                  || ':'
                  || current_date::text,
                  0
                ),
                1000
              ) + 1000,
              1000
            )::double precision / 1000.0
          ) * 0.24
      )::double precision as score
    from public.medical_tests as medical_test
    cross join request
    left join combined_signals as direct_signal
      on direct_signal.test_id = medical_test.id
    left join category_affinity as category_score
      on category_score.category = coalesce(
        nullif(btrim(medical_test.category), ''),
        'Specialised Tests'
      )
    left join body_affinity as body_score
      on body_score.body_system = nullif(btrim(medical_test.body_system), '')
    left join type_affinity as type_score
      on type_score.test_type = medical_test.test_type
    left join lateral (
      select anchor.display_name
      from anchors as anchor
      where anchor.test_id <> medical_test.id
        and (
          (
            anchor.body_system is not null
            and anchor.body_system = nullif(btrim(medical_test.body_system), '')
          )
          or anchor.category = coalesce(
            nullif(btrim(medical_test.category), ''),
            'Specialised Tests'
          )
        )
      order by
        (
          anchor.body_system is not null
          and anchor.body_system = nullif(btrim(medical_test.body_system), '')
        ) desc,
        anchor.total_score desc,
        anchor.last_interacted_at desc
      limit 1
    ) as related_anchor on true
    where medical_test.is_active = true
      and (
        request.age is null
        or medical_test.min_age is null
        or request.age >= medical_test.min_age
      )
      and (
        request.age is null
        or medical_test.max_age is null
        or request.age <= medical_test.max_age
      )
      and (
        request.gender is null
        or medical_test.gender = 'any'
        or medical_test.gender = request.gender
      )
      and not exists (
        select 1
        from recently_booked
        where recently_booked.test_id = medical_test.id
      )
      and (
        not exists (select 1 from anchors)
        or direct_signal.test_id is not null
        or category_score.category is not null
        or body_score.body_system is not null
        or medical_test.is_popular
      )
      and (
        exists (select 1 from anchors)
        or medical_test.is_popular
      )
  ),
  explained_candidates as materialized (
    select
      candidate.*,
      case
        when candidate.direct_local_score > 0 then 'continue'
        when candidate.body_score > 0 and candidate.anchor_name is not null
          then 'related_body'
        when candidate.category_score > 0 and candidate.anchor_name is not null
          then 'related_category'
        when candidate.is_popular then 'popular'
        else 'discover'
      end as strategy,
      row_number() over (
        partition by candidate.category
        order by candidate.score desc, candidate.name_sheet
      ) as category_rank
    from eligible_candidates as candidate
  ),
  diversified as materialized (
    select explained_candidate.*
    from explained_candidates as explained_candidate
    where explained_candidate.category_rank <= 2
    order by explained_candidate.score desc, explained_candidate.name_sheet
    limit (select request.result_limit from request)
  )
  select
    candidate.id,
    candidate.test_code,
    candidate.name_sheet,
    candidate.common_name,
    candidate.mrp,
    candidate.reporting_time,
    candidate.sample_type_volume,
    candidate.category,
    candidate.body_system,
    candidate.test_type,
    candidate.purpose,
    candidate.preparation,
    candidate.age_recommendation,
    candidate.home_collection_available,
    candidate.lab_visit_required,
    candidate.special_handling_required,
    candidate.is_popular,
    candidate.min_age,
    candidate.max_age,
    candidate.gender,
    candidate.parameter_count,
    candidate.included_parameters,
    candidate.sample_source,
    candidate.sample_source_label,
    candidate.sample_collection_note,
    candidate.score,
    candidate.strategy,
    case candidate.strategy
      when 'continue' then 'Continue'
      when 'related_body' then 'Related'
      when 'related_category' then 'More for you'
      when 'popular' then 'Popular'
      else 'Discover'
    end,
    case candidate.strategy
      when 'continue' then 'Continue exploring a test you recently opened.'
      when 'related_body' then
        'Related to ' || candidate.anchor_name || ' from your recent activity.'
      when 'related_category' then
        'More from ' || candidate.category || ' based on what you explored.'
      when 'popular' then 'A popular catalogue test worth comparing.'
      else 'A fresh pick from ' || candidate.category || '.'
    end,
    'hybrid-content-v2'
  from diversified as candidate
  order by candidate.score desc, candidate.name_sheet;
$$;

comment on function public.get_personalized_medical_test_candidates(
  jsonb,
  integer,
  text,
  integer
) is
'Ranks active tests with event-strength weighting, recency decay, content affinity, past-booking affinity, stable exploration, recent-booking suppression and category diversity. Browsing signals are processed ephemerally and are not stored.';

revoke all on function public.get_personalized_medical_test_candidates(
  jsonb,
  integer,
  text,
  integer
) from public, anon;

grant execute on function public.get_personalized_medical_test_candidates(
  jsonb,
  integer,
  text,
  integer
) to anon, authenticated;
