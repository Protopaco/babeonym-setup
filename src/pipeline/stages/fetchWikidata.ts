import { closePool, query } from "../../utils/postGresPool";
import buildIdentityQuery from "../../sources/wikidata/buildIdentityQuery";
import buildRelationshipQuery from "../../sources/wikidata/buildRelationshipQuery";
import runSparqlQuery, {
  SparqlBinding,
  toEntityId,
} from "../../sources/wikidata/sparqlClient";
import createBatchPacer from "../utils/createBatchPacer";
import getDataSourceId from "../utils/getDataSourceId";
import getFetchQueue from "../utils/getFetchQueue";
import getPositiveIntArg from "../utils/getPositiveIntArg";
import type { WikidataDocument } from "../../sources/wikidata/extractClaims";

const DEFAULT_NAMES_PER_QUERY = 50;

/**
 * A retained safety net rather than the working mechanism it once was. With the
 * type join gone from both queries a batch of fifty answers in about a second,
 * so this should now fire rarely — but a single pathological name can still
 * blow past the sixty-second limit, and halving is cheaper than losing the run.
 */
const runQueryWithSplitting = async (
  batchItems: string[],
  buildQuery: (items: string[]) => string,
  queryLabel: string,
): Promise<SparqlBinding[]> => {
  try {
    const results = await runSparqlQuery(buildQuery(batchItems));
    return results.results.bindings;
  } catch (error) {
    if (batchItems.length === 1) {
      throw error;
    }

    const midpoint = Math.ceil(batchItems.length / 2);
    console.warn(
      `  ${queryLabel} query failed for ${batchItems.length}; splitting into ${midpoint} and ${batchItems.length - midpoint}`,
    );

    return [
      ...(await runQueryWithSplitting(
        batchItems.slice(0, midpoint),
        buildQuery,
        queryLabel,
      )),
      ...(await runQueryWithSplitting(
        batchItems.slice(midpoint),
        buildQuery,
        queryLabel,
      )),
    ];
  }
};

const getGivenNameTypeQids = async () => {
  const result = await query(
    `SELECT item_qid FROM wikidata_given_name_types ORDER BY item_qid`,
  );

  if (result.rowCount === 0) {
    throw new Error(
      "No Wikidata given-name types stored. Run wikidata:refresh-types first.",
    );
  }

  return new Set(result.rows.map((row) => row.item_qid as string));
};

const groupBindingsByName = (bindings: SparqlBinding[]) => {
  const grouped = new Map<string, SparqlBinding[]>();

  for (const binding of bindings) {
    const name = binding.name?.value;

    if (!name) {
      continue;
    }

    if (!grouped.has(name)) {
      grouped.set(name, []);
    }

    grouped.get(name)!.push(binding);
  }

  return grouped;
};

const mapNamesByItemQid = (identityBindings: SparqlBinding[]) => {
  const namesByItemQid = new Map<string, Set<string>>();

  for (const binding of identityBindings) {
    if (!binding.item || !binding.name) {
      continue;
    }

    const itemQid = toEntityId(binding.item.value);

    if (!namesByItemQid.has(itemQid)) {
      namesByItemQid.set(itemQid, new Set());
    }

    namesByItemQid.get(itemQid)!.add(binding.name.value);
  }

  return namesByItemQid;
};

/**
 * Relationship rows are keyed on the item, so there is no ?name to group by.
 * One item can belong to more than one requested name — Katherine and Kathryn
 * resolve to overlapping entities — and each of those names keeps its own
 * document, so every owner gets a copy of the row.
 */
const groupRelationshipsByName = (
  bindings: SparqlBinding[],
  namesByItemQid: Map<string, Set<string>>,
) => {
  const grouped = new Map<string, SparqlBinding[]>();

  for (const binding of bindings) {
    if (!binding.item) {
      continue;
    }

    const owningNames = namesByItemQid.get(toEntityId(binding.item.value));

    if (!owningNames) {
      continue;
    }

    for (const owningName of owningNames) {
      if (!grouped.has(owningName)) {
        grouped.set(owningName, []);
      }

      grouped.get(owningName)!.push(binding);
    }
  }

  return grouped;
};

