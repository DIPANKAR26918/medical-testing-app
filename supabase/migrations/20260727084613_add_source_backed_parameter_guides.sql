create table public.medical_parameter_guides (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  display_name text not null,
  what_it_is text not null,
  why_it_matters text not null,
  how_to_read_it text not null,
  source_label text not null,
  source_url text not null,
  review_status text not null default 'draft',
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint medical_parameter_guides_canonical_name_unique unique (
    canonical_name
  ),
  constraint medical_parameter_guides_canonical_name_check
    check (char_length(btrim(canonical_name)) between 2 and 160),
  constraint medical_parameter_guides_display_name_check
    check (char_length(btrim(display_name)) between 2 and 160),
  constraint medical_parameter_guides_what_it_is_check
    check (char_length(btrim(what_it_is)) between 20 and 700),
  constraint medical_parameter_guides_why_it_matters_check
    check (char_length(btrim(why_it_matters)) between 20 and 700),
  constraint medical_parameter_guides_how_to_read_it_check
    check (char_length(btrim(how_to_read_it)) between 20 and 700),
  constraint medical_parameter_guides_source_label_check
    check (char_length(btrim(source_label)) between 2 and 180),
  constraint medical_parameter_guides_source_url_check
    check (source_url ~ '^https://'),
  constraint medical_parameter_guides_review_status_check
    check (
      review_status in (
        'draft',
        'source_checked',
        'clinician_reviewed',
        'retired'
      )
    ),
  constraint medical_parameter_guides_reviewed_at_check
    check (
      review_status in ('draft', 'retired')
      or reviewed_at is not null
    )
);

