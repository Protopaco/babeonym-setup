-- The comparison this round was built for: existing data beside newly extracted
-- claims, one row per name, most popular first.
--
-- The existing columns come from the earlier Wikipedia scrape. Nothing here
-- writes anything — this is for reading the two side by side and deciding what
-- the published tables should look like.
--
-- Derivation meanings are kept in their own column from mention meanings on
-- purpose. The derivation glosses are whole-name meanings and are close to
-- publishable as they stand; the mention glosses are etymological components
-- ("to defend" plus "man" for Alexander) mixed with surnames and filler.

WITH popularity AS (
  SELECT
    gn.id AS given_name_id,
    gn.given_name,
    SUM(pop.total_occurrences) AS total_occurrences
  FROM given_names gn
  LEFT JOIN given_name_popularity_by_decade pop
    ON pop.given_name_id = gn.id
  GROUP BY gn.id, gn.given_name
)
SELECT
  popularity.given_name,
  popularity.total_occurrences,

  existing_meaning.meaning_short AS existing_meaning_short,
  existing_meaning.meaning_long AS existing_meaning_long,
  (
    SELECT string_agg(l.label, ', ' ORDER BY l.label)
    FROM given_name_language_bridge b
    JOIN languages l ON l.id = b.language_id
    WHERE b.given_name_id = popularity.given_name_id
  ) AS existing_languages,
  (
    SELECT string_agg(c.label, ', ' ORDER BY c.label)
    FROM given_name_culture_bridge b
    JOIN cultures c ON c.id = b.culture_id
    WHERE b.given_name_id = popularity.given_name_id
  ) AS existing_cultures,

  (
    SELECT string_agg(DISTINCT c.claim_value, ' | ')
    FROM name_claims c
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'meaning'
      AND c.extraction_method = 'wiktionary_derivation_gloss'
  ) AS new_meaning_derivation,
  (
    SELECT string_agg(DISTINCT c.claim_value, ' | ')
    FROM name_claims c
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'meaning'
      AND c.extraction_method = 'wiktionary_mention_gloss'
  ) AS new_meaning_mention,

  (
    SELECT string_agg(DISTINCT c.claim_value, ', ')
    FROM name_claims c
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'language_of_origin'
      AND c.extraction_method = 'wiktionary_language_section'
  ) AS new_language_section,
  (
    SELECT string_agg(DISTINCT c.claim_value, ', ')
    FROM name_claims c
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'language_of_origin'
      AND c.extraction_method LIKE 'wiktionary_given_name_from%'
  ) AS new_language_from,
  (
    SELECT string_agg(DISTINCT COALESCE(item.item_label, c.claim_value), ', ')
    FROM name_claims c
    LEFT JOIN wikidata_language_items item
      ON item.item_qid = c.claim_value
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'language_of_origin'
      AND c.extraction_method LIKE 'wikidata%'
  ) AS new_language_wikidata,

  (
    SELECT string_agg(DISTINCT c.claim_value, ', ')
    FROM name_claims c
    WHERE c.given_name_id = popularity.given_name_id
      AND c.claim_type = 'gender'
  ) AS new_source_gender,

  (
    SELECT COUNT(*)
    FROM name_relationship_claims r
    WHERE r.given_name_id = popularity.given_name_id
  ) AS new_relationship_count
FROM popularity
LEFT JOIN given_name_meaning existing_meaning
  ON existing_meaning.given_name_id = popularity.given_name_id
WHERE EXISTS (
  SELECT 1
  FROM source_documents sd
  WHERE sd.source_key = popularity.given_name
)
ORDER BY popularity.total_occurrences DESC NULLS LAST, popularity.given_name
LIMIT 1000;
