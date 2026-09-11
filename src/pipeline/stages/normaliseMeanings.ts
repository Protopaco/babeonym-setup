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
  /** Wiktionary's name for the language the gloss translates, as extracted. */
  source_language: string | null;
  source_language_status: "unreviewed" | "mapped" | "rejected" | null;
  language_id: number | null;
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

/**
 * A Wiktionary meaning carries the language its gloss translates, resolved
 * through the same alias decisions as origin languages. Only a mapped decision
 * sets language_id. A rejected one — the proto-languages — leaves the phrase
 * with no language rather than gaining a row for a reconstruction, and so does
 * a language nobody has decided on yet; those are named in the log so they can
 * be reviewed.
 *
 * The Wikipedia scrape records no language for its meanings, so its phrases
 * have none.
 */
const getSourceRows = async () => {
  const result = await query(
    `
      SELECT
        gn.id AS given_name_id,
        gn.given_name,
        m.meaning_short AS raw_text,
        'wikipedia' AS source,
        'wikipedia_meaning_short' AS extraction_method,
        $1::text AS confidence,
        NULL::text AS source_language,
        NULL::text AS source_language_status,
        NULL::int AS language_id
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
        c.confidence::text,
        c.evidence->>'language',
        alias.status::text,
        CASE WHEN alias.status = 'mapped' THEN alias.language_id END
      FROM name_claims c
      JOIN given_names gn ON gn.id = c.given_name_id
      LEFT JOIN wiktionary_language_aliases alias
        ON alias.alias = c.evidence->>'language'
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
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      ON CONFLICT (
        given_name_id,
        text,
        source,
        extraction_method,
        language_id
      ) DO NOTHING
    `,
    [
      row.given_name_id,
      phrase,
      row.language_id,
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

  let languageTaggedPhraseCount = 0;
  let rejectedLanguagePhraseCount = 0;
  let unreadLanguagePhraseCount = 0;
  const undecidedLanguageClaimCounts = new Map<string, number>();

  try {
    await clearPreviousCandidates();

    for (const row of rows) {
      // Counted per claim, before any phrase is written, so a language with no
      // decision is named even when its phrase collides with another blank one
      // or its only gloss is too long to keep.
      if (
        row.source === "wiktionary" &&
        row.source_language !== null &&
        row.source_language_status !== "mapped" &&
        row.source_language_status !== "rejected"
      ) {
        undecidedLanguageClaimCounts.set(
          row.source_language,
          (undecidedLanguageClaimCounts.get(row.source_language) ?? 0) + 1,
        );
      }

      const { phrases, dropped } = normaliseMeaningPhrases(
        row.raw_text,
        row.given_name,
      );

      for (const drop of dropped) {
        dropCounts.set(drop.reason, (dropCounts.get(drop.reason) ?? 0) + 1);
      }

      for (const phrase of phrases) {
        const written = await saveCandidate(row, phrase);

        if (written === 0) {
          duplicateAcrossSourcesCount++;
          continue;
        }

        writtenCount++;
        phrasesBySource.set(
          row.source,
          (phrasesBySource.get(row.source) ?? 0) + 1,
        );

        if (row.source !== "wiktionary") {
          continue;
        }

        if (row.language_id !== null) {
          languageTaggedPhraseCount++;
        } else if (row.source_language === null) {
          unreadLanguagePhraseCount++;
        } else if (row.source_language_status === "rejected") {
          rejectedLanguagePhraseCount++;
        }
      }
    }

    const distinct = await query(
      `SELECT COUNT(DISTINCT text) AS distinct_meanings,
              COUNT(DISTINCT given_name_id) AS names_covered,
              COUNT(DISTINCT given_name_id) FILTER (WHERE language_id IS NOT NULL) AS names_with_language
       FROM normalised_meaning_candidates`,
    );

    console.log(
      `Normalisation complete. ${writtenCount} phrases written, ${distinct.rows[0].distinct_meanings} distinct meanings across ${distinct.rows[0].names_covered} names.`,
    );

    for (const [source, count] of [...phrasesBySource].sort()) {
      console.log(`  ${source}: ${count} phrases`);
    }

    console.log(
      `  language: ${languageTaggedPhraseCount} Wiktionary phrases tagged across ${distinct.rows[0].names_with_language} names, ${rejectedLanguagePhraseCount} from a rejected language, ${unreadLanguagePhraseCount} with no language read.`,
    );

    const undecidedClaimTotal = [
      ...undecidedLanguageClaimCounts.values(),
    ].reduce((total, count) => total + count, 0);

    if (undecidedClaimTotal > 0) {
      console.log(
        `  languages with no decision yet (${undecidedClaimTotal} claims):`,
      );
      for (const [language, count] of [...undecidedLanguageClaimCounts].sort(
        (a, b) => b[1] - a[1],
      )) {
        console.log(`    ${language}: ${count}`);
      }
    }

    console.log(`  dropped by rule:`);
    for (const [reason, count] of [...dropCounts].sort((a, b) => b[1] - a[1])) {
      console.log(`    ${reason}: ${count}`);
    }

    if (duplicateAcrossSourcesCount > 0) {
      console.log(
        `  ${duplicateAcrossSourcesCount} phrases already present for that name, method and language.`,
      );
    }
  } finally {
    await closePool();
  }
};
