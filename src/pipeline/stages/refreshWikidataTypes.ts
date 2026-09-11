import { closePool, query } from "../../utils/postGresPool";
import runSparqlQuery, { toEntityId } from "../../sources/wikidata/sparqlClient";

/**
 * Everything Wikidata considers a kind of given name (Q202444). Around two
 * hundred items, resolved in well under a second.
 *
 * Paying for this walk once and storing the result is what makes the per-batch
 * identity query fast — inlining the same closure into every batch query is
 * what made it time out.
 */
const GIVEN_NAME_TYPE_QUERY = `SELECT ?type ?typeLabel WHERE {
  ?type wdt:P279* wd:Q202444 .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}`;

export default async () => {
  console.log("Refreshing Wikidata given-name types...");

  try {
    const results = await runSparqlQuery(GIVEN_NAME_TYPE_QUERY);
    let storedCount = 0;

    for (const binding of results.results.bindings) {
      if (!binding.type) {
        continue;
      }

      await query(
        `
          INSERT INTO wikidata_given_name_types (item_qid, label, date_updated)
          VALUES ($1, $2, NOW())
          ON CONFLICT (item_qid) DO UPDATE
          SET label = EXCLUDED.label,
              date_updated = NOW()
        `,
        [toEntityId(binding.type.value), binding.typeLabel?.value ?? null],
      );

      storedCount++;
    }

    console.log(`Stored ${storedCount} given-name types.`);
  } finally {
    await closePool();
  }
};
