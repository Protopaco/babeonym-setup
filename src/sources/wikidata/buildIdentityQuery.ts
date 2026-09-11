import escapeSparqlLiteral from "./escapeSparqlLiteral";

/**
 * Resolves a batch of English labels to items, with their type, writing system
 * and the languages they are used in.
 *
 * Deliberately unfiltered by type. Pinning the 205 given-name types with a
 * VALUES clause reads like an optimisation and is the reverse: it makes the
 * planner enumerate every instance of every listed type — "given name" alone
 * has hundreds of thousands — rather than starting from the fifty labels.
 * Measured on one batch of fifty, the pinned form timed out at 65 seconds where
 * this answers in 0.7, and the two agree exactly once the caller filters ?type.
 *
 * That filter is not optional. Without it the results include every item
 * sharing the label, films and songs among them.
 */
export default (names: string[]) => {
  const nameValues = names
    .map((name) => `"${escapeSparqlLiteral(name)}"@en`)
    .join(" ");

  return `SELECT ?name ?item ?type ?script ?language ?languageLabel WHERE {
  VALUES ?name { ${nameValues} }
  ?item rdfs:label ?name .
  ?item wdt:P31 ?type .
  OPTIONAL { ?item wdt:P282 ?script . }
  OPTIONAL {
    ?item wdt:P407 ?language .
    ?language rdfs:label ?languageLabel .
    FILTER(LANG(?languageLabel) = "en")
  }
}`;
};
