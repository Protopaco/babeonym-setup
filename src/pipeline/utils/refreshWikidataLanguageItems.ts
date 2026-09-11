import { query } from "../../utils/postGresPool";

type WikidataLanguageItem = {
  itemQid: string;
  label: string | null;
};

/**
 * Registers the language items Wikidata extraction has seen, then maps the ones
 * whose label already matches a row in the languages table.
 *
 * Unlike Wiktionary's free-text from= field, these are typed statements
 * pointing at language items, so most map cleanly and the review queue only
 * collects genuine oddities. Anything already reviewed by hand is left alone.
 */
export default async (languageItems: WikidataLanguageItem[]) => {
  for (const item of languageItems) {
    await query(
      `
        INSERT INTO wikidata_language_items (item_qid, item_label)
        VALUES ($1, $2)
        ON CONFLICT (item_qid) DO UPDATE
        SET item_label = COALESCE(
              EXCLUDED.item_label,
              wikidata_language_items.item_label
            ),
            date_updated = NOW()
      `,
      [item.itemQid, item.label],
    );
  }

  const autoMapped = await query(
    `
      UPDATE wikidata_language_items language_item
      SET language_id = matched_language.id,
          status = 'mapped',
          date_updated = NOW()
      FROM languages matched_language
      WHERE language_item.status = 'unreviewed'
        AND language_item.item_label IS NOT NULL
        AND LOWER(matched_language.label) = LOWER(language_item.item_label)
    `,
  );

  await query(
    `
      UPDATE wikidata_language_items language_item
      SET times_seen = observed.occurrence_count,
          date_updated = NOW()
      FROM (
        SELECT claim_value, COUNT(*) AS occurrence_count
        FROM name_claims
        WHERE claim_type = 'language_of_origin'
          AND extraction_method LIKE 'wikidata%'
        GROUP BY claim_value
      ) observed
      WHERE language_item.item_qid = observed.claim_value
        AND language_item.times_seen IS DISTINCT FROM observed.occurrence_count
    `,
  );

  const unreviewed = await query(
    `
      SELECT COUNT(*) AS unreviewed_count
      FROM wikidata_language_items
      WHERE status = 'unreviewed'
    `,
  );

  return {
    autoMappedCount: autoMapped.rowCount ?? 0,
    unreviewedCount: Number(unreviewed.rows[0].unreviewed_count),
  };
};
