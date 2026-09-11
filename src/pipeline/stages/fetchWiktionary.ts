import { closePool, query } from "../../utils/postGresPool";
import fetchWiktionaryEntries, {
  WIKTIONARY_TITLES_PER_REQUEST,
  WiktionaryEntry,
} from "../../sources/wiktionary/client";
import createBatchPacer from "../utils/createBatchPacer";
import getDataSourceId from "../utils/getDataSourceId";
import getFetchQueue from "../utils/getFetchQueue";
import getPositiveIntArg from "../utils/getPositiveIntArg";

const saveSourceDocument = async (
  dataSourceId: number,
  entry: WiktionaryEntry,
) => {
  await query(
    `
      INSERT INTO source_documents (
        data_source_id,
        source_key,
        url,
        raw_payload,
        raw_text,
        fetched_at,
        date_updated
      ) VALUES ($1, $2, $3, $4::jsonb, $5, NOW(), NOW())
      ON CONFLICT (data_source_id, source_key) DO UPDATE
      SET url = EXCLUDED.url,
          raw_payload = EXCLUDED.raw_payload,
          raw_text = EXCLUDED.raw_text,
          fetched_at = EXCLUDED.fetched_at,
          date_updated = NOW()
    `,
    [
      dataSourceId,
      entry.requestedTitle,
      entry.url,
      JSON.stringify(entry.rawPayload),
      entry.rawText,
    ],
  );
};

export default async () => {
  const limit = getPositiveIntArg("--limit", 50, 200000);
  const spreadMinutes = getPositiveIntArg("--spread-minutes", 0, 1440);
  const dataSourceId = await getDataSourceId("Wiktionary");
  const names = await getFetchQueue(dataSourceId, limit);

  const batchCount = Math.ceil(names.length / WIKTIONARY_TITLES_PER_REQUEST);
  const pacer = createBatchPacer(batchCount, spreadMinutes);

  console.log(
    `Fetching Wiktionary evidence for ${names.length} names: ${pacer.describe()}`,
  );

  let foundCount = 0;
  let missingCount = 0;
  let failedBatchCount = 0;

  try {
    for (let batchIndex = 0; batchIndex < batchCount; batchIndex++) {
      const batch = names.slice(
        batchIndex * WIKTIONARY_TITLES_PER_REQUEST,
        (batchIndex + 1) * WIKTIONARY_TITLES_PER_REQUEST,
      );

      await pacer.waitForBatch(batchIndex);

      // A batch that cannot be fetched is skipped rather than ending the run.
      // Its names keep no source_documents row, so they stay in the queue and
      // the next run picks them up. Losing eight unattended hours to one bad
      // response is the worse failure.
      try {
        const entries = await fetchWiktionaryEntries(
          batch.map((name) => name.given_name),
        );

        for (const name of batch) {
          const entry = entries.get(name.given_name);

          if (!entry) {
            continue;
          }

          await saveSourceDocument(dataSourceId, entry);

          if (entry.exists) {
            foundCount++;
          } else {
            missingCount++;
          }
        }
      } catch (error) {
        failedBatchCount++;
        console.error(
          `  batch ${batchIndex + 1}/${batchCount} failed, skipping: ${error instanceof Error ? error.message : String(error)}`,
        );
        continue;
      }

      if (batchIndex % 10 === 0 || batchIndex === batchCount - 1) {
        console.log(
          `  batch ${batchIndex + 1}/${batchCount}: ${foundCount} found, ${missingCount} missing, ${failedBatchCount} batches skipped — about ${pacer.estimateRemaining(batchIndex)} remaining`,
        );
      }
    }

    console.log(
      `Wiktionary fetch complete. Found ${foundCount}, missing ${missingCount}, ${failedBatchCount} batches skipped.`,
    );
  } finally {
    await closePool();
  }
};
