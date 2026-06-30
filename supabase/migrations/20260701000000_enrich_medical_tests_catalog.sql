-- Medical tests catalog enrichment phase 1
-- Purpose:
-- 1. Add app-friendly enrichment columns.
-- 2. Classify sample source from the sheet's exact sample_type_volume value.
-- 3. Apply conservative category/test-type/home-vs-lab flags.
--
-- This migration does not insert new tests. It only enriches rows that already exist
-- in public.medical_tests.

alter table public.medical_tests
add column if not exists parameter_count integer;

alter table public.medical_tests
add column if not exists included_parameters text[] not null default '{}';

alter table public.medical_tests
add column if not exists sample_source text;

alter table public.medical_tests
add column if not exists sample_source_label text;

alter table public.medical_tests
add column if not exists sample_collection_note text;

create index if not exists medical_tests_sample_source_idx
on public.medical_tests (sample_source);

create index if not exists medical_tests_test_type_idx
on public.medical_tests (test_type);

-- 1) Sample source classification
with classified as (
  select
    id,
    case
      when lower(sample_type_volume) like '%urine%'
        and lower(sample_type_volume) like '%serum%'
        then 'blood_and_urine'

      when lower(sample_type_volume) like '%random urine%'
        or lower(sample_type_volume) like 'urine,%'
        or lower(sample_type_volume) like '%24 hours%urine%'
        then 'urine'

      when lower(sample_type_volume) like '%stool%'
        then 'stool'

      when lower(sample_type_volume) like '%semen%'
        then 'semen'

      when lower(sample_type_volume) like '%sputum%'
        then 'sputum'

      when lower(sample_type_volume) like '%body fluid%'
        then 'body_fluid'

      when lower(sample_type_volume) like '%lbc fluid%'
        then 'cervical_sample'

      when lower(sample_type_volume) like '%slides%'
        then 'slide'

      when lower(sample_type_volume) like '%specimen%'
        or lower(sample_type_volume) like '%human body parts%'
        then 'tissue_specimen'

      when lower(sample_type_volume) = 'nil'
        then 'procedure'

      when lower(sample_type_volume) = 'refer individual tests'
        then 'panel_depends'

      when lower(sample_type_volume) = 'refer to test code'
        then 'code_depends'

      when lower(sample_type_volume) like '%serum%'
        or lower(sample_type_volume) like '%plasma%'
        or lower(sample_type_volume) like '%whole blood%'
        or lower(sample_type_volume) like 'blood,%'
        then 'blood'

      else 'unknown'
    end as new_sample_source
  from public.medical_tests
)
update public.medical_tests mt
set
  sample_source = c.new_sample_source,
  sample_source_label = case c.new_sample_source
    when 'blood' then 'Blood sample'
    when 'blood_and_urine' then 'Blood + urine sample'
    when 'urine' then 'Urine sample'
    when 'stool' then 'Stool sample'
    when 'semen' then 'Semen sample'
    when 'sputum' then 'Sputum sample'
    when 'body_fluid' then 'Body fluid sample'
    when 'cervical_sample' then 'Cervical sample'
    when 'slide' then 'Prepared slide'
    when 'tissue_specimen' then 'Tissue/specimen sample'
    when 'procedure' then 'Procedure-based test'
    when 'panel_depends' then 'Depends on included tests'
    when 'code_depends' then 'Depends on selected test code'
    else 'Sample type not classified'
  end,
  sample_collection_note = case c.new_sample_source
    when 'blood' then 'Sample is collected from blood. Serum/plasma/whole blood are processed from blood.'
    when 'blood_and_urine' then 'Requires both blood and urine sample.'
    when 'urine' then 'Requires urine sample. Some tests need random urine; some need 24-hour urine collection.'
    when 'stool' then 'Requires stool/poop sample in a clean container.'
    when 'semen' then 'Requires semen sample in sterile container. Lab timing instructions may apply.'
    when 'sputum' then 'Requires sputum/phlegm sample, usually deep cough sample.'
    when 'body_fluid' then 'Requires body fluid sample, usually collected in clinic/hospital setup.'
    when 'cervical_sample' then 'Requires cervical sample, usually collected at lab/clinic.'
    when 'slide' then 'Requires properly prepared slide.'
    when 'tissue_specimen' then 'Requires tissue/specimen, usually biopsy or procedure-based collection.'
    when 'procedure' then 'Sample type is not listed; patient usually needs lab/doctor procedure.'
    when 'panel_depends' then 'This is a panel/package. Sample source depends on its included individual tests.'
    when 'code_depends' then 'This is a grouped code range. Sample source depends on the selected exact test code.'
    else 'Check lab instruction before collection.'
  end,
  updated_at = now()
