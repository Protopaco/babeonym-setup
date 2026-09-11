-- Names where the two sources resolve to different language sets.
--
-- Disagreement is expected and is not automatically a fault. Wiktionary files a
-- name under every language section that has an entry; Wikidata states the
-- languages a name item is used in, and its coverage is far more uneven —
-- Michael carries around ninety statements while Siobhan has nine and no
-- language at all.
--
-- What this is for is spotting the systematic gaps: languages one source knows
-- and the other never mentions. That is a hint about which alias rows are still
-- unmapped, not a reason to prefer one source.

WITH wiktionary_languages AS (
  SELECT DISTINCT
    c.given_name_id,
    alias.language_id
  FROM name_claims c
  JOIN wiktionary_language_aliases alias
    ON alias.alias = c.claim_value
  WHERE c.claim_type = 'language_of_origin'
    AND c.extraction_method LIKE 'wiktionary%'
    AND alias.status = 'mapped'
    AND alias.language_id IS NOT NULL
),
wikidata_languages AS (
  SELECT DISTINCT
    c.given_name_id,
    item.language_id
  FROM name_claims c
  JOIN wikidata_language_items item
    ON item.item_qid = c.claim_value
  WHERE c.claim_type = 'language_of_origin'
    AND c.extraction_method LIKE 'wikidata%'
    AND item.status = 'mapped'
    AND item.language_id IS NOT NULL
)
SELECT
  gn.given_name,
  (
    SELECT string_agg(l.label, ', ' ORDER BY l.label)
    FROM wiktionary_languages w
    JOIN languages l ON l.id = w.language_id
    WHERE w.given_name_id = gn.id
  ) AS wiktionary_only_and_shared,
  (
    SELECT string_agg(l.label, ', ' ORDER BY l.label)
    FROM wikidata_languages d
    JOIN languages l ON l.id = d.language_id
    WHERE d.given_name_id = gn.id
  ) AS wikidata_only_and_shared,
  (
    SELECT string_agg(l.label, ', ' ORDER BY l.label)
    FROM wiktionary_languages w
    JOIN languages l ON l.id = w.language_id
    WHERE w.given_name_id = gn.id
      AND NOT EXISTS (
        SELECT 1 FROM wikidata_languages d
        WHERE d.given_name_id = gn.id AND d.language_id = w.language_id
      )
  ) AS wiktionary_only,
  (
    SELECT string_agg(l.label, ', ' ORDER BY l.label)
    FROM wikidata_languages d
    JOIN languages l ON l.id = d.language_id
    WHERE d.given_name_id = gn.id
      AND NOT EXISTS (
        SELECT 1 FROM wiktionary_languages w
        WHERE w.given_name_id = gn.id AND w.language_id = d.language_id
      )
  ) AS wikidata_only
FROM given_names gn
WHERE EXISTS (SELECT 1 FROM wiktionary_languages w WHERE w.given_name_id = gn.id)
  AND EXISTS (SELECT 1 FROM wikidata_languages d WHERE d.given_name_id = gn.id)
ORDER BY gn.given_name;