create table public.medical_parameter_guide_aliases (
  parameter_key text primary key,
  guide_id uuid not null
    references public.medical_parameter_guides(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint medical_parameter_guide_aliases_key_check
    check (
      parameter_key = lower(
        regexp_replace(btrim(parameter_key), '\s+', ' ', 'g')
      )
      and char_length(parameter_key) between 1 and 180
    )
);

create index medical_parameter_guide_aliases_guide_id_idx
on public.medical_parameter_guide_aliases (guide_id);

alter table public.medical_parameter_guides enable row level security;
alter table public.medical_parameter_guide_aliases enable row level security;

revoke all on table public.medical_parameter_guides
from public, anon, authenticated;
revoke all on table public.medical_parameter_guide_aliases
from public, anon, authenticated;

grant select on table public.medical_parameter_guides to authenticated;
grant select on table public.medical_parameter_guide_aliases to authenticated;

create policy "Authenticated users read source-checked guides"
on public.medical_parameter_guides
for select
to authenticated
using (review_status in ('source_checked', 'clinician_reviewed'));

create policy "Authenticated users read published guide aliases"
on public.medical_parameter_guide_aliases
for select
to authenticated
using (
  exists (
    select 1
    from public.medical_parameter_guides as guide
    where guide.id = guide_id
      and guide.review_status in ('source_checked', 'clinician_reviewed')
  )
);

create or replace function public.get_medical_parameter_guide(
  p_parameter text
)
returns table (
  display_name text,
  what_it_is text,
  why_it_matters text,
  how_to_read_it text,
  source_label text,
  source_url text
)
language sql
stable
security invoker
set search_path = ''
rows 1
as $$
  select
    guide.display_name,
    guide.what_it_is,
    guide.why_it_matters,
    guide.how_to_read_it,
    guide.source_label,
    guide.source_url
  from public.medical_parameter_guide_aliases as alias
  join public.medical_parameter_guides as guide
    on guide.id = alias.guide_id
  where alias.parameter_key = lower(
    regexp_replace(btrim(coalesce(p_parameter, '')), '\s+', ' ', 'g')
  )
    and guide.review_status in ('source_checked', 'clinician_reviewed')
  limit 1;
$$;

revoke all on function public.get_medical_parameter_guide(text)
from public;
grant execute on function public.get_medical_parameter_guide(text)
to authenticated;

comment on table public.medical_parameter_guides is
  'Short, source-backed explanations shown when a user taps a medical-test parameter.';
comment on table public.medical_parameter_guide_aliases is
  'Normalized catalogue names that map to one reviewed medical-parameter guide.';
comment on function public.get_medical_parameter_guide(text) is
  'Returns at most one published parameter explanation for an authenticated app user.';

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
values
  (
    'albumin',
    'Albumin',
    'Albumin is a protein made by the liver. It helps keep fluid inside blood vessels and carries substances such as hormones, vitamins, and medicines through the blood.',
    'It helps assess the liver’s protein-making function. Albumin can also provide context about kidney health, nutrition, inflammation, and hydration.',
    'An albumin result does not diagnose a condition by itself. It should be read with the rest of the panel, your symptoms, and your clinical history.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/albumin-blood-test/',
    'source_checked',
    now()
  ),
  (
    'alkaline-phosphatase',
    'Alkaline phosphatase (ALP)',
    'ALP is an enzyme found throughout the body, with higher amounts in the liver, bile ducts, and bones.',
    'It helps look for patterns involving the liver or bile ducts. Other results in the panel help distinguish a possible liver source from a bone source.',
    'ALP can change for several reasons, including normal bone growth and pregnancy. The value needs the lab’s range and the other test results for context.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/alkaline-phosphatase/',
    'source_checked',
    now()
  ),
  (
    'bilirubin',
    'Bilirubin',
    'Bilirubin is a yellow waste substance made when old red blood cells are broken down. The liver processes it and removes most of it through bile.',
    'It helps assess how the body is processing red-cell waste and whether the liver and bile-flow pathway are handling it normally.',
    'A higher result can have different causes involving red blood cells, the liver, or bile ducts. It must be interpreted with the bilirubin type and other tests.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/bilirubin-blood-test/',
    'source_checked',
    now()
  ),
  (
    'globulin',
    'Globulin',
    'Globulins are a group of blood proteins made by the liver and immune system. They help with functions such as fighting infection and blood clotting.',
    'Together with albumin and total protein, globulin helps show the balance of major proteins in the blood and adds context about liver, kidney, and immune health.',
    'High or low globulin is not specific to one condition. It should be interpreted with albumin, total protein, symptoms, and any follow-up testing.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/globulin-test/',
    'source_checked',
    now()
  ),
  (
    'sgpt-alt',
    'SGPT (ALT)',
    'SGPT is an older name for ALT, an enzyme measured in the blood and mainly associated with liver cells.',
    'It helps look for a pattern of possible liver-cell irritation or injury, especially when compared with SGOT (AST) and the other liver-panel results.',
    'An abnormal ALT result does not identify the cause or show the whole liver picture. Medicines, recent illness, and other factors can affect the result.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/liver-function-tests/',
    'source_checked',
    now()
  ),
  (
    'sgot-ast',
    'SGOT (AST)',
    'SGOT is an older name for AST, an enzyme measured in the blood. It is associated with the liver but is also present in other body tissues.',
    'It is interpreted with SGPT (ALT) and the rest of the liver panel to look for patterns that may suggest tissue or liver-cell injury.',
    'AST is not specific to the liver, so a changed value cannot identify the source or diagnose a condition on its own.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/liver-function-tests/',
    'source_checked',
    now()
  ),
  (
    'total-protein',
    'Total protein',
    'Total protein measures the combined amount of the two main groups of protein in blood: albumin and globulins.',
    'It gives an overall view of blood-protein balance and can add context about liver and kidney function, nutrition, and immune activity.',
    'A changed total does not show which protein caused it. Albumin, globulin, the A/G ratio, and the rest of the report provide the needed context.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/total-protein-and-albumin-globulin-a-g-ratio/',
    'source_checked',
    now()
  ),
  (
    'albumin-globulin-ratio',
    'Albumin-globulin ratio (A/G ratio)',
    'The A/G ratio is a calculated comparison between the amount of albumin and the amount of globulin in the blood.',
    'It helps show whether the two major protein groups are in their expected balance and complements the individual albumin, globulin, and total-protein results.',
    'The ratio can change when either albumin or globulin changes. It cannot diagnose a condition without the individual values and the rest of the report.',
    'MedlinePlus — U.S. National Library of Medicine',
    'https://medlineplus.gov/lab-tests/total-protein-and-albumin-globulin-a-g-ratio/',
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
    ('albumin', 'albumin'),
    ('serum albumin', 'albumin'),
    ('alkaline phospatase', 'alkaline-phosphatase'),
    ('alkaline phosphatase', 'alkaline-phosphatase'),
    ('alkaline phosphatase (alp)', 'alkaline-phosphatase'),
    ('alp', 'alkaline-phosphatase'),
    ('bilirubin', 'bilirubin'),
    ('total bilirubin', 'bilirubin'),
    ('bilirubin total', 'bilirubin'),
    ('globulin', 'globulin'),
    ('serum globulin', 'globulin'),
    ('sgpt', 'sgpt-alt'),
    ('alt', 'sgpt-alt'),
    ('sgpt/alt', 'sgpt-alt'),
    ('alanine transaminase', 'sgpt-alt'),
    ('alanine aminotransferase', 'sgpt-alt'),
    ('sgot', 'sgot-ast'),
    ('ast', 'sgot-ast'),
    ('sgot/ast', 'sgot-ast'),
    ('aspartate transaminase', 'sgot-ast'),
    ('aspartate aminotransferase', 'sgot-ast'),
    ('total protein', 'total-protein'),
    ('total proteins', 'total-protein'),
    ('albumin-globulin ratio', 'albumin-globulin-ratio'),
    ('albumin/globulin ratio', 'albumin-globulin-ratio'),
    ('a/g ratio', 'albumin-globulin-ratio')
) as aliases(parameter_key, canonical_name)
join public.medical_parameter_guides as guide
  on guide.canonical_name = aliases.canonical_name
on conflict (parameter_key) do update
set guide_id = excluded.guide_id;
