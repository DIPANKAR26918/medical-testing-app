-- Build a complete, app-friendly medical-test taxonomy and expose a compact
-- randomized home feed. The feed is intentionally assembled in Postgres so
-- Flutter does not download and shuffle the full catalogue on every launch.

with uncategorized as (
  select
    id,
    lower(concat_ws(' ', name_sheet, common_name, test_code)) as search_text,
    test_type,
    sample_source
  from public.medical_tests
  where category is null or btrim(category) = ''
),
classified as (
  select
    id,
    case
      when test_type = 'procedure'
        or sample_source in (
          'tissue_specimen',
          'slide',
          'cervical_sample',
          'body_fluid',
          'procedure'
        )
        or search_text like any (
          array['%biopsy%', '%cytology%', '%fnac%', '%pap stain%', '%histopath%']
        )
        then 'Histopathology & Cytology'

      when search_text like any (
        array[
          '%std panel%',
          '%sexually transmitted%',
          '%hiv%',
          '%syph%',
          '%vdrl%',
          '%tpha%',
          '%treponema%',
          '%chlamydia%',
          '%gonorrh%',
          '%rpr -%'
        ]
      )
        then 'Sexual Health Tests'

      when search_text like any (
        array[
          '%maternal%',
          '%pregnancy%',
          '%beta hcg%',
          '%papp-a%',
          '%torch panel%',
          '%double marker%',
          '%triple marker%',
          '%quadraple marker%',
          '%quadruple marker%'
        ]
      )
        then 'Pregnancy & Women’s Health'

      when search_text like any (
        array[
          '%psa %',
          '%psa-%',
          '%prostate%',
          '%seminogram%',
          '%semen analysis%',
          '%fructose analysis - semen%'
        ]
      )
        then 'Men’s Health'

      when search_text like any (
        array[
          '%cancer marker%',
          '%tumor marker%',
          '%tumour marker%',
          '%carcino embryonic%',
          '%ca 125%',
          '%ca 15.3%',
          '%ca 19.9%',
          '%ca 72.4%',
          '%roma index%',
          '%alpha feto protein%',
          '%afp -%',
          '%cea -%',
          '%beta 2m%'
        ]
      )
        then 'Cancer Markers'

      when search_text like any (
        array[
          '%thyroid%',
          '%tsh%',
          '%thyroglobulin%',
          '%anti tpo%',
          '%anti - tg%',
          '%anti tg%',
          '%t3 %',
          '%t4 %'
        ]
      )
        then 'Thyroid'

      when search_text like any (
        array[
          '%diabetes%',
          '%glucose%',
          '%hba1c%',
          '%glycated%',
          '%insulin%',
          '%c- peptide%',
          '%c peptide%',
          '%ogtt%'
        ]
      )
        then 'Diabetes'

      when search_text like any (
        array[
          '%creatinine%',
          '%renal%',
          '%kidney%',
          '%micro albumin%',
          '%microalbumin%',
          '%urea%',
          '%uric acid%',
          '%cystatin%',
          '%protein - total - 24 hours%'
        ]
      )
        then 'Kidney'

      when search_text like any (
        array[
          '%bilirubin%',
          '%liver%',
          '%sgot%',
          '%sgpt%',
          '%alkaline phosphatase%',
          '%gamma gt%',
          '%ggt%',
          '%ammonia%',
          '%saag%',
          '%cholinesterase%'
        ]
      )
        then 'Liver'

      when search_text like any (
        array[
          '%lipid%',
          '%cholesterol%',
          '%triglyceride%',
          '%apolipo%',
          '%apo a1%',
          '%apo b %',
          '%lipoprotein%',
          '%troponin%',
          '%trop i%',
          '%trop t%',
          '%nt pro bnp%',
          '%bnp%',
          '%cardiac%',
          '%heart%',
          '%homocyst%',
          '%ck-mb%'
        ]
      )
        then 'Heart'

      when search_text like any (
        array[
          '%pt - inr%',
          '%prothrombin%',
          '%aptt%',
          '%thromboplastin%',
          '%thrombin time%',
          '%anti thrombin%',
          '%fibrinogen%',
          '%fibrin degeneration%',
          '%d-dimer%',
          '%d dimer%',
          '%bleeding time%',
          '%clotting time%',
          '%bt & ct%',
          '%coagulation%',
          '%thrombosis%'
        ]
      )
        then 'Coagulation & Clotting'

      when search_text like any (
        array[
          '%cbc%',
          '%complete blood count%',
          '%haemoglobin%',
          '%hemoglobin%',
          '%differential count%',
          '%total count%',
          '%platelet%',
          '%peripheral blood smear%',
          '%pbs -%',
          '%reticulocyte%',
          '%sickling%',
          '%thalassemia%',
          '%osmotic fragility%',
          '%blood group%',
          '%coomb%',
          '%esr%',
          '%erythrocyte sedimentation%',
          '%bone marrow%',
          '%packed cell volume%',
          '%pcv -%'
        ]
      )
        then 'Blood Tests'

      when search_text like any (
        array[
          '%vitamin%',
          '%ferritin%',
          '%folate%',
          '%folic%',
          '%iron%',
          '%tibc%',
          '%transferrin%',
          '%zinc%',
          '%copper%',
          '%ceruloplasmin%'
        ]
      )
        then 'Vitamins & Weakness'

      when search_text like any (
        array[
          '%calcium%',
          '%phosphorus%',
          '%phosphate%',
          '%magnesium%',
          '%sodium%',
          '%potassium%',
          '%chloride%',
          '%bicarbonate%',
          '%electrolyte%',
          '%osmolality%'
        ]
      )
        then 'Electrolytes & Minerals'

      when search_text ~ '(^|[^a-z0-9])(ana|anf|anca)([^a-z0-9]|$)'
        or search_text like any (
          array[
            '%anti ds dna%',
            '%anti smith%',
            '%sm/rnp%',
            '%anti jo 1%',
            '%anti ccp%',
            '%cardiolipin%',
            '%phospholipid%',
            '%lupus%',
            '%rheumatoid%',
            '%ra factor%',
            '%complement 3%',
            '%complement 4%',
            '%c3 -%',
            '%c4 -%',
            '%ama-m2%',
            '%mitochondrial antibody%',
            '%autoimmune%',
            '%hla b27%',
            '%hlab27%',
            '%glomerular basement membrane%'
          ]
        )
        then 'Autoimmune & Rheumatology'

      when search_text like any (
        array[
          '%allergy%',
          '%ige level%',
          '%immunoglobulin e%',
          '%food intolerance%'
        ]
      )
        then 'Allergy Tests'

      when search_text like any (
        array[
          '%progesterone%',
          '%testosterone%',
          '%estradiol%',
          '%estriol%',
          '%estrogen%',
          '%prolactin%',
          '%follicle stimulating%',
          '%luteinizing%',
          '%fsh%',
          '% lh %',
          '%amh %',
          '%anti mullerian%',
          '%cortisol%',
          '%acth%',
          '%aldosterone%',
          '%catecholamine%',
          '%adrenaline%',
          '%epinephrine%',
          '%dhea%',
          '%shbg%',
          '%sex hormone%',
          '%fertility%',
          '%growth hormone%',
          '%inhibin%'
        ]
      )
        then 'Hormones & Fertility'

      when search_text like any (
        array[
          '%dengue%',
          '%malaria%',
          '%typhi%',
          '%widal%',
          '%scrub typhus%',
          '%hepatitis%',
          '%hbsag%',
          '%hcv%',
          '%rubella%',
          '%toxoplasma%',
          '%cmv%',
          '%cytomegalo%',
          '%varicella%',
          '%vzv%',
          '%leptospira%',
          '%brucella%',
          '%ebv%',
          '%epstein%',
          '%herpes%',
          '%virus%',
          '%viral%',
          '%afb%',
          '%a.f.b%',
          '%tuberculosis%',
          '%quantiferon%',
          '%genexpert%',
          '%mtb/rif%',
          '%culture%',
          '%gram stain%',
          '%fungal%',
          '%parasite%',
          '%filaria%',
          '%pro calcitonin%',
          '%procalcitonin%',
          '%aso -%',
          '%antistreptolysin%',
          '%adenosine deaminase%'
        ]
      )
        then 'Infection & Fever'

      when search_text like any (
        array[
          '%amylase%',
          '%lipase%',
          '%pancrea%',
          '%celiac%',
          '%coeliac%',
          '%transglutaminase%',
          '%occult blood%',
          '%calprotectin%',
          '%h. pylori%',
          '%helicobacter%',
          '%digestive%'
        ]
      )
        then 'Digestive & Pancreas'

      when sample_source = 'stool' or search_text like '%stool%'
        then 'Stool Tests'

      when sample_source = 'sputum'
        or search_text like any (array['%sputum%', '%respiratory%'])
        then 'Respiratory Tests'

      when sample_source in ('urine', 'blood_and_urine')
        or search_text like '%urine%'
        then 'Urine Tests'

      when search_text like any (
        array[
          '%absolute count - cd%',
          '%immunoglobulin%',
          '%iga %',
          '%igg %',
          '%igm %',
          '%immune%',
          '%lymphocyte%',
          '%protein electrophoresis%',
          '%electrophoresis - protein%',
          '%immunofixation%'
        ]
      )
        then 'Immunity & Proteins'

      when search_text like any (
        array['%phenytoin%', '%drug monitoring%', '%lithium%']
      )
        then 'Therapeutic Drug Monitoring'

      when search_text like any (
        array['%cytogenetic%', '%chromosomal%', '%karyotype%', '%genetic%']
      )
        then 'Genetic Tests'

      else 'Specialised Tests'
    end as category
  from uncategorized
)
update public.medical_tests as medical_test
set
  category = classified.category,
  updated_at = now()
