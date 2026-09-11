import fetchWithRetry from "../fetchWithRetry";
import getWikimediaUserAgent from "../getWikimediaUserAgent";

export type SparqlBinding = Record<
  string,
  { type: string; value: string; "xml:lang"?: string }
>;

export type SparqlResults = {
  head: { vars: string[] };
  results: { bindings: SparqlBinding[] };
};

const WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql";

/**
 * POST rather than GET: a batch query carries two hundred type identifiers
 * alongside fifty names, which is well past a comfortable query-string length.
 */
export default async (sparqlQuery: string): Promise<SparqlResults> => {
  const response = await fetchWithRetry(WIKIDATA_SPARQL_URL, {
    method: "POST",
    headers: {
      "User-Agent": getWikimediaUserAgent(),
      Accept: "application/sparql-results+json",
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ query: sparqlQuery }).toString(),
  });

  return (await response.json()) as SparqlResults;
};

/** Turns "http://www.wikidata.org/entity/Q1860" into "Q1860". */
export const toEntityId = (entityUri: string) => entityUri.split("/").pop() ?? entityUri;
