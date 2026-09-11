import { query } from "../../utils/postGresPool";

export type QueuedGivenName = {
  id: number;
  given_name: string;
};

/**
 * Names that have no stored document for this data source yet, most popular
 * first. Popularity is total SSA occurrences summed across every decade and
 * gender, tie-broken on the name itself so the order is stable between runs.
 *
 * The intent is to work through the whole corpus eventually, so this is a queue
 * position rather than a selection.
 */
export default async (dataSourceId: number, limit: number) => {
  const result = await query(
    `
      SELECT gn.id, gn.given_name
      FROM given_names gn
      LEFT JOIN (
        SELECT given_name_id, SUM(total_occurrences) AS total_occurrences
        FROM given_name_popularity_by_decade
        GROUP BY given_name_id
      ) popularity
        ON popularity.given_name_id = gn.id
      WHERE NOT EXISTS (
        SELECT 1
        FROM source_documents sd
        WHERE sd.data_source_id = $1
          AND sd.source_key = gn.given_name
      )
      ORDER BY popularity.total_occurrences DESC NULLS LAST, gn.given_name ASC
      LIMIT $2
    `,
    [dataSourceId, limit],
  );

  return result.rows as QueuedGivenName[];
};