const saveSourceDocument = async (
  dataSourceId: number,
  givenName: string,
  document: WikidataDocument,
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
      ) VALUES ($1, $2, $3, $4::jsonb, NULL, NOW(), NOW())
      ON CONFLICT (data_source_id, source_key) DO UPDATE
      SET url = EXCLUDED.url,
          raw_payload = EXCLUDED.raw_payload,
          fetched_at = EXCLUDED.fetched_at,
          date_updated = NOW()
    `,
    [
      dataSourceId,
      givenName,
      `https://www.wikidata.org/w/index.php?search=${encodeURIComponent(givenName)}`,
      JSON.stringify(document),
    ],
  );
};

export default async () => {
  const limit = getPositiveIntArg("--limit", 50, 200000);
  const namesPerQuery = getPositiveIntArg(
    "--batch-size",
    DEFAULT_NAMES_PER_QUERY,
    DEFAULT_NAMES_PER_QUERY,
  );
  const spreadMinutes = getPositiveIntArg("--spread-minutes", 0, 1440);
  const dataSourceId = await getDataSourceId("Wikidata");
  const givenNameTypeQids = await getGivenNameTypeQids();
  const names = await getFetchQueue(dataSourceId, limit);

  const batchCount = Math.ceil(names.length / namesPerQuery);
  const pacer = createBatchPacer(batchCount, spreadMinutes);

  console.log(
    `Fetching Wikidata evidence for ${names.length} names: ${pacer.describe()} (two queries each)`,
  );

  let namesWithItems = 0;
  let namesWithoutItems = 0;
  let failedBatchCount = 0;

  try {
    for (let batchIndex = 0; batchIndex < batchCount; batchIndex++) {
      const batch = names.slice(
        batchIndex * namesPerQuery,
        (batchIndex + 1) * namesPerQuery,
      );
      const batchNames = batch.map((name) => name.given_name);

      await pacer.waitForBatch(batchIndex);

      // Splitting already handles a batch that is merely too large. Reaching
      // here means it failed even one name at a time, so the batch is skipped
      // and its names stay in the queue for a later run.
      try {
        // The identity query returns every item carrying the label, so the type
        // filter that used to live in the SPARQL is applied here instead. Rows
        // are filtered before anything is stored: of 603 returned for one batch
        // of fifty, 54 were given names, and keeping the rest would bloat every
        // document with entries the extractor discards anyway.
        const identityBindings = (
          await runQueryWithSplitting(batchNames, buildIdentityQuery, "identity")
        ).filter(
          (binding) =>
            binding.type !== undefined &&
            givenNameTypeQids.has(toEntityId(binding.type.value)),
        );

        const identityByName = groupBindingsByName(identityBindings);
        const namesByItemQid = mapNamesByItemQid(identityBindings);
        const itemQids = [...namesByItemQid.keys()];

        const relationshipsByName =
          itemQids.length > 0
            ? groupRelationshipsByName(
                await runQueryWithSplitting(
                  itemQids,
                  buildRelationshipQuery,
                  "relationship",
                ),
                namesByItemQid,
              )
            : new Map<string, SparqlBinding[]>();

        for (const givenName of batchNames) {
          const document: WikidataDocument = {
            identity: identityByName.get(givenName) ?? [],
            relationships: relationshipsByName.get(givenName) ?? [],
          };

          // Every requested name gets a row, including one Wikidata knows
          // nothing about. Without it the queue never stops offering that name.
          await saveSourceDocument(dataSourceId, givenName, document);

          if (document.identity.length > 0) {
            namesWithItems++;
          } else {
            namesWithoutItems++;
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
          `  batch ${batchIndex + 1}/${batchCount}: ${namesWithItems} matched, ${namesWithoutItems} unmatched, ${failedBatchCount} batches skipped — about ${pacer.estimateRemaining(batchIndex)} remaining`,
        );
      }
    }

    console.log(
      `Wikidata fetch complete. Matched ${namesWithItems}, unmatched ${namesWithoutItems}, ${failedBatchCount} batches skipped.`,
    );
  } finally {
    await closePool();
  }
};
