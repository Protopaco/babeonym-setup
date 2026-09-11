-- Coverage across the fetched set, sliced into ten bands by popularity.
--
-- A flat percentage is not the useful number; the shape of the decline is. The
-- expectation is that coverage falls as names get rarer, and a low rate in the
-- tail is not a reason to stop fetching — names that are rare in US birth data
-- are often central somewhere else.
--
-- Two separate match measures matter here. page_exists says Wiktionary has an
-- entry at all; has_given_name_content says that entry carried a {{given name}}
-- template we could read. The gap between them separates "the source does not
-- cover this name" from "our extraction is leaving data behind".

WITH popularity AS (
  SELECT
    gn.id AS given_name_id,
    gn.given_name,
    SUM(pop.total_occurrences) AS total_occurrences
  FROM given_names gn
  LEFT JOIN given_name_popularity_by_decade pop
    ON pop.given_name_id = gn.id
  GROUP BY gn.id, gn.given_name
),
wiktionary_documents AS (
  SELECT sd.source_key, sd.raw_text
  FROM source_documents sd
  JOIN data_sources ds ON ds.id = sd.data_source_id
  WHERE ds.label = 'Wiktionary'
),
wikidata_documents AS (
  SELECT sd.source_key, sd.raw_payload
  FROM source_documents sd
  JOIN data_sources ds ON ds.id = sd.data_source_id
  WHERE ds.label = 'Wikidata'
),
fetched AS (
  SELECT
    popularity.given_name_id,
    popularity.given_name,
    popularity.total_occurrences,
    NTILE(10) OVER (
      ORDER BY popularity.total_occurrences DESC NULLS LAST, popularity.given_name
    ) AS popularity_band,
    wiktionary_documents.raw_text IS NOT NULL AS wiktionary_page_exists,
    wikidata_documents.source_key IS NOT NULL AS wikidata_fetched,
    jsonb_array_length(
      COALESCE(wikidata_documents.raw_payload -> 'identity', '[]'::jsonb)
    ) > 0 AS wikidata_item_found
  FROM popularity
  LEFT JOIN wiktionary_documents
    ON wiktionary_documents.source_key = popularity.given_name
  LEFT JOIN wikidata_documents
    ON wikidata_documents.source_key = popularity.given_name
  WHERE wiktionary_documents.source_key IS NOT NULL
     OR wikidata_documents.source_key IS NOT NULL
)
SELECT
  fetched.popularity_band,
  COUNT(*) AS names,
  MIN(fetched.total_occurrences) AS lowest_occurrences,
  MAX(fetched.total_occurrences) AS highest_occurrences,
  COUNT(*) FILTER (WHERE fetched.wiktionary_page_exists) AS wiktionary_page_exists,
  COUNT(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM name_claims c
      WHERE c.given_name_id = fetched.given_name_id
        AND c.extraction_method LIKE 'wiktionary%'
    )
  ) AS has_given_name_content,
  COUNT(*) FILTER (WHERE fetched.wikidata_item_found) AS wikidata_item_found,
  COUNT(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM name_claims c
      WHERE c.given_name_id = fetched.given_name_id
        AND c.claim_type = 'language_of_origin'
    )
  ) AS has_language,
  COUNT(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM name_claims c
      WHERE c.given_name_id = fetched.given_name_id
        AND c.claim_type = 'meaning'
        AND c.extraction_method = 'wiktionary_derivation_gloss'
    )
  ) AS has_derivation_meaning,
  COUNT(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM name_claims c
      WHERE c.given_name_id = fetched.given_name_id
        AND c.claim_type = 'meaning'
    )
  ) AS has_any_meaning,
  COUNT(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM name_relationship_claims r
      WHERE r.given_name_id = fetched.given_name_id
    )
  ) AS has_relationships
FROM fetched
GROUP BY fetched.popularity_band
ORDER BY fetched.popularity_band;
