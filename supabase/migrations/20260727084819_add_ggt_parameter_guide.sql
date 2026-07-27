insert into public.medical_parameter_guides (
  canonical_name,
  display_name,
  what_it_is,
  why_it_matters,
  how_to_read_it,
  source_label,
  source_url,
  review_status,
  reviewed_at
)
values (
  'ggt',
  'Gamma-glutamyl transferase (GGT)',
  'GGT is an enzyme found throughout the body but mainly in the liver. It can enter the blood when the liver or bile ducts are affected.',
  'It helps look for liver or bile-duct patterns and is often interpreted with alkaline phosphatase (ALP) to add context about the likely source.',
  'GGT cannot identify a specific cause on its own. Alcohol, medicines, supplements, and smoking can affect the result, so the full context matters.',
  'MedlinePlus — U.S. National Library of Medicine',
  'https://medlineplus.gov/lab-tests/gamma-glutamyl-transferase-ggt-test/',
  'source_checked',
  now()
)
on conflict (canonical_name) do update
set
  display_name = excluded.display_name,
  what_it_is = excluded.what_it_is,
  why_it_matters = excluded.why_it_matters,
  how_to_read_it = excluded.how_to_read_it,
  source_label = excluded.source_label,
  source_url = excluded.source_url,
  review_status = excluded.review_status,
  reviewed_at = excluded.reviewed_at,
  updated_at = now();

insert into public.medical_parameter_guide_aliases (
  parameter_key,
  guide_id
)
select aliases.parameter_key, guide.id
from (
  values
    ('ggt', 'ggt'),
    ('ggtp', 'ggt'),
    ('gamma-gt', 'ggt'),
    ('gamma glutamyl transferase', 'ggt'),
    ('gamma-glutamyl transferase', 'ggt')
) as aliases(parameter_key, canonical_name)
join public.medical_parameter_guides as guide
  on guide.canonical_name = aliases.canonical_name
on conflict (parameter_key) do update
set guide_id = excluded.guide_id;