from classified
where medical_test.id = classified.id;

-- Merge older near-duplicate labels so the catalogue does not render tiny,
-- confusing category sections.
update public.medical_tests
set
  category = case category
    when 'Electrolytes' then 'Electrolytes & Minerals'
    when 'Women’s Health' then 'Pregnancy & Women’s Health'
    when 'Procedure / Lab Visit Tests' then 'Histopathology & Cytology'
    else category
  end,
  updated_at = now()
where category in (
  'Electrolytes',
  'Women’s Health',
  'Procedure / Lab Visit Tests'
);

create index if not exists medical_tests_active_category_idx
on public.medical_tests (category, display_order, name_sheet)
where is_active = true;

create or replace function public.get_medical_test_categories()
returns table (
  category text,
  test_count bigint,
  popular_count bigint
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    coalesce(nullif(btrim(medical_test.category), ''), 'Specialised Tests') as category,
    count(*) as test_count,
    count(*) filter (where medical_test.is_popular) as popular_count
  from public.medical_tests as medical_test
  where medical_test.is_active = true
  group by 1
  order by test_count desc, category;
$$;

comment on function public.get_medical_test_categories()
is 'Returns active medical-test categories and counts for catalogue navigation.';

revoke all on function public.get_medical_test_categories() from public;
grant execute on function public.get_medical_test_categories() to anon, authenticated;

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
  category_totals as (
    select
      eligible_test.category,
      count(*) as total_count
    from eligible_tests as eligible_test
    group by eligible_test.category
  ),
  ranked_categories as (
    select
      category_total.category,
      category_total.total_count,
      row_number() over (order by random()) as category_position
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
        order by random()
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
is 'Builds a fresh randomized category-and-test composition for the Testified home screen.';

revoke all on function public.get_home_medical_test_feed(integer, integer)
from public;
grant execute on function public.get_home_medical_test_feed(integer, integer)
to anon, authenticated;
