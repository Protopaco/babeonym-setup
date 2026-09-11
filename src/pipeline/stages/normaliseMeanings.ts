import { closePool, query } from "../../utils/postGresPool";
import normaliseMeaningPhrases, {
  PhraseDropReason,
} from "../../sources/normaliseMeaningPhrases";

type MeaningSourceRow = {
  given_name_id: number;
  given_name: string;
  raw_text: string;
  source: string;
  extraction_method: string;
  confidence: string;
};

/**
 * The older Wikipedia scrape. meaning_long is deliberately not read: it holds
 * the article's opening paragraph rather than a meaning — "Nikolaus is a given
 * name. Notable people with this name include the following:" — and 3,047 names
 * have only that. Mining a meaning out of that prose is a job for a model, not
 * for separators.
 *
 * Confidence is a flat 0.6. The scrape recorded none, and inventing per-row
 * numbers would dress up a guess; 0.6 places it below a stated derivation gloss
 * and above a mention gloss, which is where the comparison put it.
 */
const WIKIPEDIA_CONFIDENCE = "0.6";

const getSourceRows = async () => {
  const result = await query(
    `
      SELECT
        gn.id AS given_name_id,
        gn.given_name,
        m.meaning_short AS raw_text,
        'wikipedia' AS source,
        'wikipedia_meaning_short' AS extraction_method,
        $1::text AS confidence
      FROM given_name_meaning m
      JOIN given_names gn ON gn.id = m.given_name_id
      WHERE m.meaning_short IS NOT NULL
        AND m.meaning_short <> ''

      UNION ALL

      SELECT
        c.given_name_id,
        gn.given_name,
        c.claim_value AS raw_text,
        'wiktionary' AS source,
        c.extraction_method,
        c.confidence::text
      FROM name_claims c
      JOIN given_names gn ON gn.id = c.given_name_id
      WHERE c.claim_type = 'meaning'
        AND c.extraction_method LIKE 'wiktionary%'

      ORDER BY given_name_id
    `,
    [WIKIPEDIA_CONFIDENCE],
  );

  return result.rows as MeaningSourceRow[];
};

/**
 * The normaliser is expected to be rewritten and re-run — the length limit, the
 * separators and the commentary patterns are all first guesses. Clearing the
 * table each time keeps a re-run from leaving phrases behind that the current
 * rules would no longer produce.
 */
const clearPreviousCandidates = async () => {
  await query(`TRUNCATE normalised_meaning_candidates RESTART IDENTITY`);
};

const saveCandidate = async (
  row: MeaningSourceRow,
  phrase: string,
): Promise<number> => {
  const result = await query(
    `
      INSERT INTO normalised_meaning_candidates (
        given_name_id,
        text,
        language_id,
        source,
        extraction_method,
        confidence,
        original_text,
        date_updated
      ) VALUES ($1, $2, NULL, $3, $4, $5, $6, NOW())
      ON CONFLICT (given_name_id, text, source, extraction_method) DO NOTHING
    `,
    [
      row.given_name_id,
      phrase,
      row.source,
      row.extraction_method,
      row.confidence,
      row.raw_text,
    ],
  );

  return result.rowCount ?? 0;
};

export default async () => {
  const rows = await getSourceRows();

  console.log(
    `Normalising meanings from ${rows.length} source strings across both sources...`,
  );

  const dropCounts = new Map<PhraseDropReason, number>();
  let writtenCount = 0;
  let duplicateAcrossSourcesCount = 0;
  const phrasesBySource = new Map<string, number>();

  try {
    await clearPreviousCandidates();

    for (const row of rows) {
      const { phrases, dropped } = normaliseMeaningPhrases(
        row.raw_text,
        row.given_name,
      );

      for (const drop of dropped) {
        dropCounts.set(drop.reason, (dropCounts.get(drop.reason) ?? 0) + 1);
      }

      for (const phrase of phrases) {
        const written = await saveCandidate(row, phrase);

        if (written > 0) {
          writtenCount++;
          phrasesBySource.set(
            row.source,
            (phrasesBySource.get(row.source) ?? 0) + 1,
          );
        } else {
          duplicateAcrossSourcesCount++;
        }
      }
    }

    const distinct = await query(
      `SELECT COUNT(DISTINCT text) AS distinct_meanings,
              COUNT(DISTINCT given_name_id) AS names_covered
       FROM normalised_meaning_candidates`,
    );

    console.log(
      `Normalisation complete. ${writtenCount} phrases written, ${distinct.rows[0].distinct_meanings} distinct meanings across ${distinct.rows[0].names_covered} names.`,
    );

    for (const [source, count] of [...phrasesBySource].sort()) {
      console.log(`  ${source}: ${count} phrases`);
    }

    console.log(`  dropped by rule:`);
    for (const [reason, count] of [...dropCounts].sort((a, b) => b[1] - a[1])) {
      console.log(`    ${reason}: ${count}`);
    }

    if (duplicateAcrossSourcesCount > 0) {
      console.log(
        `  ${duplicateAcrossSourcesCount} phrases already present for that name and method.`,
      );
    }
  } finally {
    await closePool();
  }
};