from classified c
where mt.id = c.id;

-- 2) Test type enrichment
update public.medical_tests
set
  test_type = case
    when lower(name_sheet) like '%fnac%'
      or lower(name_sheet) like '%biopsy%'
      or lower(name_sheet) like '%pap smear%'
      or lower(name_sheet) like '%cytology%'
      or sample_source in ('procedure', 'tissue_specimen', 'slide', 'cervical_sample', 'body_fluid')
      then 'procedure'

    when lower(name_sheet) like '%panel%'
      or lower(name_sheet) like '%profile%'
      or lower(name_sheet) like '%complete%analysis%'
      or lower(name_sheet) like '%routine examination%'
      or lower(name_sheet) like '%total, direct & indirect%'
      or lower(name_sheet) like '%igg / igm%'
      or lower(name_sheet) like '%iga / igg / igm%'
      or test_code like '% - %'
      then 'panel'

    else 'individual'
  end,
  updated_at = now();

-- 3) Home/lab/special-handling flags
update public.medical_tests
set
  lab_visit_required = case
    when test_type = 'procedure'
      or sample_source in ('procedure', 'tissue_specimen', 'slide', 'cervical_sample', 'body_fluid')
      then true
    else false
  end,

  home_collection_available = case
    when test_type = 'procedure'
      or sample_source in ('procedure', 'tissue_specimen', 'slide', 'cervical_sample', 'body_fluid')
      then false
    else true
  end,

  special_handling_required = case
    when sample_source in ('semen', 'sputum', 'body_fluid', 'cervical_sample', 'slide', 'tissue_specimen', 'procedure', 'panel_depends', 'code_depends')
      or lower(name_sheet) like '%culture%'
      or lower(name_sheet) like '%pcr%'
      or lower(name_sheet) like '%24 hours%'
      or lower(name_sheet) like '%fnac%'
      or lower(name_sheet) like '%biopsy%'
      or lower(name_sheet) like '%gene%expert%'
      then true
    else false
  end,
  updated_at = now();

