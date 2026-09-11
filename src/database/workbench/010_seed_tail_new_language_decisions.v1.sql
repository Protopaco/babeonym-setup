-- Decisions for the tail tokens seen for ten or more names that were not a form
-- of a language already carried — the second pass through the tail, after 009
-- folded the historical and regional forms. Reviewed 2026-09-11.
--
-- Depends on 040_seed_tail_languages.v1.sql having run, since the mappings join
-- languages on label. Wiktionary tokens are keyed on their text and Wikidata
-- items on their identifier, following 005, 007 and 009. Safe to re-run: a
-- decision already recorded is not overwritten.

BEGIN;

-- Languages added by 040, stated here so the queue settles on workbench:init
-- without waiting for a re-extraction.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('West Frisian', 'West Frisian'),
  ('Sakizaya',     'Sakizaya'),
  ('Sicilian',     'Sicilian'),
  ('Yola',         'Yola'),
  ('Pazeh',        'Pazeh'),
  ('Illyrian',     'Illyrian')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q27175',  'West Frisian', 'West Frisian'),
  ('Q718269', 'Sakizaya',     'Sakizaya'),
  ('Q33973',  'Sicilian',     'Sicilian')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Old Saxon is the earliest recorded form of Low German, which 009 folds into
-- German, so it falls under the same historical-forms rule. The automatic match
-- in 009 missed it only because no reference language is called Saxon.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT 'Old Saxon', languages.id, 'mapped'
FROM languages
WHERE languages.label = 'German'
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Not languages. India is a country. Romance, Germanic languages and North
-- Germanic are families, rejected on the precedent of Germanic languages in 004
-- and Slavic languages in 005. Wikidata's Germanic languages item is a separate
-- row from the Wiktionary token of the same name, which 004 already rejected.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('India', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

INSERT INTO wikidata_language_items (item_qid, item_label, status)
VALUES
  ('Q19814',  'Romance',            'rejected'),
  ('Q21200',  'Germanic languages', 'rejected'),
  ('Q106085', 'North Germanic',     'rejected')
ON CONFLICT (item_qid) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

COMMIT;
