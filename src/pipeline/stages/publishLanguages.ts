import { closePool, query } from "../../utils/postGresPool";

/**
 * Adds the languages worked out from Wiktionary and Wikidata to the bridge the
 * app already reads.
 *
 * Additive on purpose. The bridge carries no source column, so a pair written
 * by the older Wikipedia scrape and a pair written here are indistinguishable
 * afterwards — which means this merge cannot be unpicked later. It can always
 * be repeated, since every claim behind it stays in the workbench, but the old
 * scrape's own rows exist nowhere else and are left untouched rather than
 * rebuilt.
 *
 * Both sources resolve through the curated decisions: a Wiktionary token
 * through wiktionary_language_aliases, a Wikidata item through
 * wikidata_language_items, and only where the decision was to map it. A
 * rejected token contributes nothing.
 *
 * Transmission claims are included. A language a name passed through on its way
 * — Ancient Greek between Latin and Hebrew for Gabriel — is still a language
 * the name is associated with, which is the single fact this table records.
 */
const countNamesWithLanguage = async () => {
  const result = await query(
    `SELECT COUNT(DISTINCT given_name_id) AS names FROM given_name_language_bridge`,
  );

  return Number(result.rows[0].names);
};

export default async () => {
  try {
    const namesBefore = await countNamesWithLanguage();

    const inserted = await query(
      `
        INSERT INTO given_name_language_bridge (given_name_id, language_id)
        SELECT DISTINCT claim.given_name_id, alias.language_id
        FROM name_claims claim
        JOIN wiktionary_language_aliases alias
          ON alias.alias = claim.claim_value
         AND alias.status = 'mapped'
         AND alias.language_id IS NOT NULL
        WHERE claim.claim_type = 'language_of_origin'
          AND claim.extraction_method LIKE 'wiktionary%'

        UNION

        SELECT DISTINCT claim.given_name_id, item.language_id
        FROM name_claims claim
        JOIN wikidata_language_items item
          ON item.item_qid = claim.claim_value
         AND item.status = 'mapped'
         AND item.language_id IS NOT NULL
        WHERE claim.claim_type = 'language_of_origin'
          AND claim.extraction_method LIKE 'wikidata%'

        ON CONFLICT (given_name_id, language_id) DO NOTHING
      `,
    );

    const namesAfter = await countNamesWithLanguage();

    const summary = await query(
      `
        SELECT COUNT(*) AS pairings, COUNT(DISTINCT language_id) AS languages
        FROM given_name_language_bridge
      `,
    );

    console.log(`Published languages from both sources.`);
    console.log(
      `  ${inserted.rowCount} pairings added; names with a language ${namesBefore} -> ${namesAfter}.`,
    );
    console.log(
      `  ${summary.rows[0].pairings} pairings now, across ${summary.rows[0].languages} languages.`,
    );
  } finally {
    await closePool();
  }
};
