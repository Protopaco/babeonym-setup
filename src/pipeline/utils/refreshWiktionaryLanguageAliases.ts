import { query } from "../../utils/postGresPool";

/**
 * Registers every language token Wiktionary extraction has produced, maps the
 * ones that already name a row in the languages table, and refreshes how often
 * each was seen.
 *
 * Most tokens are plain language names — English, Danish, Spanish — and match
 * exactly, so making a person confirm them is busywork. What is left for review
 * is the part that needs a judgment: historical forms to fold in, languages the
 * reference list does not carry yet, and tokens that are not languages at all.
 *
 * Counts are recomputed from name_claims rather than incremented, so running
 * extraction twice does not inflate them. Rows already reviewed keep their
 * status and mapping — only the frequency moves.
 *
 * A token extraction stops producing is removed while it is still unreviewed.
 * Otherwise a parser fix — reading "de:Elisabeth" as German rather than as a
 * language called "de:Elisabeth" — would leave the old token in the queue for
 * good, still showing the count it had when last seen. A mapped or rejected row
 * is a decision and stays even if its token disappears.
 */
export default async () => {
  const inserted = await query(
    `
      INSERT INTO wiktionary_language_aliases (alias)
      SELECT DISTINCT claim_value
      FROM name_claims
      WHERE claim_type = 'language_of_origin'
        AND extraction_method LIKE 'wiktionary%'
      ON CONFLICT (alias) DO NOTHING
    `,
  );

  const autoMapped = await query(
    `
      UPDATE wiktionary_language_aliases alias_row
      SET language_id = matched_language.id,
          status = 'mapped',
          date_updated = NOW()
      FROM languages matched_language
      WHERE alias_row.status = 'unreviewed'
        AND LOWER(matched_language.label) = LOWER(alias_row.alias)
    `,
  );

  const removed = await query(
    `
      DELETE FROM wiktionary_language_aliases alias_row
      WHERE alias_row.status = 'unreviewed'
        AND NOT EXISTS (
          SELECT 1
          FROM name_claims
          WHERE claim_type = 'language_of_origin'
            AND extraction_method LIKE 'wiktionary%'
            AND claim_value = alias_row.alias
        )
    `,
  );

  await query(
    `
      UPDATE wiktionary_language_aliases alias_row
      SET times_seen = observed.occurrence_count,
          date_updated = NOW()
      FROM (
        SELECT claim_value, COUNT(*) AS occurrence_count
        FROM name_claims
        WHERE claim_type = 'language_of_origin'
          AND extraction_method LIKE 'wiktionary%'
        GROUP BY claim_value
      ) observed
      WHERE alias_row.alias = observed.claim_value
        AND alias_row.times_seen IS DISTINCT FROM observed.occurrence_count
    `,
  );

  const unreviewed = await query(
    `
      SELECT COUNT(*) AS unreviewed_count
      FROM wiktionary_language_aliases
      WHERE status = 'unreviewed'
    `,
  );

  return {
    newAliasCount: inserted.rowCount ?? 0,
    autoMappedCount: autoMapped.rowCount ?? 0,
    removedAliasCount: removed.rowCount ?? 0,
    unreviewedAliasCount: Number(unreviewed.rows[0].unreviewed_count),
  };
};