-- 4) Category enrichment. Order matters: specific categories come first.
update public.medical_tests
set
  category = case
    when lower(name_sheet) like '%fnac%'
      or lower(name_sheet) like '%biopsy%'
      or lower(name_sheet) like '%pap smear%'
      or lower(name_sheet) like '%cytology%'
      or sample_source in ('procedure', 'tissue_specimen', 'slide', 'cervical_sample', 'body_fluid')
      then 'Procedure / Lab Visit Tests'

    when lower(name_sheet) like '%hiv%'
      or lower(name_sheet) like '%hbsag%'
      or lower(name_sheet) like '%hcv%'
      or lower(name_sheet) like '%vdrl%'
      or lower(name_sheet) like '%tpha%'
      or lower(name_sheet) like '%syphilis%'
      or lower(name_sheet) like '%chlamydia%'
      or lower(name_sheet) like '%std%'
      or lower(name_sheet) like '%herpes%'
      or lower(name_sheet) like '%hsv%'
      then 'STD / Sexual Health'

    when lower(name_sheet) like '%af.b%'
      or lower(name_sheet) like '%a.f.b%'
      or lower(name_sheet) like '%mtb%'
      or lower(name_sheet) like '%tb %'
      or lower(name_sheet) like '%tuberculosis%'
      or lower(name_sheet) like '%genexpert%'
      or lower(name_sheet) like '%genexpert%'
      or lower(name_sheet) like '%culture & sensitivity%'
      then 'TB & Culture'

    when lower(name_sheet) like '%dengue%'
      or lower(name_sheet) like '%malaria%'
      or lower(name_sheet) like '%widal%'
      or lower(name_sheet) like '%typhi%'
      or lower(name_sheet) like '%chikungunya%'
      or lower(name_sheet) like '%scrub%'
      or lower(name_sheet) like '%leptospira%'
      or lower(name_sheet) like '%filaria%'
      or lower(name_sheet) like '%crp%'
      or lower(name_sheet) like '%procalcitonin%'
      or lower(name_sheet) like '%haptoglobin%'
      then 'Fever & Infection'

    when lower(name_sheet) like '%hepatitis%'
      or lower(name_sheet) like '%hav%'
      or lower(name_sheet) like '%hev%'
      or lower(name_sheet) like '%hbe%'
      or lower(name_sheet) like '%hbc%'
      or lower(name_sheet) like '%hbv%'
      then 'Hepatitis & Viral'

    when lower(name_sheet) like '%glucose%'
      or lower(name_sheet) like '%hba1c%'
      or lower(name_sheet) like '%insulin%'
      or lower(name_sheet) like '%c-peptide%'
      or lower(name_sheet) like '%gtt%'
      or lower(name_sheet) like '%diabetes%'
      then 'Diabetes'

    when lower(name_sheet) like '%thyroid%'
      or lower(name_sheet) like '% tsh%'
      or lower(name_sheet) like '% t3%'
      or lower(name_sheet) like '% t4%'
      or lower(name_sheet) like '%ft3%'
      or lower(name_sheet) like '%ft4%'
      or lower(name_sheet) like '%anti tpo%'
      or lower(name_sheet) like '%thyroglobulin%'
      then 'Thyroid'

    when lower(name_sheet) like '%sgpt%'
      or lower(name_sheet) like '%sgot%'
      or lower(name_sheet) like '%bilirubin%'
      or lower(name_sheet) like '%lft%'
      or lower(name_sheet) like '%liver%'
      or lower(name_sheet) like '%alkaline phosphatase%'
      or lower(name_sheet) like '%ggt%'
      or lower(name_sheet) like '%albumin%'
      or lower(name_sheet) like '%globulin%'
      or lower(name_sheet) like '%total protein%'
      then 'Liver'

    when lower(name_sheet) like '%creatinine%'
      or lower(name_sheet) like '%urea%'
      or lower(name_sheet) like '%bun%'
      or lower(name_sheet) like '%egfr%'
      or lower(name_sheet) like '%cystatin%'
      or lower(name_sheet) like '%uric acid%'
      or lower(name_sheet) like '%kidney%'
      or lower(name_sheet) like '%renal%'
      or lower(name_sheet) like '%micro albumin%'
      or lower(name_sheet) like '%acr%'
      then 'Kidney'

    when lower(name_sheet) like '%cholesterol%'
      or lower(name_sheet) like '%lipid%'
      or lower(name_sheet) like '%triglyceride%'
      or lower(name_sheet) like '%apo %'
      or lower(name_sheet) like '%troponin%'
      or lower(name_sheet) like '%trop%'
      or lower(name_sheet) like '%ntprobnp%'
      or lower(name_sheet) like '%nt pro bnp%'
      or lower(name_sheet) like '%ck mb%'
      then 'Heart'

    when lower(name_sheet) like '%pt %'
      or lower(name_sheet) like '%inr%'
      or lower(name_sheet) like '%aptt%'
      or lower(name_sheet) like '%d dimer%'
      or lower(name_sheet) like '%fibrinogen%'
      or lower(name_sheet) like '%bleeding time%'
      or lower(name_sheet) like '%clotting time%'
      or lower(name_sheet) like '%thrombin%'
      then 'Coagulation / Clotting'

    when lower(name_sheet) like '%vitamin%'
      or lower(name_sheet) like '%ferritin%'
      or lower(name_sheet) like '%iron%'
      or lower(name_sheet) like '%tibc%'
      or lower(name_sheet) like '%folic%'
      or lower(name_sheet) like '%folate%'
      or lower(name_sheet) like '%anemia%'
      then 'Vitamins & Weakness'

    when lower(name_sheet) like '%testosterone%'
      or lower(name_sheet) like '%lh%'
      or lower(name_sheet) like '%fsh%'
      or lower(name_sheet) like '%prolactin%'
      or lower(name_sheet) like '%amh%'
      or lower(name_sheet) like '%estradiol%'
      or lower(name_sheet) like '%estriol%'
      or lower(name_sheet) like '%progesterone%'
      or lower(name_sheet) like '%cortisol%'
      or lower(name_sheet) like '%dhea%'
      or lower(name_sheet) like '%fertility%'
      then 'Hormones & Fertility'

    when lower(name_sheet) like '%beta hcg%'
      or lower(name_sheet) like '%pregnancy%'
      or lower(name_sheet) like '%pap%'
      or lower(name_sheet) like '%ca 125%'
      then 'Women’s Health'

    when lower(name_sheet) like '%psa%'
      or lower(name_sheet) like '%prostatic%'
      or lower(name_sheet) like '%semen%'
      then 'Men’s Health'

    when lower(name_sheet) like '%ca 15%'
      or lower(name_sheet) like '%ca 19%'
      or lower(name_sheet) like '%ca 72%'
      or lower(name_sheet) like '%cea%'
      or lower(name_sheet) like '%afp%'
      or lower(name_sheet) like '%cancer marker%'
      or lower(name_sheet) like '%tumor%'
      then 'Cancer Markers'

    when lower(name_sheet) like '%ana%'
      or lower(name_sheet) like '%anca%'
      or lower(name_sheet) like '%anti%'
      or lower(name_sheet) like '%allergy%'
      or lower(name_sheet) like '%ra-factor%'
      or lower(name_sheet) like '%rheumatoid%'
      or lower(name_sheet) like '%complement%'
      or lower(name_sheet) like '%cardiolipin%'
      or lower(name_sheet) like '%phospholipid%'
      or lower(name_sheet) like '%lupus%'
      then 'Autoimmune & Allergy'

    when sample_source = 'urine'
      or lower(name_sheet) like '%urine%'
      then 'Urine Tests'

    when sample_source = 'stool'
      or lower(name_sheet) like '%stool%'
      then 'Stool Tests'

    when lower(name_sheet) like '%calcium%'
      or lower(name_sheet) like '%phosphorus%'
      or lower(name_sheet) like '%magnesium%'
      or lower(name_sheet) like '%sodium%'
      or lower(name_sheet) like '%potassium%'
      or lower(name_sheet) like '%chloride%'
      or lower(name_sheet) like '%bicarbonate%'
      then 'Electrolytes & Minerals'

    when lower(name_sheet) like '%cbc%'
      or lower(name_sheet) like '%haemoglobin%'
      or lower(name_sheet) like '%hemoglobin%'
      or lower(name_sheet) like '%platelet%'
      or lower(name_sheet) like '%total count%'
      or lower(name_sheet) like '%differential count%'
      or lower(name_sheet) like '%esr%'
      or lower(name_sheet) like '%blood group%'
      or lower(name_sheet) like '%coomb%'
      then 'Blood Tests'

    else coalesce(category, 'Other Tests')
  end,
  updated_at = now();

