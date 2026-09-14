import fs from "fs";
import path from "path";
import { closePool, getClient, query } from "../../utils/postGresPool";
import getFileNamesInFolder from "../../utils/getFileNamesInFolder";
import parseCsv from "../utils/parseCsv";

const curatedBatchPath = path.resolve(__dirname, "../../database/data/curated");

const BATCH_FILE_NAME = /^meanings-batch-\d{3}\.csv$/;

const EXPECTED_COLUMNS = [
  "given_name",
  "text",
  "language",
  "source_phrases",
  "note",
];

const PHRASE_SEPARATOR = "|";

type CuratedRow = {
  batchFile: string;
  rowNumber: number;
  givenName: string;
  text: string;
  language: string;
  sourcePhrases: string[];
  note: string;
};

type ResolvedRow = CuratedRow & {
  givenNameId: number;
  languageId: number | null;
  confidence: string | null;
};

const getBatchFileNames = () => {
  if (!fs.existsSync(curatedBatchPath)) {
    return [];
  }

  return getFileNamesInFolder(curatedBatchPath)
    .filter((fileName) => BATCH_FILE_NAME.test(fileName))
    .sort();
};

const readBatchRows = (batchFile: string): CuratedRow[] => {
  const fileContents = fs.readFileSync(
    path.join(curatedBatchPath, batchFile),
    "utf8",
  );

  const [header, ...dataRows] = parseCsv(fileContents);

  if (header === undefined) {
    throw new Error(`${batchFile} is empty.`);
  }

  if (header.join(",") !== EXPECTED_COLUMNS.join(",")) {
    throw new Error(
      `${batchFile} has columns ${header.join(",")}, expected ${EXPECTED_COLUMNS.join(",")}.`,
    );
  }

  return dataRows.map((fields, index) => {
    if (fields.length !== EXPECTED_COLUMNS.length) {
      throw new Error(
        `${batchFile} row ${index + 1} has ${fields.length} fields, expected ${EXPECTED_COLUMNS.length}.`,
      );
    }

    const [givenName = "", text = "", language = "", sourcePhrases = "", note = ""] =
      fields;

    return {
      batchFile,
      rowNumber: index + 1,
      givenName: givenName.trim(),
      text: text.trim(),
      language: language.trim(),
      sourcePhrases: sourcePhrases
        .split(PHRASE_SEPARATOR)
        .map((phrase) => phrase.trim())
        .filter((phrase) => phrase !== ""),
      note: note.trim(),
    };
  });
};

const getGivenNameIds = async () => {
  const result = await query(`SELECT id, given_name FROM given_names`);

  return new Map<string, number>(
    result.rows.map((row) => [row.given_name.toLowerCase(), row.id]),
  );
};

const getLanguageIds = async () => {
  const result = await query(`SELECT id, label FROM languages`);

  return new Map<string, number>(
    result.rows.map((row) => [row.label.toLowerCase(), row.id]),
  );
};

/**
 * The strongest confidence each raw phrase reached for a name. A phrase can
 * arrive more than once for one name — the same gloss from two templates — and
 * the curator cited the phrase rather than one of its rows, so the best of them
 * is what the curated line inherits.
 */
const getRawPhraseConfidence = async () => {
  const result = await query(
    `
      SELECT given_name_id, text, MAX(confidence)::text AS confidence
      FROM normalised_meaning_candidates
      GROUP BY given_name_id, text
    `,
  );

  const confidenceByName = new Map<number, Map<string, string>>();

  for (const row of result.rows) {
    const phrases =
      confidenceByName.get(row.given_name_id) ?? new Map<string, string>();

    phrases.set(row.text.toLowerCase(), row.confidence);
    confidenceByName.set(row.given_name_id, phrases);
  }

  return confidenceByName;
};

/**
 * Resolves every batch row against the database, collecting problems rather
 * than stopping at the first. A batch is loaded whole or not at all: a CSV with
 * three bad rows should be corrected in one pass, not discovered three runs in
 * a row.
 */
