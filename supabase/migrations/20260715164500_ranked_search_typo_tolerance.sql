-- A compact v2 search RPC that adds word-level trigram similarity. This lets
-- incomplete/typo queries such as "livr" match the category word "liver"
-- even when the full test name is much longer.

create index if not exists medical_tests_active_search_all_trgm_idx
  on public.medical_tests using gin (
    (
      lower(
        coalesce(common_name, '') || ' ' ||
        name_sheet || ' ' ||
        coalesce(test_code, '') || ' ' ||
        coalesce(category, '') || ' ' ||
        coalesce(body_system, '')
      )
    ) extensions.gin_trgm_ops
  )
  where is_active = true;

drop function if exists public.search_medical_tests_ranked(text, integer, text);

create function public.search_medical_tests_ranked(
  p_query text default '',
  p_limit integer default 30,
  p_category text default null
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
  relevance double precision,
  match_reason text
)
language sql
stable
security invoker
set search_path = ''
as $$
  with input as (
    select
      lower(
        trim(
          pg_catalog.regexp_replace(
            coalesce(p_query, ''),
            '[[:space:]]+',
            ' ',
            'g'
          )
        )
      ) as query_text,
      greatest(1, least(coalesce(p_limit, 30), 60)) as result_limit
  ), scored as (
    select
      medical_test.*,
      input.query_text,
      lower(coalesce(medical_test.common_name, '')) as common_lower,
      lower(medical_test.name_sheet) as name_lower,
      lower(coalesce(medical_test.test_code, '')) as code_lower,
      lower(coalesce(medical_test.category, '')) as category_lower,
      lower(coalesce(medical_test.body_system, '')) as body_lower,
      lower(
        coalesce(medical_test.common_name, '') || ' ' ||
        medical_test.name_sheet || ' ' ||
        coalesce(medical_test.test_code, '') || ' ' ||
        coalesce(medical_test.category, '') || ' ' ||
        coalesce(medical_test.body_system, '')
      ) as searchable_text,
      case
        when input.query_text = '' then 0
        else extensions.word_similarity(
          input.query_text,
          lower(
            coalesce(medical_test.common_name, '') || ' ' ||
            medical_test.name_sheet || ' ' ||
            coalesce(medical_test.test_code, '') || ' ' ||
            coalesce(medical_test.category, '') || ' ' ||
            coalesce(medical_test.body_system, '')
          )
        )
      end as word_rank,
      case
        when input.query_text = '' then 0
        else pg_catalog.ts_rank_cd(
          medical_test.search_document,
          pg_catalog.websearch_to_tsquery('simple'::regconfig, input.query_text)
        )
      end as text_rank,
      case
        when input.query_text = '' then false
        else exists (
          select 1
          from unnest(medical_test.search_keywords) as keyword
          where lower(keyword) = input.query_text
             or lower(keyword) like input.query_text || '%'
             or input.query_text like lower(keyword) || '%'
        )
      end as keyword_match
    from public.medical_tests as medical_test
    cross join input
    where medical_test.is_active = true
      and (
        p_category is null
        or trim(p_category) = ''
        or medical_test.category = p_category
      )
  ), filtered as (
    select
      scored_test.*,
      (
        case
          when scored_test.query_text = '' then
            case when scored_test.is_popular then 10 else 1 end
          when scored_test.common_lower = scored_test.query_text then 160
          when scored_test.name_lower = scored_test.query_text then 155
          when scored_test.code_lower = scored_test.query_text then 150
          when scored_test.common_lower like scored_test.query_text || '%' then 118
          when scored_test.name_lower like scored_test.query_text || '%' then 114
          when scored_test.code_lower like scored_test.query_text || '%' then 110
          when scored_test.category_lower = scored_test.query_text then 90
          when scored_test.body_lower = scored_test.query_text then 86
          when scored_test.searchable_text like '%' || scored_test.query_text || '%' then 78
          else 0
        end
        + scored_test.word_rank * 94
        + scored_test.text_rank * 80
        + case when scored_test.keyword_match then 34 else 0 end
        + case when scored_test.is_popular then 5 else 0 end
      )::double precision as score
    from scored as scored_test
    where scored_test.query_text = ''
       or scored_test.search_document @@ pg_catalog.websearch_to_tsquery(
         'simple'::regconfig,
         scored_test.query_text
       )
       or scored_test.searchable_text like '%' || scored_test.query_text || '%'
       or scored_test.word_rank >= 0.28
       or scored_test.keyword_match
  )
  select
    result.id,
    result.test_code,
    result.name_sheet,
    result.common_name,
    result.mrp,
    result.reporting_time,
    result.sample_type_volume,
    result.category,
    result.body_system,
    result.test_type,
    result.purpose,
    result.preparation,
    result.age_recommendation,
    result.home_collection_available,
    result.lab_visit_required,
    result.special_handling_required,
    result.is_popular,
    result.min_age,
    result.max_age,
    result.gender,
    result.parameter_count,
    result.included_parameters,
    result.sample_source,
    result.sample_source_label,
    result.sample_collection_note,
    result.score,
    case
      when result.query_text = '' and result.is_popular then 'Popular near you'
      when result.query_text = '' then 'Explore test'
      when result.common_lower = result.query_text
        or result.name_lower = result.query_text
        or result.code_lower = result.query_text then 'Exact match'
      when result.common_lower like result.query_text || '%'
        or result.name_lower like result.query_text || '%'
        or result.code_lower like result.query_text || '%' then 'Name match'
      when result.keyword_match then 'Matches your health need'
      when result.text_rank > 0 then 'Relevant test'
      else 'Closest spelling match'
    end
  from filtered as result
  cross join input
  order by
    result.score desc,
    result.is_popular desc,
    result.display_order,
    result.name_sheet
  limit (select result_limit from input);
$$;

revoke all on function public.search_medical_tests_ranked(text, integer, text)
  from public;
grant execute on function public.search_medical_tests_ranked(text, integer, text)
  to anon, authenticated;
