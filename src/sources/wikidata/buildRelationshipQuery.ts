/**
 * The three relationship properties Wikidata states explicitly:
 *   P460  said to be the same as              — Michael to Miguel, Michel, Mikael
 *   P1813 short name                          — Michael to Mike, Mick, Mickey
 *   P1560 given name version for other gender — Michael to Michaela
 *
 * Keyed on the items the identity pass already resolved rather than on labels.
 * That skips the label match and the type join entirely, and it is now the only
 * thing keeping the query scoped to given names, since the identity query no
 * longer filters types itself.
 *
 * Kept separate from the identity query on purpose. Michael alone carries
 * around fifty P460 statements, and combining them with the language OPTIONAL
 * multiplies the two together into a needlessly large result.
 *
 * The three do not share a datatype. P460 and P1560 point at items, so their
 * name is an rdfs:label; P1813 is monolingual text, so the value *is* the name.
 * Reading only labels silently drops every short name — Michael's Mike, Mick
 * and Mickey included.
 *
 * No ?name is selected. Rows are attributed back to names by the caller, which
 * holds the item-to-name map the identity pass produced.
 */
export default (itemQids: string[]) => {
  const itemValues = itemQids.map((itemQid) => `wd:${itemQid}`).join(" ");

  return `SELECT ?item ?property ?related ?relatedLabel WHERE {
  VALUES ?item { ${itemValues} }
  VALUES ?property { wdt:P460 wdt:P1813 wdt:P1560 }
  ?item ?property ?related .
  OPTIONAL {
    ?related rdfs:label ?entityLabel .
    FILTER(LANG(?entityLabel) = "en")
  }
  BIND(COALESCE(?entityLabel, IF(ISLITERAL(?related), STR(?related), "")) AS ?relatedLabel)
  FILTER(STRLEN(?relatedLabel) > 0)
}`;
};
