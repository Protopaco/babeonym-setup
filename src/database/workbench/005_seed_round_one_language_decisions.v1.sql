-- Curation decisions for the twenty-one Wiktionary language tokens that carried
-- twenty or more names each, reviewed after extraction ran over the full corpus.
--
-- Those twenty-one accounted for 2,351 of the 3,146 claims awaiting a decision,
-- so they were worked through by hand and the remaining 345 thin tokens left in
-- the queue. Continues 004; kept as a separate file so the record of what was
-- decided, and when, stays append-only.
--
-- Depends on 038_seed_round_one_languages.v1.sql having run, since the mappings
-- below join languages on label. Safe to re-run: a decision already recorded is
-- not overwritten.

BEGIN;

-- Languages added by 038. The refresh in the extraction stage would map these
-- on its own, but only at the end of a full re-extraction. Stating them here
-- means the review queue settles on workbench:init, and this file reads as the
-- complete record of all twenty-one decisions rather than two thirds of one.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT added.alias, languages.id, 'mapped'
FROM (VALUES
  ('Sanskrit'),
  ('Old Norse'),
  ('Walloon'),
  ('Atayal'),
  ('Asturian'),
  ('Esperanto'),
  ('Lun Bawang'),
  ('Greenlandic'),
  ('Ingrian'),
  ('Tausug'),
  ('Aramaic')
) AS added (alias)
JOIN languages ON languages.label = added.alias
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Historical forms folded into their modern descendant, continuing the default
-- set in 004. Each of these has exactly one, so nothing is being chosen for the
-- source. Old Galician-Portuguese has two and goes to Portuguese as the larger,
-- which is a judgment: it is not a label anyone would browse for, so keeping it
-- separate would buy a row nobody reads.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT folded.alias, languages.id, 'mapped'
FROM (VALUES
  ('Old Czech',               'Czech'),
  ('Old High German',         'German'),
  ('Old Irish',               'Irish'),
  ('Old Galician-Portuguese', 'Portuguese')
) AS folded (alias, language_label)
JOIN languages ON languages.label = folded.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Same language, different English name. Wiktionary prefers the short form and
-- the reference list carries the long one, so the exact-match auto-mapper never
-- connects them.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT 'Slovene', languages.id, 'mapped'
FROM languages
WHERE languages.label = 'Slovenian'
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Not languages. Rejection has to be sticky, or every re-run puts them back in
-- the review queue.
--
-- The first three are real statements about where a name came from — Bradley
-- from a surname, Jayden from nothing at all, Chelsea from a place — that
-- Wiktionary happens to file in the same slot as a language. Rejecting them
-- only means they are not treated as languages; the claims stay in name_claims,
-- so a name-origin feature can still be built on them later.
--
-- Slavic languages follows Germanic and Celtic from 004. Proto-Germanic is a
-- reconstruction rather than an attested language, so it joins them.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('surnames', 'rejected'),
  ('coinages', 'rejected'),
  ('place names', 'rejected'),
  ('Slavic languages', 'rejected'),
  ('Proto-Germanic', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

COMMIT;
