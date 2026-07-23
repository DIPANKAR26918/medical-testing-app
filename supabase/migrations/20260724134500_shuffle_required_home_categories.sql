create or replace function public.get_home_medical_test_feed(
  p_category_limit integer default 8,
  p_tests_per_category integer default 4
)
returns jsonb
language sql
volatile
security invoker
set search_path = ''
as $$
  with feed_limits as materialized (
    select
      least(greatest(coalesce(p_category_limit, 8), 5), 12) as category_limit,
      least(greatest(coalesce(p_tests_per_category, 4), 1), 6) as tests_per_category
  ),
  eligible_tests as materialized (
    select
      medical_test.id,
      medical_test.test_code,
      medical_test.name_sheet,
      medical_test.common_name,
      medical_test.mrp,
      medical_test.reporting_time,
      medical_test.sample_type_volume,
      coalesce(nullif(btrim(medical_test.category), ''), 'Specialised Tests') as category,
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
      medical_test.sample_collection_note
    from public.medical_tests as medical_test
    where medical_test.is_active = true
  ),
  category_totals as materialized (
    select
      eligible_test.category,
      count(*) as total_count,
      count(*) filter (where eligible_test.is_popular) as popular_count,
      count(*) filter (
        where nullif(btrim(eligible_test.common_name), '') is not null
          or nullif(btrim(eligible_test.purpose), '') is not null
          or nullif(btrim(eligible_test.preparation), '') is not null
      ) as enriched_count,
      count(*) filter (
        where eligible_test.home_collection_available
          and not eligible_test.lab_visit_required
      ) as home_collection_count,
      case
        when lower(eligible_test.category) like '%diabetes%'
          or lower(eligible_test.category) like '%sugar%'
          then 1
        when lower(eligible_test.category) like '%blood%' then 2
        when lower(eligible_test.category) like '%kidney%' then 3
        when lower(eligible_test.category) like '%liver%' then 4
        when lower(eligible_test.category) like '%heart%' then 5
        else null
      end as required_group
    from eligible_tests as eligible_test
    group by eligible_test.category
  ),
  required_candidates as materialized (
    select
      category_total.*,
      row_number() over (
        partition by category_total.required_group
        order by category_total.total_count desc, lower(category_total.category)
      ) as group_choice
    from category_totals as category_total
    where category_total.required_group is not null
  ),
  required_categories as materialized (
    select
      required_candidate.category,
      required_candidate.total_count,
      row_number() over (order by random()) as category_position
    from required_candidates as required_candidate
    where required_candidate.group_choice = 1
  ),
  required_count as materialized (
    select count(*)::bigint as value
    from required_categories
  ),
  ranked_remaining_categories as materialized (
    select
      category_total.category,
      category_total.total_count,
      row_number() over (
        order by
          -ln(greatest(random(), 0.000001)) /
          (
            1.0
            + least(category_total.popular_count, 6) * 0.42
            + least(category_total.enriched_count, 8) * 0.12
            + least(category_total.home_collection_count, 10) * 0.025
          )::double precision,
          random()
      ) as remaining_position
    from category_totals as category_total
    where category_total.required_group is null
  ),
  selected_categories as materialized (
    select
      required_category.category,
      required_category.total_count,
      required_category.category_position
    from required_categories as required_category

    union all

    select
      remaining_category.category,
      remaining_category.total_count,
      required_count.value + remaining_category.remaining_position as category_position
    from ranked_remaining_categories as remaining_category
    cross join required_count
    cross join feed_limits
    where remaining_category.remaining_position <= greatest(
      feed_limits.category_limit - required_count.value,
      0
    )
  ),
  ranked_tests as materialized (
    select
      eligible_test.*,
      row_number() over (
        partition by eligible_test.category
        order by
          -ln(greatest(random(), 0.000001)) /
          (
            1.0
            + case when eligible_test.is_popular then 2.4 else 0 end
            + case
                when nullif(btrim(eligible_test.common_name), '') is not null then 0.8
                else 0
              end
            + case
                when nullif(btrim(eligible_test.purpose), '') is not null then 0.55
                else 0
              end
            + case
                when eligible_test.home_collection_available
                  and not eligible_test.lab_visit_required
                then 0.2
                else 0
              end
          )::double precision,
          random()
      ) as test_position
    from eligible_tests as eligible_test
    inner join selected_categories as selected_category
      on selected_category.category = eligible_test.category
  )
  select jsonb_build_object(
    'feed_id', gen_random_uuid(),
    'generated_at', now(),
    'categories', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'name', selected_category.category,
            'total_count', selected_category.total_count,
            'tests', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', ranked_test.id,
                    'test_code', ranked_test.test_code,
                    'name_sheet', ranked_test.name_sheet,
                    'common_name', ranked_test.common_name,
                    'mrp', ranked_test.mrp,
                    'reporting_time', ranked_test.reporting_time,
                    'sample_type_volume', ranked_test.sample_type_volume,
                    'category', ranked_test.category,
                    'body_system', ranked_test.body_system,
                    'test_type', ranked_test.test_type,
                    'purpose', ranked_test.purpose,
                    'preparation', ranked_test.preparation,
                    'age_recommendation', ranked_test.age_recommendation,
                    'home_collection_available', ranked_test.home_collection_available,
                    'lab_visit_required', ranked_test.lab_visit_required,
                    'special_handling_required', ranked_test.special_handling_required,
                    'is_popular', ranked_test.is_popular,
                    'min_age', ranked_test.min_age,
                    'max_age', ranked_test.max_age,
                    'gender', ranked_test.gender,
                    'parameter_count', ranked_test.parameter_count,
                    'included_parameters', ranked_test.included_parameters,
                    'sample_source', ranked_test.sample_source,
                    'sample_source_label', ranked_test.sample_source_label,
                    'sample_collection_note', ranked_test.sample_collection_note
                  )
                  order by ranked_test.test_position
                )
                from ranked_tests as ranked_test
                cross join feed_limits
                where ranked_test.category = selected_category.category
                  and ranked_test.test_position <= feed_limits.tests_per_category
              ),
              '[]'::jsonb
            )
          )
          order by selected_category.category_position
        )
        from selected_categories as selected_category
      ),
      '[]'::jsonb
    )
  );
$$;

comment on function public.get_home_medical_test_feed(integer, integer)
is 'Always places diabetes, blood, kidney, liver and heart categories in the first five positions in a fresh shuffled order; all later categories and tests rotate using weighted random selection.';

revoke all on function public.get_home_medical_test_feed(integer, integer)
from public;
grant execute on function public.get_home_medical_test_feed(integer, integer)
to anon, authenticated;