const resolveRows = async (rows: CuratedRow[]) => {
  const givenNameIds = await getGivenNameIds();
  const languageIds = await getLanguageIds();
  const rawPhraseConfidence = await getRawPhraseConfidence();

  const resolved: ResolvedRow[] = [];
  const problems: string[] = [];
  const rowsAlreadySeen = new Map<string, CuratedRow>();

  for (const row of rows) {
    const location = `${row.batchFile} row ${row.rowNumber} (${row.givenName || "no name"})`;

    const givenNameId = givenNameIds.get(row.givenName.toLowerCase());

    if (givenNameId === undefined) {
      problems.push(`${location}: no given name by that spelling.`);
      continue;
    }

    let languageId: number | null = null;

    if (row.language !== "") {
      const foundLanguageId = languageIds.get(row.language.toLowerCase());

      if (foundLanguageId === undefined) {
        problems.push(`${location}: no language labelled "${row.language}".`);
        continue;
      }

      languageId = foundLanguageId;
    }

    if (row.sourcePhrases.length === 0) {
      problems.push(`${location}: cites no source phrases.`);
      continue;
    }

    const phraseConfidence =
      rawPhraseConfidence.get(givenNameId) ?? new Map<string, string>();

    const uncitablePhrases: string[] = [];
    let confidence: string | null = null;

    for (const phrase of row.sourcePhrases) {
      const phraseConfidenceValue = phraseConfidence.get(phrase.toLowerCase());

      if (phraseConfidenceValue === undefined) {
        uncitablePhrases.push(phrase);
        continue;
      }

      if (
        confidence === null ||
        Number(phraseConfidenceValue) > Number(confidence)
      ) {
        confidence = phraseConfidenceValue;
      }
    }

    // The invention check, run where it is cheapest to fix: a phrase the raw
    // rows for that name never contained means the curated line came from
    // somewhere other than the source.
    if (uncitablePhrases.length > 0) {
      problems.push(
        `${location}: cites phrases this name has no raw row for: ${uncitablePhrases.join(", ")}.`,
      );
      continue;
    }

    // Case-insensitive, because publishing lowercases. "Bear" and "bear" on one
    // name would read as two curated rows here and then collide on the bridge's
    // unique constraint, which is a long way from the batch that caused it.
    const rowKey = `${givenNameId}|${row.text.toLowerCase()}|${languageId ?? ""}`;
    const duplicatedRow = rowsAlreadySeen.get(rowKey);

    if (duplicatedRow !== undefined) {
      problems.push(
        `${location}: already curated by ${duplicatedRow.batchFile} row ${duplicatedRow.rowNumber}.`,
      );
      continue;
    }

    rowsAlreadySeen.set(rowKey, row);

    resolved.push({
      ...row,
      givenNameId,
      languageId,
      confidence: row.text === "" ? null : confidence,
    });
  }

  return { resolved, problems };
};

/**
 * Replaces the table rather than merging into it. The CSVs are the record, so
 * whatever they say now is the whole truth — a line deleted from a batch should
 * disappear here too, and a corrected batch should just be re-run.
 */
const writeRows = async (rows: ResolvedRow[]) => {
  const client = await getClient();

  try {
    await client.query("BEGIN");
    await client.query("TRUNCATE curated_meanings RESTART IDENTITY");

    for (const row of rows) {
      await client.query(
        `
          INSERT INTO curated_meanings (
            given_name_id,
            text,
            language_id,
            source_phrases,
            confidence,
            note,
            batch_file,
            date_updated
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        `,
        [
          row.givenNameId,
          row.text,
          row.languageId,
          row.sourcePhrases.join(PHRASE_SEPARATOR),
          row.confidence,
          row.note,
          row.batchFile,
        ],
      );
    }

    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

export default async () => {
  try {
    const batchFiles = getBatchFileNames();

    if (batchFiles.length === 0) {
      console.log(`No curated batches found in ${curatedBatchPath}.`);
      return;
    }

    const rows = batchFiles.flatMap(readBatchRows);

    console.log(
      `Read ${rows.length} curated rows from ${batchFiles.length} batch file(s): ${batchFiles.join(", ")}.`,
    );

    const { resolved, problems } = await resolveRows(rows);

    if (problems.length > 0) {
      console.error(`${problems.length} row(s) could not be loaded:`);
      for (const problem of problems) {
        console.error(`  ${problem}`);
      }

      throw new Error(
        "Nothing was loaded. Correct the batch files and run this again.",
      );
    }

    await writeRows(resolved);

    const namesCovered = new Set(resolved.map((row) => row.givenNameId));
    const namesCuratedToNothing = new Set(
      resolved.filter((row) => row.text === "").map((row) => row.givenNameId),
    );
    const rowsWithLanguage = resolved.filter(
      (row) => row.languageId !== null,
    ).length;

    console.log(`Loaded ${resolved.length} curated rows.`);
    console.log(
      `  ${namesCovered.size} names covered, ${namesCuratedToNothing.size} curated to nothing.`,
    );
    console.log(`  ${rowsWithLanguage} rows carry a language.`);
  } finally {
    await closePool();
  }
};
