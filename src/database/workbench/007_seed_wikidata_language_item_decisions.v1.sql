-- Curation decisions for the eight Wikidata language items that carried twenty
-- or more names each, reviewed after extraction ran over the full corpus.
--
-- Those eight accounted for 1,687 of the 2,105 claims awaiting a decision; the
-- remaining 166 thin items were left in the queue. The Wikidata counterpart to
-- 005.
--
-- Keyed on the item identifier rather than the label, unlike 005. The
-- identifier is the table's primary key and does not change; labels on Wikidata
-- do, and are edited by anyone. Keying on the label would let a relabel on
-- Wikidata's side quietly undo a decision recorded here. Labels are carried
-- alongside for readability and so a row can be created before extraction has
-- met the item.
--
-- Depends on 039_seed_wikidata_review_languages.v1.sql having run, since the
-- mappings join languages on label. Safe to re-run: a decision already recorded
-- is not overwritten.

BEGIN;

-- Languages added by 039. The refresh in the extraction stage would map these on
-- its own, but only at the end of a full re-extraction. Stating them here means
-- the queue settles on workbench:init.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q716686', 'Seediq',    'Seediq'),
  ('Q35132',  'Amis',      'Amis'),
  ('Q8765',   'Aragonese', 'Aragonese')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- The same language under another English name, which the exact-match
-- auto-mapper can never connect.
--
-- Slovene repeats the decision 005 made for Wiktionary; the two sources reached
-- the short form independently.
--
-- Bangla is the speakers' own name for the language, and the one Bangladesh
-- uses in English. The reference row stays Bengali because it is the name most
-- English-speaking parents will look for, and the languages table has no second
-- column to hold the other name. Relabelling the row later is a one-row edit
-- that leaves this mapping intact, since it points at the row's id.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q9063', 'Slovene', 'Slovenian'),
  ('Q9610', 'Bangla',  'Bengali')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Regional varieties folded into their language, following Norwegian Bokmål and
-- Nynorsk in 004.
--
-- Folding Brazilian Portuguese loses nothing about Brazil. The claims keep the
-- item identifier Q750553 in name_claims, so once a Brazilian culture row
-- exists those 46 names can be mapped to it directly, without re-fetching.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q750553', 'Brazilian Portuguese', 'Portuguese'),
  ('Q7976',   'American English',     'English')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Not a language. Wikidata's placeholder for a name used across many languages
-- that nobody listed individually — George, Juan, Liam. Rejection has to be
-- sticky, or every re-run puts it back in the queue.
INSERT INTO wikidata_language_items (item_qid, item_label, status)
VALUES
  ('Q20923490', 'multiple languages', 'rejected')
ON CONFLICT (item_qid) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

COMMIT;
