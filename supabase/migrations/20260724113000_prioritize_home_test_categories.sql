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
  with eligible_tests as materialized (
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
        when lower(eligible_test.category) like '%immunity%' then 6
        when lower(eligible_test.category) like '%allergy%' then 7
        else 100
      end as priority_rank
    from eligible_tests as eligible_test
    group by eligible_test.category
  ),
  ranked_categories as (
    select
      category_total.category,
      category_total.total_count,
      category_total.priority_rank,
      row_number() over (
        order by
          category_total.priority_rank,
          case
            when category_total.priority_rank < 100 then 0::double precision
            else
              -ln(greatest(random(), 0.000001)) /
              (
                1.0
                + least(category_total.popular_count, 6) * 0.42
                + least(category_total.enriched_count, 8) * 0.12
                + least(category_total.home_collection_count, 10) * 0.025
              )::double precision
          end,
          case
            when category_total.priority_rank < 100
              then lower(category_total.category)
            else null
          end,
          random()
      ) as category_position
    from category_totals as category_total
  ),
  selected_categories as materialized (
    select
      ranked_category.category,
      ranked_category.total_count,
      ranked_category.category_position
    from ranked_categories as ranked_category
    where ranked_category.category_position <= least(
      greatest(coalesce(p_category_limit, 8), 1),
      12
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
                when nullif(btrim(eligible_test.common_name), '') is not null
                then 0.8
                else 0
              end
            + case
                when nullif(btrim(eligible_test.purpose), '') is not null
                then 0.55
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
                where ranked_test.category = selected_category.category
                  and ranked_test.test_position <= least(
                    greatest(coalesce(p_tests_per_category, 4), 1),
                    6
                  )
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
is 'Builds a fresh home feed with fixed category priority: diabetes, blood, kidney, liver, heart, immunity and allergy; remaining categories and tests continue to rotate using weighted random selection.';

revoke all on function public.get_home_medical_test_feed(integer, integer)
from public;
grant execute on function public.get_home_medical_test_feed(integer, integer)
to anon, authenticated;
