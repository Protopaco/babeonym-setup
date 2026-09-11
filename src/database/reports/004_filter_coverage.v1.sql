-- How many names each language filter would actually offer.
--
-- The number that predicts whether the Greek filter is any good is how many
-- names carry the Greek tag, not what percentage of the dataset matched
-- something. A filter is only worth offering above some floor — five names,
-- possibly ten — because an empty filter is worse than no filter. This report
-- is what sets that floor against real distributions.
--
-- Counts are of resolved claims only: a token still sitting unreviewed in the
-- alias tables contributes nothing, which is the point.

WITH resolved_language_claims AS (
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

  UNION

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
  l.label AS language,
  COUNT(DISTINCT resolved_language_claims.given_name_id) AS name_count,
  COUNT(DISTINCT resolved_language_claims.given_name_id) >= 10 AS meets_ten,
  COUNT(DISTINCT resolved_language_claims.given_name_id) >= 5 AS meets_five,
  (
    SELECT COUNT(*)
    FROM given_name_language_bridge b
    WHERE b.language_id = l.id
  ) AS existing_name_count
FROM languages l
LEFT JOIN resolved_language_claims
  ON resolved_language_claims.language_id = l.id
GROUP BY l.id, l.label
ORDER BY name_count DESC, l.label;
