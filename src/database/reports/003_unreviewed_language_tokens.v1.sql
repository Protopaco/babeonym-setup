-- The curation queue for both alias tables, most frequent first.
--
-- This is the "police rules, not names" list: fixing the token that appears
-- four hundred times is worth more than the one that appears once, and the
-- ordering makes that obvious without reading every row.
--
-- To resolve a row, set language_id and status:
--   UPDATE wiktionary_language_aliases
--   SET language_id = (SELECT id FROM languages WHERE label = 'Greek'),
--       status = 'mapped'
--   WHERE alias = 'Ancient Greek';
--
-- For a token that is not a language at all — 'surnames', 'the Bible' — mark it
-- rejected so it stops reappearing:
--   UPDATE wiktionary_language_aliases
--   SET status = 'rejected'
--   WHERE alias = 'the Bible';

SELECT
  'wiktionary' AS source,
  alias AS token,
  NULL AS item_qid,
  times_seen,
  status,
  EXISTS (
    SELECT 1 FROM languages l
    WHERE LOWER(l.label) = LOWER(wiktionary_language_aliases.alias)
  ) AS exact_language_match_available
FROM wiktionary_language_aliases
WHERE status = 'unreviewed'

UNION ALL

SELECT
  'wikidata' AS source,
  item_label AS token,
  item_qid,
  times_seen,
  status,
  FALSE AS exact_language_match_available
FROM wikidata_language_items
WHERE status = 'unreviewed'

ORDER BY times_seen DESC, token;
