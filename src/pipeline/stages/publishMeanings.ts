import { closePool, getClient, query } from "../../utils/postGresPool";

/**
 * Everything the normaliser keeps is published, mention tier included.
 *
 * The floor was 0.6 while that tier carried the noise. With the bleed, the
 * filler and the name-pointers now dropped at normalisation, what is left in it
 * is ordinary: Matthew's "gift of the Lord", Catherine's "pure", Edward's
 * "rich", each glossed on a mention template because that is how those entries
 * are written. Holding the floor at 0.6 left those pages blank while the data
 * sat in the workbench.
 *
 * Confidence still rides on every row, so a consumer that wants only the
 * stronger tier can filter for it.
 *
 * It applies to the raw rows only. A curated row was read and decided on by a
 * person, which outranks the number it inherited from the phrases it cites.
 */
const PUBLISH_CONFIDENCE_FLOOR = "0.5";

/**
 * Copies the workbench's meanings into the app-facing tables, preferring the
 * curation pass to the rules wherever it has run.
 *
 * A name with any curated row publishes its curated rows and nothing else. The
 * pass read the same raw rows and decided what belongs, so publishing both
 * would restore exactly what it dropped. A name curated to nothing publishes
 * nothing at all. Every other name publishes from the raw rows as before, which
 * makes partial curation an ordinary state rather than a half-finished
 * migration.
 *
 * The bridge is rebuilt rather than merged: the normaliser's rules are still
 * changing, and a row it no longer produces should not survive in what the app
 * reads. Doing it inside one transaction means readers see the previous set
 * until the new one is complete, so there is no window where a name has no
 * meaning.
 *
 * Meaning text is kept across runs and only removed when nothing points at it
 * any more, so ids stay stable for anything that has already referenced them.
 *
 * Curated text publishes as written, capitals and all — "God is gracious",
 * "Christ-bearer". It was lowercased here for as long as the pass was partway
 * through, because meanings dedupes on exact text and publishing "Bear" beside
 * the "bear" an un-curated name still pointed at would have split one shared
 * row into two. The pass now covers every name that has a raw row, so nothing
 * publishes from the raw tier and there is no lowercase twin left to collide
 * with. A curator reading a phrase writes it properly, and that judgment is
 * what the app should show.
 */
export default async () => {
  const client = await getClient();

  try {
    await client.query("BEGIN");

    await client.query(
      `
        CREATE TEMP TABLE publishable_meanings (
          given_name_id INT NOT NULL,
          text TEXT NOT NULL,
          language_id INT,
          source TEXT NOT NULL,
          extraction_method TEXT NOT NULL,
          confidence NUMERIC NOT NULL
        ) ON COMMIT DROP
      `,
    );

    await client.query(
      `
        INSERT INTO publishable_meanings (
          given_name_id,
          text,
          language_id,
          source,
          extraction_method,
          confidence
        )
        SELECT
          curated.given_name_id,
          curated.text,
          curated.language_id,
          'curated',
          'curation_pass',
          curated.confidence
        FROM curated_meanings curated
        WHERE curated.text <> ''

        UNION ALL

        SELECT
          raw.given_name_id,
          raw.text,
          raw.language_id,
          raw.source,
          raw.extraction_method,
          raw.confidence
        FROM normalised_meaning_candidates raw
        WHERE raw.confidence >= $1
          AND NOT EXISTS (
            SELECT 1
            FROM curated_meanings curated
            WHERE curated.given_name_id = raw.given_name_id
          )
      `,
      [PUBLISH_CONFIDENCE_FLOOR],
    );

    const insertedMeanings = await client.query(
      `
        INSERT INTO meanings (text)
        SELECT DISTINCT text
        FROM publishable_meanings
        ON CONFLICT (text) DO NOTHING
      `,
    );

    await client.query(`DELETE FROM given_name_meaning_bridge`);

    const bridged = await client.query(
      `
        INSERT INTO given_name_meaning_bridge (
          given_name_id,
          meaning_id,
          language_id,
          source,
          extraction_method,
          confidence,
          date_updated
        )
        SELECT
          publishable.given_name_id,
          meaning.id,
          publishable.language_id,
          publishable.source,
          publishable.extraction_method,
          publishable.confidence,
          NOW()
        FROM publishable_meanings publishable
        JOIN meanings meaning ON meaning.text = publishable.text
      `,
    );

    // A meaning's language is one the name is used in, so it belongs among the
    // name's languages too — otherwise the page shows a meaning under Irish for
    // a name that does not list Irish, and the language filter misses it. The
    // language bridge is additive and carries no source column, so these rows
    // stay even if a later run drops the meaning that added them.
    const addedLanguages = await client.query(
      `
        INSERT INTO given_name_language_bridge (given_name_id, language_id)
        SELECT DISTINCT bridge.given_name_id, bridge.language_id
        FROM given_name_meaning_bridge bridge
        WHERE bridge.language_id IS NOT NULL
        ON CONFLICT (given_name_id, language_id) DO NOTHING
      `,
    );

    const removedMeanings = await client.query(
      `
        DELETE FROM meanings orphan
        WHERE NOT EXISTS (
          SELECT 1
          FROM given_name_meaning_bridge bridge
          WHERE bridge.meaning_id = orphan.id
        )
      `,
    );

    await client.query("COMMIT");

    console.log(
      `Published meanings, curated where curated and at confidence ${PUBLISH_CONFIDENCE_FLOOR} and above elsewhere.`,
    );
    console.log(
      `  ${bridged.rowCount} pairings written, ${insertedMeanings.rowCount} meanings added, ${removedMeanings.rowCount} no longer referenced and removed.`,
    );
    console.log(
      `  ${addedLanguages.rowCount} name-language pairings added from meaning languages.`,
    );

    const summary = await query(
      `
        SELECT
          COUNT(*) AS pairings,
          COUNT(DISTINCT given_name_id) AS names,
          COUNT(DISTINCT meaning_id) AS distinct_meanings,
          COUNT(*) FILTER (WHERE language_id IS NOT NULL) AS pairings_with_language,
          COUNT(DISTINCT language_id) AS languages,
          COUNT(*) FILTER (WHERE source = 'curated') AS curated_pairings,
          COUNT(DISTINCT given_name_id) FILTER (WHERE source = 'curated') AS curated_names
        FROM given_name_meaning_bridge
      `,
    );

    const row = summary.rows[0];
    console.log(
      `  ${row.pairings} pairings cover ${row.names} names and ${row.distinct_meanings} distinct meanings.`,
    );
    console.log(
      `  ${row.pairings_with_language} pairings carry a language, drawn from ${row.languages}.`,
    );

    const curated = await query(
      `
        SELECT
          COUNT(DISTINCT given_name_id) AS curated_names,
          COUNT(DISTINCT given_name_id) FILTER (WHERE text = '') AS names_curated_to_nothing
        FROM curated_meanings
      `,
    );

    console.log(
      `  ${row.curated_pairings} pairings on ${row.curated_names} names come from the curation pass, which has covered ${curated.rows[0].curated_names} names and emptied ${curated.rows[0].names_curated_to_nothing}.`,
    );
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await closePool();
  }
};