-- 5) Preventive/popular flags. Conservative: avoid forcing cancer/STD/hormone/autoimmune tests as routine.
update public.medical_tests
set
  is_preventive = case
    when category in (
      'Blood Tests',
      'Diabetes',
      'Liver',
      'Kidney',
      'Heart',
      'Thyroid',
      'Vitamins & Weakness',
      'Urine Tests',
      'Electrolytes & Minerals',
      'Men’s Health',
      'Women’s Health'
    )
    and category not in ('Cancer Markers', 'STD / Sexual Health', 'Autoimmune & Allergy')
    then true
    else false
  end,

  is_popular = case
    when lower(name_sheet) like '%cbc%'
      or lower(name_sheet) like '%hba1c%'
      or lower(name_sheet) like '%glucose%'
      or lower(name_sheet) like '%lft%'
      or lower(name_sheet) like '%kidney/renal panel%'
      or lower(name_sheet) like '%lipid panel%'
      or lower(name_sheet) like '%thyroid panel%'
      or lower(name_sheet) like '%vitamin d%'
      or lower(name_sheet) like '%vitamin b12%'
      or lower(name_sheet) like '%urine routine%'
      or lower(name_sheet) like '%stool routine%'
      then true
    else is_popular
  end,
  updated_at = now();

-- 6) Age/gender flags only where very obvious. Keep most tests as any-age/any-gender.
update public.medical_tests
set
  gender = case
    when category = 'Men’s Health' then 'male'
    when category = 'Women’s Health' then 'female'
    else gender
  end,
  min_age = case
    when lower(name_sheet) like '%psa%'
      or lower(name_sheet) like '%prostatic%'
      then 50
    when lower(name_sheet) like '%occult blood%'
      then 45
    else min_age
  end,
  updated_at = now();
